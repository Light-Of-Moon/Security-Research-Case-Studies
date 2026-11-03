import datetime as dt
import json
import os
import re
import time
from urllib.parse import urlsplit

SOURCE = "/logs/waf-access.log"
OUTPUT = "/logs/waf-normalized.jsonl"
PATTERN = re.compile(r'^(?P<src>\S+) .*?"(?P<method>[A-Z]+) (?P<path>\S+) HTTP/[^\"]+" (?P<status>\d{3}) ')
EXPERIMENT = os.getenv("LAB_EXPERIMENT_ID", "manual-unset")
position = 0
while True:
    try:
        with open(SOURCE, "r", encoding="utf-8", errors="replace") as source:
            source.seek(position)
            lines = source.readlines()
            position = source.tell()
        with open(OUTPUT, "a", encoding="utf-8") as target:
            for line in lines:
                match = PATTERN.search(line)
                if not match:
                    continue
                fields = match.groupdict()
                event = {"timestamp": dt.datetime.now(dt.timezone.utc).isoformat(),
                         "component": "waf", "event_type": "access", "experiment_id": EXPERIMENT,
                         "source_ip": fields["src"], "method": fields["method"],
                         "path": urlsplit(fields["path"]).path[:200],
                         "status": int(fields["status"])}
                target.write(json.dumps(event, separators=(",", ":")) + "\n")
    except FileNotFoundError:
        pass
    time.sleep(0.5)
