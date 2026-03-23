"""Primitive script: read-skill-documents

Reads all llm-conductor skill documents and returns structured JSON
with file contents organized by document type.

Input: JSON with optional "base_path" parameter (defaults to skill directory)
Output: JSON array of {name, type, content} objects for fan-out processing
"""

import json
import os
import sys


def process(input_text: str) -> str:
    """Read skill documents and return structured content."""
    try:
        data = json.loads(input_text)
        input_data = data.get("input_data", "{}")
        params = data.get("parameters", {})
    except (json.JSONDecodeError, AttributeError):
        input_data = "{}"
        params = {}

    try:
        parsed_input = json.loads(input_data) if isinstance(input_data, str) else input_data
    except json.JSONDecodeError:
        parsed_input = {}

    base_path = params.get("base_path", parsed_input.get("base_path", ""))

    if not base_path:
        base_path = os.environ.get("LLM_ORC_PROJECT_PATH", os.getcwd())

    documents = []

    # Read domain model
    domain_model_path = os.path.join(base_path, "docs", "domain-model.md")
    if os.path.exists(domain_model_path):
        with open(domain_model_path, "r") as f:
            documents.append({
                "name": "domain-model",
                "type": "domain-model",
                "path": domain_model_path,
                "content": f.read()
            })

    # Read SKILL.md
    skill_path = os.path.join(base_path, "SKILL.md")
    if os.path.exists(skill_path):
        with open(skill_path, "r") as f:
            documents.append({
                "name": "SKILL.md",
                "type": "skill-instructions",
                "path": skill_path,
                "content": f.read()
            })

    # Read all ADRs
    decisions_dir = os.path.join(base_path, "docs", "decisions")
    if os.path.isdir(decisions_dir):
        for filename in sorted(os.listdir(decisions_dir)):
            if filename.endswith(".md"):
                filepath = os.path.join(decisions_dir, filename)
                with open(filepath, "r") as f:
                    documents.append({
                        "name": filename,
                        "type": "adr",
                        "path": filepath,
                        "content": f.read()
                    })

    # Read scenarios
    scenarios_path = os.path.join(base_path, "docs", "scenarios.md")
    if os.path.exists(scenarios_path):
        with open(scenarios_path, "r") as f:
            documents.append({
                "name": "scenarios",
                "type": "scenarios",
                "path": scenarios_path,
                "content": f.read()
            })

    return json.dumps(documents)


if __name__ == "__main__":
    input_text = sys.stdin.read()
    result = process(input_text)
    print(result)
