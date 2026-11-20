from provider import Provider
from scanner import Clock, scan


def main():
    clock = Clock()
    provider = Provider(clock)
    log = []
    provider.grant("acme", "drive.read")
    print("grant stored: drive.read for acme")
    clock.sleep(1)
    files = scan("acme", provider, clock, log)
    print(f"first scan: ok, {len(files)} files")
    for line in log:
        print("  log:", line)
    clock.sleep(86400)
    log.clear()
    files = scan("acme", provider, clock, log)
    print(f"second scan (next day): ok, {len(files)} files")


if __name__ == "__main__":
    main()
