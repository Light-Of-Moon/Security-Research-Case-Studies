#!/usr/bin/env python3
"""Derive an evidence-backed DLP classification matrix from one experiment."""
import json
import sys
from pathlib import Path

run = Path(sys.argv[1])
experiment = (run / "EXPERIMENT_ID").read_text().strip()
receiver_events = []
for line in (run / "shared/receiver.jsonl").read_text().splitlines():
    try:
        receiver_events.append(json.loads(line))
    except json.JSONDecodeError:
        pass

expected = {
    "public": "public_control",
    "recognized_confidential": "recognized_and_enforced",
    "unrecognized_restricted": "classification_failure",
    "base64_recognized": "transform_classification_gap",
}
rows = []
for name, interpretation in expected.items():
    result_path = run / "egress" / f"{name}.json"
    try:
        result = json.loads(result_path.read_text())
    except (FileNotFoundError, json.JSONDecodeError):
        result = {"status": None, "request_bytes": None, "request_sha256": None}
    request_id = f"{experiment}-{name}"
    receipts = [event for event in receiver_events if event.get("request_id") == request_id]
    rows.append({
        "classification_test": name,
        "gateway_status": result.get("status"),
        "request_bytes": result.get("request_bytes"),
        "request_sha256": result.get("request_sha256"),
        "receiver_records": len(receipts),
        "receiver_bytes": sum(event.get("bytes", 0) for event in receipts),
        "interpretation": interpretation,
    })

(run / "egress/dlp-classification-matrix.json").write_text(
    json.dumps(rows, indent=2, sort_keys=True) + "\n"
)
with (run / "egress/dlp-classification-matrix.tsv").open("w", encoding="utf-8") as handle:
    handle.write("classification_test\tgateway_status\trequest_bytes\treceiver_records\treceiver_bytes\tinterpretation\n")
    for row in rows:
        handle.write("\t".join(str(row[key]) for key in (
            "classification_test", "gateway_status", "request_bytes", "receiver_records",
            "receiver_bytes", "interpretation"
        )) + "\n")
