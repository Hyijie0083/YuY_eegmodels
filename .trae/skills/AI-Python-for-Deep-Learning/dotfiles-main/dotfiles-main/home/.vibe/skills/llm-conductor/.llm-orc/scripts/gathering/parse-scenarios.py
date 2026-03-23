"""Primitive script: parse-scenarios

Parses scenarios.md into individual scenarios paired with relevant
SKILL.md instruction sections for per-scenario verification.

Input: JSON with optional "base_path" parameter
Output: JSON array of {scenario_name, feature, given, when, then, skill_section} objects
"""

import json
import os
import re
import sys


def extract_scenarios(content: str) -> list[dict]:
    """Parse Given/When/Then scenarios from markdown."""
    scenarios = []
    current_feature = ""
    current_scenario = None

    for line in content.split("\n"):
        line = line.strip()

        if line.startswith("## Feature:") or line.startswith("## "):
            current_feature = line.lstrip("# ").replace("Feature: ", "")

        elif line.startswith("### Scenario:"):
            if current_scenario:
                scenarios.append(current_scenario)
            current_scenario = {
                "feature": current_feature,
                "scenario_name": line.replace("### Scenario: ", ""),
                "given": "",
                "when": "",
                "then": "",
                "full_text": ""
            }

        elif current_scenario:
            if line.startswith("**Given**"):
                current_scenario["given"] = line.replace("**Given** ", "")
            elif line.startswith("**When**"):
                current_scenario["when"] = line.replace("**When** ", "")
            elif line.startswith("**Then**"):
                current_scenario["then"] = line.replace("**Then** ", "")

            if line:
                current_scenario["full_text"] += line + "\n"

    if current_scenario:
        scenarios.append(current_scenario)

    return scenarios


def extract_skill_sections(content: str) -> dict[str, str]:
    """Extract top-level sections from SKILL.md."""
    sections = {}
    current_section = ""
    current_content = []

    for line in content.split("\n"):
        if line.startswith("## ") and not line.startswith("### "):
            if current_section:
                sections[current_section] = "\n".join(current_content)
            current_section = line.lstrip("# ").strip()
            current_content = []
        else:
            current_content.append(line)

    if current_section:
        sections[current_section] = "\n".join(current_content)

    return sections


FEATURE_TO_SECTION = {
    "Three-Category Delegability": "TASK TRIAGE AND ROUTING",
    "Multi-Stage Ensemble Composition": "ENSEMBLE COMPOSITION",
    "Ensemble-Prepared Claude": "ENSEMBLE COMPOSITION",
    "Updated Workflow Planning": "WORKFLOW PLANNING",
    "Multi-Stage Ensemble Promotion": "ENSEMBLE PROMOTION",
    "Pre-Flight Discovery": "PRE-FLIGHT DISCOVERY",
    "Task Routing": "TASK TRIAGE AND ROUTING",
    "Ensemble Composition": "ENSEMBLE COMPOSITION",
    "Evaluation": "EVALUATION AND REFLECTION",
    "Promotion": "ENSEMBLE PROMOTION",
}


def map_feature_to_section(feature: str, sections: dict[str, str]) -> str:
    """Map a feature name to the most relevant SKILL.md section."""
    for key, section_name in FEATURE_TO_SECTION.items():
        if key.lower() in feature.lower():
            for sname, scontent in sections.items():
                if section_name.lower() in sname.lower():
                    return scontent

    # Fallback: search for feature keywords in section names
    feature_words = set(feature.lower().split())
    best_match = ""
    best_score = 0
    for sname, scontent in sections.items():
        score = len(feature_words & set(sname.lower().split()))
        if score > best_score:
            best_score = score
            best_match = scontent

    return best_match


def process(input_text: str) -> str:
    """Parse scenarios and pair with SKILL.md sections."""
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

    # Read scenarios
    scenarios_path = os.path.join(base_path, "docs", "scenarios.md")
    if not os.path.exists(scenarios_path):
        return json.dumps({"error": f"scenarios.md not found at {scenarios_path}"})

    with open(scenarios_path, "r") as f:
        scenarios_content = f.read()

    # Read SKILL.md
    skill_path = os.path.join(base_path, "SKILL.md")
    if not os.path.exists(skill_path):
        return json.dumps({"error": f"SKILL.md not found at {skill_path}"})

    with open(skill_path, "r") as f:
        skill_content = f.read()

    scenarios = extract_scenarios(scenarios_content)
    sections = extract_skill_sections(skill_content)

    # Pair each scenario with relevant section
    paired = []
    for scenario in scenarios:
        section_content = map_feature_to_section(scenario["feature"], sections)
        paired.append({
            "scenario_name": scenario["scenario_name"],
            "feature": scenario["feature"],
            "given": scenario["given"],
            "when": scenario["when"],
            "then": scenario["then"],
            "skill_section": section_content[:3000] if section_content else "NO MATCHING SECTION FOUND"
        })

    return json.dumps(paired)


if __name__ == "__main__":
    input_text = sys.stdin.read()
    result = process(input_text)
    print(result)
