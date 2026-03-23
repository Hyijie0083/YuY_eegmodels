# Artifact Schemas — Conductor ↔ Designer Protocol

These schemas define the artifacts exchanged between the conductor and designer at lifecycle boundaries (ADR-015).

## Ensemble-Request Artifact

Emitted by the conductor when a delegable task type needs a new or revised ensemble:

```yaml
request_type: "new | revision"
task_type: "extraction"
delegability_category: "agent-delegable | ensemble-delegable"
dag_test_result: {dag: true, script: true, fanout: true, synthesis: true}
sample_inputs:
  - "Extract all API endpoints from server.py"
  - "Extract class names from models.py"
expected_output_format: "JSON array of {method, path, handler}"
repetition_count: 6
evaluation_data:  # for revision requests
  scores: [good, good, poor, poor, poor]
  dominant_failure_mode: "incomplete"
  sample_poor_outputs: ["..."]
context: "Workflow plan for handler refactoring — 6 extraction subtasks identified"
```

## Feedback Artifact

Emitted by the conductor when providing evaluation feedback on an existing ensemble:

```yaml
feedback_type: "calibration_summary | poor_evaluation | promotion_candidate"
ensemble: "extract-semantics"
scores: {good: 2, acceptable: 0, poor: 3}
dominant_failure_mode: "incomplete"
sample_evaluations:
  - input: "..."
    output: "..."
    score: "poor"
    reasoning: "Missing 3 of 8 expected fields"
recommendation: "Revise DAG — extraction stage may need chunking for large files"
```

## Handoff Artifact (Designer → Conductor)

Returned by the designer when a validated ensemble is ready for calibration:

```yaml
ensemble_name: "extract-semantics"
dag_shape: "fan-out swarm → verification script → synthesizer"
profiles_used: ["conductor-micro", "conductor-medium"]
verification_scripts: ["embed-confidence"]
complementary: false
readiness: "validated — ready for calibration"
design_notes: "Based on cross-file analyzer template; added MiniLM verification for confidence scoring"
```
