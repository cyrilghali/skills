FILES = {"acme": ["a.doc", "b.doc", "c.doc"]}
RETRIES = (1, 2, 4)


class Clock:
    def __init__(self):
        self.now = 0

    def sleep(self, seconds):
        self.now += seconds


def scan(customer, provider, clock, log):
    for wait in (0,) + RETRIES:
        clock.sleep(wait)
        token, error = provider.mint_token(customer, "drive.read")
        if token:
            return list(FILES[customer])
        log.append(f"t={clock.now}s mint refused: {error}")
    return []
