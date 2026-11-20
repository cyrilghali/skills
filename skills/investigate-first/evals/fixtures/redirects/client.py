import sys

import edge


def fetch(url, max_hops=6):
    scheme, rest = url.split("://")
    host, _, path = rest.partition("/")
    for hop in range(max_hops):
        status, headers, body = edge.handle({"scheme": scheme, "host": host, "path": "/" + path})
        print(f"hop {hop}: {scheme}://{host}/{path} -> {status} {headers.get('Location', '')}")
        if status < 300:
            return body
        scheme, rest = headers["Location"].split("://")
        host, _, path = rest.partition("/")
    raise SystemExit("too many redirects")


if __name__ == "__main__":
    print(fetch(sys.argv[1]))
