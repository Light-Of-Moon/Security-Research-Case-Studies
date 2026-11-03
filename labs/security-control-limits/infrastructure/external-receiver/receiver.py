"""Isolated receiver proving data movement without any real Internet access."""
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

LOG = Path(os.getenv("LAB_LOG", "/evidence/receiver.jsonl"))
STORE = Path(os.getenv("LAB_STORE", "/evidence/received"))
STORE.mkdir(parents=True, exist_ok=True)


class Handler(BaseHTTPRequestHandler):
    server_version = "SCLExternalReceiver/1.0"

    def do_GET(self):
        body = b'{"status":"ready"}'
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_POST(self):
        length = int(self.headers.get("Content-Length", "0"))
        if length < 0 or length > 2 * 1024 * 1024:
            self.send_error(413)
            return
        data = self.rfile.read(length)
        digest = hashlib.sha256(data).hexdigest()
        experiment = self.headers.get("X-Experiment-ID", "missing")[:100]
        request_id = self.headers.get("X-Request-ID", "missing")[:100]
        safe_name = "".join(c for c in f"{experiment}-{request_id}" if c.isalnum() or c in "-_")
        (STORE / f"{safe_name or digest}.bin").write_bytes(data)
        event = {"timestamp": dt.datetime.now(dt.timezone.utc).isoformat(),
                 "component": "external-receiver", "experiment_id": experiment,
                 "request_id": request_id, "source": self.client_address[0],
                 "bytes": len(data), "sha256": digest}
        with LOG.open("a", encoding="utf-8") as handle:
            handle.write(json.dumps(event, separators=(",", ":")) + "\n")
        body = json.dumps({"received": True, "bytes": len(data), "sha256": digest}).encode()
        self.send_response(201)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *_args):
        return


ThreadingHTTPServer(("0.0.0.0", 8080), Handler).serve_forever()

