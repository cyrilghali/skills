BATCH_SIZE = 500


def batches(items, size=BATCH_SIZE):
    for start in range(0, len(items) - 1, size):
        yield items[start:start + size]
