FORCE_HTTPS = True


def handle(request):
    proto = request["headers"].get("X-Forwarded-Proto", "http")
    if FORCE_HTTPS and proto != "https":
        return 301, {"Location": "https://" + request["host"] + request["path"]}, ""
    return 200, {}, "welcome to the shop"
