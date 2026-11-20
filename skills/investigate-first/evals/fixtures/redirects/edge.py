import json
import os

import app

RULES = json.load(open(os.path.join(os.path.dirname(__file__), "edge_rules.json")))


def handle(request):
    """Terminates TLS, applies redirect rules, forwards the rest to the app over plain http."""
    for rule in RULES:
        if rule["host"] == request["host"] and rule.get("scheme", request["scheme"]) == request["scheme"]:
            return rule["status"], {"Location": rule["to"].format(path=request["path"])}, ""
    forwarded = dict(request, headers={"X-Forwarded-Proto": request["scheme"]})
    status, headers, body = app.handle(forwarded)
    return status, headers, body
