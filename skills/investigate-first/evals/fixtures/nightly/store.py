from collections import OrderedDict

PAGE_SIZE = 50
CACHE_PAGES = 12
HIT_COST = 0.2
MISS_COST = 40


class Store:
    """Rows live on disk in pages; a small cache keeps the recently used pages."""

    def __init__(self, rows, clock):
        self.rows = rows
        self.clock = clock
        self.cache = OrderedDict()

    def get(self, i):
        page = i // PAGE_SIZE
        if page in self.cache:
            self.cache.move_to_end(page)
            self.clock.spend(HIT_COST)
        else:
            self.clock.spend(MISS_COST)
            self.cache[page] = True
            if len(self.cache) > CACHE_PAGES:
                self.cache.popitem(last=False)
        return self.rows[i]
