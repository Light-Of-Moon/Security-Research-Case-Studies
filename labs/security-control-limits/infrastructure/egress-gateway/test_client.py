import http.client
import base64
import hashlib
import json
import sys

kind, experiment, request_id = sys.argv[1:4]
payloads = {
    "public": b"SCL-PUBLIC-EGRESS-CONTROL",
    "recognized_confidential": b"CONFIDENTIAL-LAB SCL-DOC-EGRESS-7VQ29KLM SCL_API_KEY_7VQ29KLM4N8R",
    "unrecognized_restricted": b"amber-7 Project Moonstone valuation 7400000 Northwind Research close 2027-01-15",
    "base64_recognized": base64.b64encode(b"CONFIDENTIAL-LAB SCL-DOC-EGRESS-7VQ29KLM"),
}
body = payloads[kind]
connection = http.client.HTTPConnection("egress-gateway", 8080, timeout=10)
connection.request("POST", "/send", body=body, headers={
    "Content-Type": "application/octet-stream",
    "Content-Length": str(len(body)),
    "X-Lab-Destination": "external-receiver:8080",
    "X-Experiment-ID": experiment,
    "X-Request-ID": request_id,
    "X-Lab-Source": "egress-positive-control",
})
response = connection.getresponse()
result = {"classification_test": kind, "request_bytes": len(body),
          "request_sha256": hashlib.sha256(body).hexdigest(),
          "status": response.status, "body": response.read().decode("utf-8", "replace")}
print(json.dumps(result, separators=(",", ":")))
connection.close()
