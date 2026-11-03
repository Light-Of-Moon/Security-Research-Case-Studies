import json
import os
import time

SOURCE = "/logs/eve.json"
OUTPUT = "/logs/ips-normalized.jsonl"
KEEP = {"alert", "http", "flow", "anomaly", "drop"}
EXPERIMENT = os.getenv("LAB_EXPERIMENT_ID", "manual-unset")


def normalize(src):
    if src.get("event_type") not in KEEP:
        return None
    event = {key: src[key] for key in ("timestamp", "flow_id", "src_ip", "src_port",
             "dest_ip", "dest_port", "proto", "app_proto", "event_type") if key in src}
    event["component"] = "suricata"
    event["experiment_id"] = EXPERIMENT
    if "alert" in src:
        event["alert"] = {key: src["alert"].get(key) for key in
                          ("signature", "signature_id", "category", "severity", "action")}
    return event


position = 0
while True:
    try:
        with open(SOURCE, "r", encoding="utf-8", errors="replace") as source:
            source.seek(position)
            lines = source.readlines()
            position = source.tell()
        with open(OUTPUT, "a", encoding="utf-8") as target:
            for line in lines:
                try:
                    result = normalize(json.loads(line))
                    if result:
                        target.write(json.dumps(result, separators=(",", ":")) + "\n")
                except (ValueError, TypeError):
                    pass
    except FileNotFoundError:
        pass
    time.sleep(0.5)
