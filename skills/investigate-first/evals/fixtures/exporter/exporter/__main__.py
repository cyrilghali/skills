import json
import sys

from exporter.batch import batches
from exporter.csvout import row


def main(src, dst):
    with open(src) as f:
        users = json.load(f)
    with open(dst, "w") as out:
        out.write(row(["id", "name", "email"]) + "\n")
        for chunk in batches(users):
            for u in chunk:
                out.write(row([u["id"], u["name"], u["email"]]) + "\n")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
