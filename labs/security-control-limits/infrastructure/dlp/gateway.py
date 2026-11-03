"""Research HTTP DLP and controlled egress gateway; not an enterprise DLP product."""
import datetime as dt
import hashlib
import http.client
import json
import os
import re
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlsplit

ROLE = os.getenv("GATEWAY_ROLE", "egress")
MODE = os.getenv("DLP_MODE", "block").lower()
LOG = os.getenv("DLP_LOG", "/evidence/dlp.jsonl")
EXPERIMENT = os.getenv("LAB_EXPERIMENT_ID", "manual-unset")
SECURITY_MODE = os.getenv("LAB_SECURITY_MODE", "mode-a")
UPSTREAM = os.getenv("UPSTREAM", "")
ALLOWED = set(filter(None, os.getenv("EGRESS_DESTINATIONS", "external-receiver:8080").split(",")))
DENY_PATH_PREFIXES = tuple(filter(None, os.getenv("DENY_PATH_PREFIXES", "").split(",")))
DENY_QUERY_KEYS = set(filter(None, os.getenv("DENY_QUERY_KEYS", "").split(",")))
DENY_UNAUTHENTICATED_METHODS = set(filter(None, os.getenv("DENY_UNAUTHENTICATED_METHODS", "").upper().split(",")))
UNAUTHENTICATED_METHOD_ALLOW_PREFIXES = tuple(filter(None, os.getenv("UNAUTHENTICATED_METHOD_ALLOW_PREFIXES", "").split(",")))
MAX_BODY = 2 * 1024 * 1024
PATTERNS = {
    "confidential_label": re.compile(rb"CONFIDENTIAL-LAB", re.I),
    "synthetic_api_key": re.compile(rb"SCL_API_KEY_[A-Z0-9]{8,}"),
    "synthetic_internal_token": re.compile(rb"SCL-INTERNAL-TOKEN-[A-Z0-9]+"),
    "synthetic_pan": re.compile(rb"(?:4[0-9]{3}[- ]?){3}[0-9]{4}"),
    "tracked_document": re.compile(rb"SCL-DOC-[A-Z0-9-]+"),
}
HOP = {"connection", "proxy-connection", "keep-alive", "transfer-encoding", "te",
       "trailer", "upgrade", "content-length"}


def matches(data):
    return [name for name, pattern in PATTERNS.items() if pattern.search(data)]


def emit(**fields):
    event = {"timestamp": dt.datetime.now(dt.timezone.utc).isoformat(),
             "experiment_id": EXPERIMENT, "security_mode": SECURITY_MODE,
             "component": "dlp-gateway", "role": ROLE, **fields}
    with open(LOG, "a", encoding="utf-8") as handle:
        handle.write(json.dumps(event, separators=(",", ":")) + "\n")


class Handler(BaseHTTPRequestHandler):
    server_version = "SCLDLP/2.0"

    def reply(self, status, body, content_type="application/json"):
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        if self.command != "HEAD":
            self.wfile.write(body)

    def do_GET(self):
        self.handle_request()

    def do_POST(self):
        self.handle_request()

    def do_PUT(self):
        self.handle_request()

    def do_PATCH(self):
        self.handle_request()

    def do_DELETE(self):
        self.handle_request()

    def handle_request(self):
        request_id = self.headers.get("X-Request-ID", "missing")[:100]
        split = urlsplit(self.path)
        request_path = split.path
        query_keys = sorted(parse_qs(split.query, keep_blank_values=True))
        context = {"method": self.command, "path": request_path[:200],
                   "query_keys": query_keys,
                   "authorization_present": bool(self.headers.get("Authorization")),
                   "cookie_present": bool(self.headers.get("Cookie"))}
        if ROLE == "response" and DENY_PATH_PREFIXES and request_path.startswith(DENY_PATH_PREFIXES):
            self.reply(403, b'{"error":"application capability disabled"}')
            emit(request_id=request_id, verdict="block", reason="path_policy",
                 policy="disabled_application_capability", **context)
            return
        if ROLE == "response" and DENY_QUERY_KEYS.intersection(query_keys):
            self.reply(403, b'{"error":"unsupported routing parameter"}')
            emit(request_id=request_id, verdict="block", reason="query_key_policy",
                 policy="canonical_application_routing", **context)
            return
        if (ROLE == "response" and self.command in DENY_UNAUTHENTICATED_METHODS
                and not context["authorization_present"] and not context["cookie_present"]
                and not request_path.startswith(UNAUTHENTICATED_METHOD_ALLOW_PREFIXES)):
            self.reply(403, b'{"error":"authentication required for state-changing request"}')
            emit(request_id=request_id, verdict="block",
                 reason="unauthenticated_unsafe_method",
                 policy="authenticated_state_change",
                 allow_prefixes=list(UNAUTHENTICATED_METHOD_ALLOW_PREFIXES), **context)
            return
        length = int(self.headers.get("Content-Length", "0"))
        if length < 0 or length > MAX_BODY:
            self.reply(413, b'{"error":"inspection size limit"}')
            emit(request_id=request_id, verdict="block", reason="size_limit", bytes=length, **context)
            return
        body = self.rfile.read(length) if length else b""
        request_matches = matches(body)
        target = UPSTREAM if ROLE == "response" else self.headers.get("X-Lab-Destination", "")
        if ROLE == "egress" and target not in ALLOWED:
            self.reply(403, b'{"error":"destination denied"}')
            emit(request_id=request_id, verdict="block", reason="destination", destination=target,
                 bytes=len(body), sha256=hashlib.sha256(body).hexdigest(), **context)
            return
        if request_matches and MODE == "block":
            self.reply(403, b'{"error":"DLP policy blocked request"}')
            emit(request_id=request_id, verdict="block", reason="request_content",
                 destination=target, match_types=request_matches, bytes=len(body),
                 sha256=hashlib.sha256(body).hexdigest(), **context)
            return
        host, port = target.rsplit(":", 1)
        path = self.path if ROLE == "response" else "/receive"
        headers = {k: v for k, v in self.headers.items() if k.lower() not in HOP}
        headers["Host"] = target
        headers["Connection"] = "close"
        headers["X-Experiment-ID"] = EXPERIMENT
        try:
            conn = http.client.HTTPConnection(host, int(port), timeout=15)
            conn.request(self.command, path, body=body, headers=headers)
            response = conn.getresponse()
            response_body = response.read(MAX_BODY + 1)
            response_headers = response.getheaders()
            conn.close()
            if len(response_body) > MAX_BODY:
                self.reply(502, b'{"error":"upstream response too large"}')
                emit(request_id=request_id, verdict="block", reason="response_size", destination=target, **context)
                return
            response_matches = matches(response_body)
            if response_matches and MODE == "block":
                self.reply(403, b'{"error":"DLP policy blocked response"}')
                emit(request_id=request_id, verdict="block", reason="response_content",
                     destination=target, match_types=response_matches, bytes=len(response_body),
                     sha256=hashlib.sha256(response_body).hexdigest(), **context)
                return
            self.send_response(response.status)
            for key, value in response_headers:
                if key.lower() not in HOP and key.lower() != "server":
                    self.send_header(key, value)
            self.send_header("Content-Length", str(len(response_body)))
            self.end_headers()
            if self.command != "HEAD":
                self.wfile.write(response_body)
            emit(request_id=request_id, verdict="allow", reason="no_blocking_match",
                 destination=target, request_matches=request_matches,
                 response_matches=response_matches, request_bytes=len(body),
                 response_bytes=len(response_body), status=response.status, **context)
        except Exception as exc:
            self.reply(502, b'{"error":"gateway upstream failure"}')
            emit(request_id=request_id, verdict="error", reason=type(exc).__name__, destination=target, **context)

    def log_message(self, *_args):
        return


if ROLE not in {"egress", "response"} or MODE not in {"monitor", "block"}:
    raise SystemExit("invalid GATEWAY_ROLE or DLP_MODE")
ThreadingHTTPServer(("0.0.0.0", 8080), Handler).serve_forever()
