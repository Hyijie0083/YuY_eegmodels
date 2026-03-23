# Prompt: Implement Ensemble Promotion, Library Management, and Bug Fixes

## Bug Fix: Ollama Detection Silently Fails

**File:** `src/llm_orc/mcp/handlers/provider_handler.py`, lines 39-64

The `_get_ollama_status` method has a silent `except Exception: pass` that swallows all errors. When called from the MCP server (running under FastMCP's `anyio.run()` via stdio transport), the Ollama check fails with an unknown exception, but the error is discarded and the user sees only `"reason": "Ollama not running"` — even when Ollama IS running and accessible via `curl http://localhost:11434/api/tags`.

**Confirmed:** httpx works fine in standalone Python, under `uv run`, and even under `anyio.run()`. The failure is specific to the MCP server subprocess context (likely a network/sandbox restriction from the Claude Code host process).

**Fix required:**

1. **Log the actual exception** — at minimum, include the exception type and message in the response:

```python
async def _get_ollama_status(self) -> dict[str, Any]:
    if self._test_ollama_status is not None:
        return self._test_ollama_status

    import httpx

    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get("http://localhost:11434/api/tags")
            if response.status_code == 200:
                data = response.json()
                models = [m.get("name", "") for m in data.get("models", [])]
                return {
                    "available": True,
                    "models": sorted(models),
                    "model_count": len(models),
                }
            return {
                "available": False,
                "models": [],
                "reason": f"Ollama returned status {response.status_code}",
            }
    except Exception as e:
        return {
            "available": False,
            "models": [],
            "reason": f"Ollama not reachable: {type(e).__name__}: {e}",
        }
```

2. **Support configurable Ollama host** via `OLLAMA_HOST` environment variable (Ollama's own convention):

```python
import os
ollama_host = os.environ.get("OLLAMA_HOST", "http://localhost:11434")
response = await client.get(f"{ollama_host}/api/tags")
```

3. **Add fallback to `127.0.0.1`** if `localhost` fails (DNS resolution can differ in subprocess contexts):

```python
for host in [ollama_host, "http://127.0.0.1:11434"]:
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get(f"{host}/api/tags")
            if response.status_code == 200:
                # ... success
    except Exception:
        continue
```

4. **Propagate `OLLAMA_HOST` in `.mcp.json`** — the MCP server config should forward the env var:

```json
{
  "mcpServers": {
    "llm-orc": {
      "command": "uv",
      "args": ["run", "llm-orc", "mcp", "serve"],
      "env": {
        "OLLAMA_HOST": "http://localhost:11434"
      }
    }
  }
}
```

This also affects `check_ensemble_runnable` since it calls `get_provider_status` internally (line 95).

---

## Context

llm-orc's MCP server currently has 23 tools covering ensemble CRUD, invocation, profiles, scripts, validation, and library browsing. However, there is a gap: **no tools support moving ensembles between tiers** (local → global → library). The only cross-tier operation is `library_copy`, which copies FROM the library TO local — the reverse direction of promotion.

An external Claude Code skill (llm-conductor) acts as an intelligent broker that routes tasks to local ensembles, evaluates their output quality, and promotes high-quality ensembles through a three-tier lifecycle:

- **Local tier** (`{project}/.llm-orc/`) — where ensembles are born, project-specific
- **Global tier** (`~/.config/llm-orc/`) — user-wide, reusable across projects
- **Library tier** (`llm-orchestra-library/`) — community-contributed, shared

Currently, the conductor must work around the missing tools by using raw file operations (Read/Write/Bash) to copy files between tiers. This is fragile, bypasses llm-orc's configuration management, and can't leverage llm-orc's built-in validation and runnability checking.

## What to Implement

Add a new `PromotionHandler` in `src/llm_orc/mcp/handlers/promotion_handler.py` following the existing handler patterns, and register 4 new MCP tools in `server.py`.

### Tool 1: `promote_ensemble`

Copy an ensemble from one tier to another, including its profile dependencies.

**Parameters:**
- `ensemble_name` (str, required) — name of the ensemble to promote
- `destination` (str, required) — target tier: `"global"` or `"library"`
- `include_profiles` (bool, default `true`) — copy referenced profiles that are missing at the destination
- `dry_run` (bool, default `true`) — preview what would be copied without actually copying
- `overwrite` (bool, default `false`) — overwrite if ensemble already exists at destination

**Behavior:**
1. Find the ensemble in the current tier (search local first, then global)
2. Resolve all profile dependencies — parse the ensemble YAML, extract each agent's `model_profile`, find the profile definitions
3. Check which profiles already exist at the destination tier
4. If `dry_run`: return a report of what would be copied (ensemble path, profile paths, what's missing at destination)
5. If not `dry_run`:
   - Copy the ensemble YAML to the destination's `ensembles/` directory
   - Copy any missing profiles to the destination's `profiles/` directory
   - Run `check_ensemble_runnable` at the destination to verify the promoted ensemble works
6. Return a structured result with: files copied, profiles copied, runnability status

**Key considerations:**
- When promoting to `"library"`, write to the library path resolved by `ConfigurationManager` (via `LLM_ORC_LIBRARY_PATH` env var or `llm-orchestra-library/` relative to cwd)
- When promoting to `"global"`, write to `config_manager.global_config_dir`
- Profile files may be multi-profile YAML files (containing a `model_profiles:` dict with multiple profiles). When copying, only copy the specific profiles needed — don't copy the entire file if it contains unrelated profiles. Alternatively, copy the whole file if all its profiles are relevant, and document this choice.
- If the ensemble references a profile that doesn't exist anywhere (broken reference), report it as an error rather than silently skipping

### Tool 2: `list_dependencies`

Show all external dependencies an ensemble requires: profiles, models, and providers.

**Parameters:**
- `ensemble_name` (str, required) — name of the ensemble to inspect

**Return:**
```json
{
  "ensemble": "extract-endpoints",
  "source_tier": "local",
  "agents": [
    {
      "name": "extractor",
      "model_profile": "micro-extractor",
      "profile_found": true,
      "profile_tier": "local",
      "provider": "ollama",
      "model": "qwen3:0.6b",
      "model_available": true
    }
  ],
  "profiles_needed": ["micro-extractor", "medium-synthesizer"],
  "models_needed": ["qwen3:0.6b", "gemma3:4b"],
  "providers_needed": ["ollama"]
}
```

This gives the conductor (or any user) a complete picture of what an ensemble requires before attempting promotion.

### Tool 3: `check_promotion_readiness`

Assess whether an ensemble can be promoted to a target tier, and what's missing.

**Parameters:**
- `ensemble_name` (str, required) — name of the ensemble to check
- `destination` (str, required) — target tier: `"global"` or `"library"`

**Return:**
```json
{
  "ensemble": "extract-endpoints",
  "destination": "global",
  "ready": false,
  "issues": [
    {
      "type": "missing_profile",
      "detail": "Profile 'micro-extractor' not found at global tier",
      "resolution": "Will be copied during promotion if include_profiles=true"
    },
    {
      "type": "model_unavailable",
      "detail": "Model 'qwen3:0.6b' requires Ollama but Ollama is not running",
      "resolution": "Ensure Ollama is running with: ollama pull qwen3:0.6b"
    }
  ],
  "already_exists": false,
  "profiles_to_copy": ["micro-extractor"],
  "profiles_already_present": ["medium-synthesizer"]
}
```

This is distinct from `check_ensemble_runnable` because it checks readiness at the *destination* tier, not the current tier. It also identifies what promotion would need to copy.

### Tool 4: `demote_ensemble`

Remove an ensemble from a higher tier (does not delete the lower-tier copy if one exists).

**Parameters:**
- `ensemble_name` (str, required) — name of the ensemble to demote
- `tier` (str, required) — tier to remove from: `"global"` or `"library"`
- `remove_orphaned_profiles` (bool, default `false`) — also remove profiles at that tier that are no longer referenced by any remaining ensemble
- `confirm` (bool, default `false`) — must be `true` to actually delete

**Behavior:**
1. Find the ensemble at the specified tier
2. If `confirm` is false, return a preview of what would be removed
3. If `confirm` is true, delete the ensemble YAML from the tier
4. If `remove_orphaned_profiles`, scan remaining ensembles at that tier and remove profiles that are no longer referenced by any ensemble

This supports rollback when a promoted ensemble turns out to have issues.

## Implementation Guide

### File Structure

```
src/llm_orc/mcp/handlers/
├── promotion_handler.py    # NEW — PromotionHandler class
├── ensemble_crud.py        # Existing — reference for patterns
├── library_handler.py      # Existing — reference for cross-tier file ops
├── provider_handler.py     # Existing — reference for check_ensemble_runnable
└── ...
```

### Handler Pattern to Follow

Based on the existing handlers (e.g., `LibraryHandler`, `EnsembleCrudHandler`):

```python
class PromotionHandler:
    def __init__(self, config_manager, provider_handler=None):
        self._config_manager = config_manager
        self._provider_handler = provider_handler  # for runnability checks

    async def promote_ensemble(self, arguments: dict[str, Any]) -> dict[str, Any]:
        ensemble_name = arguments.get("ensemble_name")
        if not ensemble_name:
            raise ValueError("ensemble_name is required")
        destination = arguments.get("destination")
        if destination not in ("global", "library"):
            raise ValueError("destination must be 'global' or 'library'")
        # ... implementation
```

### Registration in server.py

Follow the existing pattern in `_setup_tools()`:

```python
# In _setup_tools(), add a new section after library tools:

# --- Promotion tools ---
@self._mcp.tool()
async def promote_ensemble(
    ensemble_name: str,
    destination: str,
    include_profiles: bool = True,
    dry_run: bool = True,
    overwrite: bool = False,
) -> str:
    """Promote an ensemble from local to global or library tier, including profile dependencies."""
    result = await self._promotion_handler.promote_ensemble({...})
    return json.dumps(result, indent=2)
```

And add to `_get_tool_handler()` dispatch table:

```python
"promote_ensemble": self._promotion_handler.promote_ensemble,
"list_dependencies": self._promotion_handler.list_dependencies,
"check_promotion_readiness": self._promotion_handler.check_promotion_readiness,
"demote_ensemble": self._promotion_handler.demote_ensemble,
```

### Key Implementation Details

**Resolving destination directories:**
```python
if destination == "global":
    dest_ensembles = self._config_manager.global_config_dir / "ensembles"
    dest_profiles = self._config_manager.global_config_dir / "profiles"
elif destination == "library":
    # Use the library path from ConfigurationManager
    # Check LLM_ORC_LIBRARY_PATH env var first, then cwd/llm-orchestra-library/
    dest_ensembles = library_path / "ensembles"
    dest_profiles = library_path / "profiles"
```

**Parsing profile references from ensemble YAML:**
```python
# Load ensemble YAML
# For each agent, extract model_profile field
# Use get_agent_attr() utility from mcp/utils.py for dict/object compatibility
from llm_orc.mcp.utils import get_agent_attr

profiles_needed = set()
for agent in ensemble_config.agents:
    profile_name = get_agent_attr(agent, "model_profile")
    if profile_name:
        profiles_needed.add(profile_name)
```

**Checking profile existence at destination:**
```python
# Profiles may be in multi-profile YAML files
# Use config_manager.load_profiles() pattern but scoped to destination tier
# Check if the profile name exists in any YAML file at the destination
```

**Dry run pattern** — follow the existing `update_ensemble` tool which already has `dry_run` support:
```python
if dry_run:
    return {
        "status": "dry_run",
        "would_copy": {
            "ensemble": str(source_path),
            "profiles": [str(p) for p in profiles_to_copy],
        },
        "destination": str(dest_dir),
    }
```

### Tests

Add tests in `tests/mcp/handlers/test_promotion_handler.py` following the existing test patterns (e.g., `test_library_handler.py`, `test_ensemble_crud.py`). Key test cases:

1. Promote ensemble from local to global (happy path)
2. Promote with missing profiles — profiles get copied
3. Promote with profiles already at destination — no duplicate copy
4. Dry run returns preview without copying
5. Promote to library tier
6. Promote ensemble that doesn't exist — error
7. Promote ensemble with broken profile reference — error
8. Demote ensemble from global
9. Demote with orphaned profile cleanup
10. Check promotion readiness with all deps met
11. Check promotion readiness with missing model/profile
12. List dependencies for multi-agent ensemble

## Why This Matters

Without these tools, any client (like llm-conductor) that wants to promote ensembles must:
1. Manually parse ensemble YAML to find profile references
2. Manually resolve profile file paths across tiers
3. Use raw file copy operations that bypass llm-orc's config management
4. Separately call `check_ensemble_runnable` and hope it works at the destination
5. Handle all edge cases (multi-profile files, overwrite conflicts, orphaned profiles) themselves

With these tools, promotion becomes a single atomic MCP call with built-in dependency resolution, validation, and dry-run preview.
