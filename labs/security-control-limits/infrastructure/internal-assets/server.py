"""Synthetic internal service. Every secret is non-production test data."""
import datetime as dt
import hashlib
import json
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

TOKEN = os.getenv("LAB_ASSET_TOKEN", "SCL-INTERNAL-TOKEN-4M7Q9X2K")
LOG = os.getenv("LAB_LOG", "/evidence/internal-assets.jsonl")
EXPERIMENT = os.getenv("LAB_EXPERIMENT_ID", "manual-unset")
RECOGNIZED_DOCUMENT = {
    "classification": "CONFIDENTIAL-LAB",
    "document_id": "SCL-DOC-7VQ2-9KLM",
    "owner": "research@example.invalid",
    "synthetic_person": "Ada Example, 203.0.113.77, 4111-1111-1111-1111",
    "synthetic_api_key": "SCL_API_KEY_7VQ29KLM4N8R",
}
UNRECOGNIZED_DOCUMENT = {
    "handling": "amber-7",
    "record_id": "Q4-ORCHID-17",
    "project": "Project Moonstone acquisition model",
    "synthetic_terms": "valuation 7400000; counterparty Northwind Research; close 2027-01-15",
}


def emit(**fields):
    event = {"timestamp": dt.datetime.now(dt.timezone.utc).isoformat(),
             "experiment_id": EXPERIMENT, "component": "internal-assets", **fields}
    with open(LOG, "a", encoding="utf-8") as handle:
        handle.write(json.dumps(event, separators=(",", ":")) + "\n")


class Handler(BaseHTTPRequestHandler):
    server_version = "SCLInternalAssets/1.0"

    def respond(self, status, payload):
        body = json.dumps(payload, separators=(",", ":")).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)
        emit(method=self.command, path=self.path, status=status,
             source=self.client_address[0], bytes=len(body),
             body_sha256=hashlib.sha256(body).hexdigest())

    def do_GET(self):
        if self.path == "/health":
            return self.respond(200, {"status": "ok", "service": "internal-assets"})
        if self.path == "/public":
            return self.respond(200, {"classification": "PUBLIC", "value": "SCL-PUBLIC-OK"})
        if self.path in {"/documents", "/documents/recognized", "/documents/unrecognized"}:
            if self.headers.get("Authorization") != f"Bearer {TOKEN}":
                return self.respond(401, {"error": "valid internal token required"})
            if self.path == "/documents/unrecognized":
                return self.respond(200, UNRECOGNIZED_DOCUMENT)
            return self.respond(200, RECOGNIZED_DOCUMENT)
        return self.respond(404, {"error": "not found"})

    def log_message(self, *_args):
        return


ThreadingHTTPServer(("0.0.0.0", 8080), Handler).serve_forever()
