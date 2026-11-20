from store import Store

DEADLINE = 500
COMPARE_COST = 0.0002


class Clock:
    def __init__(self):
        self.used = 0

    def spend(self, units):
        self.used += units


def build_report(store, clock):
    accounts = [store.get(i) for i in range(600)]
    links = [(a["id"], a["id"] + 1) for a in accounts]
    out = []
    for a in accounts:
        related = []
        for src, dst in links:
            clock.spend(COMPARE_COST)
            if src == a["id"]:
                related.append(dst)
        out.append((a["id"], len(related)))
    return out


def archive_old_entries(store):
    for i in range(600, 1200):
        store.get(i)


def main():
    clock = Clock()
    store = Store([{"id": i} for i in range(1200)], clock)
    build_report(store, clock)  # the service was already up before the week starts
    for day in ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]:
        if day in ("Wed", "Sat"):
            archive_old_entries(store)
        clock.used = 0
        build_report(store, clock)
        status = "ok" if clock.used <= DEADLINE else "FAILED deadline exceeded"
        print(f"{day} {status} ({clock.used:.0f} units, limit {DEADLINE})")


if __name__ == "__main__":
    main()
