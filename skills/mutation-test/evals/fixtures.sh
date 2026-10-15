#!/usr/bin/env bash
# Builds the five eval repositories under <dir>/c1 .. <dir>/c5. Usage: fixtures.sh <dir>
# Needs git, python3, node and go.
set -euo pipefail
out="${1:?usage: fixtures.sh <dir>}"
mkdir -p "$out"
out="$(cd "$out" && pwd)"
g() { git -c user.name=dev -c user.email=dev@example.com -c commit.gpgsign=false "$@"; }
fresh() { rm -rf "$out/$1"; mkdir "$out/$1"; cd "$out/$1"; git init -q -b main; printf "__pycache__/\nnode_modules/\n" > .gitignore; }

# c1: Python, a new fee rule with happy-path tests
fresh c1
cat > shipping.py <<'EOF'
def weight_class(kg):
    if kg < 1:
        return "light"
    if kg < 10:
        return "medium"
    return "heavy"
EOF
cat > test_shipping.py <<'EOF'
import unittest
from shipping import weight_class


class WeightClassTest(unittest.TestCase):
    def test_classes(self):
        self.assertEqual(weight_class(0.5), "light")
        self.assertEqual(weight_class(1), "medium")
        self.assertEqual(weight_class(10), "heavy")


if __name__ == "__main__":
    unittest.main()
EOF
g add -A && g commit -qm "Add weight classes"
g checkout -qb feature/shipping-fee
cat >> shipping.py <<'EOF'


FREE_SHIPPING_THRESHOLD = 50
BASE_FEE = 4.90
EXPRESS_FEE = 10
HEAVY_SURCHARGE = 5


def shipping_fee(subtotal, kg, express=False):
    """Fee charged at checkout. Free above the threshold unless express."""
    fee = BASE_FEE
    if subtotal >= FREE_SHIPPING_THRESHOLD and not express:
        fee = 0
    if express:
        fee += EXPRESS_FEE
    if kg > 20:
        fee += HEAVY_SURCHARGE
    return round(fee, 2)
EOF
cat > test_shipping_fee.py <<'EOF'
import unittest
from shipping import shipping_fee


class ShippingFeeTest(unittest.TestCase):
    def test_small_order_pays_base_fee(self):
        self.assertEqual(shipping_fee(20, 2), 4.90)

    def test_large_order_ships_free(self):
        self.assertEqual(shipping_fee(80, 2), 0)

    def test_express_adds_fee(self):
        self.assertEqual(shipping_fee(20, 2, express=True), 14.90)


if __name__ == "__main__":
    unittest.main()
EOF
g add -A && g commit -qm "Add shipping fee at checkout"

# c2: Python, a branch that only rewords a log line and docs
fresh c2
cat > invoices.py <<'EOF'
import logging

log = logging.getLogger(__name__)


def invoice_total(lines, vat_rate):
    """Sum line amounts and add VAT."""
    net = sum(line["qty"] * line["unit_price"] for line in lines)
    total = round(net * (1 + vat_rate), 2)
    log.info("invoice total computed: %s", total)
    return total
EOF
cat > test_invoices.py <<'EOF'
import unittest
from invoices import invoice_total


class InvoiceTotalTest(unittest.TestCase):
    def test_adds_vat(self):
        lines = [{"qty": 2, "unit_price": 10}, {"qty": 1, "unit_price": 5}]
        self.assertEqual(invoice_total(lines, 0.2), 30.0)

    def test_empty(self):
        self.assertEqual(invoice_total([], 0.2), 0)


if __name__ == "__main__":
    unittest.main()
EOF
printf '# invoices\n\nComputes invoice totals.\n' > README.md
g add -A && g commit -qm "Add invoice totals"
g checkout -qb chore/log-wording
python3 - <<'EOF'
p = "invoices.py"
s = open(p).read()
s = s.replace('"invoice total computed: %s"', '"computed invoice total=%s (net + VAT)"')
s = s.replace("Sum line amounts and add VAT.", "Sum line amounts (qty x unit price) and add VAT on top.")
open(p, "w").write(s)
EOF
printf '# invoices\n\nComputes invoice totals, VAT included.\n\nRun the tests with `python3 -m unittest`.\n' > README.md
g add -A && g commit -qm "Clarify invoice log line and docs"

# c3: JavaScript, the branch's own suite is already red
fresh c3
cat > package.json <<'EOF'
{ "name": "cart", "version": "1.0.0", "type": "module", "scripts": { "test": "node --test" } }
EOF
mkdir -p src test
cat > src/cart.js <<'EOF'
export function itemCount(cart) {
  return cart.items.reduce((n, item) => n + item.qty, 0);
}
EOF
cat > test/cart.test.js <<'EOF'
import { test } from "node:test";
import assert from "node:assert/strict";
import { itemCount } from "../src/cart.js";

test("counts quantities", () => {
  assert.equal(itemCount({ items: [{ qty: 2 }, { qty: 3 }] }), 5);
});
EOF
g add -A && g commit -qm "Add cart item count"
g checkout -qb feature/coupons
cat > src/coupons.js <<'EOF'
export function applyCoupon(total, coupon, now = new Date()) {
  if (!coupon || new Date(coupon.expiresAt) < now) return total;
  if (coupon.kind === "percent") {
    return Math.round(total * (100 - coupon.value)) / 100;
  }
  if (coupon.kind === "fixed") {
    return Math.max(0, total - coupon.value);
  }
  return total;
}
EOF
cat > test/coupons.test.js <<'EOF'
import { test } from "node:test";
import assert from "node:assert/strict";
import { applyCoupon } from "../src/coupons.js";

const later = "2999-01-01";

test("percent coupon", () => {
  assert.equal(applyCoupon(200, { kind: "percent", value: 10, expiresAt: later }), 180);
});

test("fixed coupon never goes below zero", () => {
  assert.equal(applyCoupon(5, { kind: "fixed", value: 10, expiresAt: later }), 0);
});

test("expired coupon is ignored", () => {
  assert.equal(applyCoupon(100, { kind: "fixed", value: 10, expiresAt: "2000-01-01" }), 100);
});

test("percent coupon keeps cents", () => {
  assert.equal(applyCoupon(19.99, { kind: "percent", value: 15, expiresAt: later }), 16.99);
});

test("unknown coupon kind is rejected", () => {
  assert.throws(() => applyCoupon(100, { kind: "bogo", value: 1, expiresAt: later }), /unknown coupon kind/);
});
EOF
g add -A && g commit -qm "Add coupons"

# c4: Python and SQLite, a query string, with uncommitted work left in the tree
fresh c4
cat > orders.py <<'EOF'
import sqlite3

SCHEMA = """
CREATE TABLE orders (
    id INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    status TEXT NOT NULL,
    created_at TEXT NOT NULL,
    amount_cents INTEGER NOT NULL
);
"""


def connect():
    conn = sqlite3.connect(":memory:")
    conn.executescript(SCHEMA)
    return conn


def add_order(conn, customer_id, status, created_at, amount_cents):
    conn.execute(
        "INSERT INTO orders (customer_id, status, created_at, amount_cents) VALUES (?, ?, ?, ?)",
        (customer_id, status, created_at, amount_cents),
    )
EOF
cat > test_orders.py <<'EOF'
import unittest
import orders


class AddOrderTest(unittest.TestCase):
    def test_insert(self):
        conn = orders.connect()
        orders.add_order(conn, 1, "paid", "2026-01-01", 1000)
        self.assertEqual(conn.execute("SELECT COUNT(*) FROM orders").fetchone()[0], 1)


if __name__ == "__main__":
    unittest.main()
EOF
g add -A && g commit -qm "Add orders table"
g checkout -qb feature/refund-eligibility
cat >> orders.py <<'EOF'


RECENT_ORDERS_SQL = """
SELECT id, amount_cents
FROM orders
WHERE customer_id = ?
  AND status != 'cancelled'
  AND created_at >= date(?, '-30 days')
ORDER BY created_at DESC
LIMIT ?
"""


def recent_refundable_orders(conn, customer_id, today, limit=5):
    """Orders a customer can still ask a refund for: not cancelled, at most 30 days old."""
    rows = conn.execute(RECENT_ORDERS_SQL, (customer_id, today, limit)).fetchall()
    return [{"id": r[0], "amount_cents": r[1]} for r in rows]


def refundable_total(conn, customer_id, today):
    return sum(o["amount_cents"] for o in recent_refundable_orders(conn, customer_id, today))
EOF
cat > test_refunds.py <<'EOF'
import unittest
import orders


class RefundTest(unittest.TestCase):
    def setUp(self):
        self.conn = orders.connect()
        orders.add_order(self.conn, 7, "paid", "2026-03-10", 2500)
        orders.add_order(self.conn, 7, "paid", "2026-03-12", 1500)

    def test_lists_recent_orders(self):
        rows = orders.recent_refundable_orders(self.conn, 7, "2026-03-15")
        self.assertEqual(len(rows), 2)

    def test_total(self):
        self.assertEqual(orders.refundable_total(self.conn, 7, "2026-03-15"), 4000)


if __name__ == "__main__":
    unittest.main()
EOF
g add -A && g commit -qm "Add refund eligibility query"
cat >> orders.py <<'EOF'


def order_count(conn, customer_id):
    # WIP: used by the upcoming loyalty badge
    return conn.execute("SELECT COUNT(*) FROM orders WHERE customer_id = ?", (customer_id,)).fetchone()[0]
EOF
printf 'TODO loyalty badge: threshold 10 orders\n' > NOTES.txt

# c5: Go, pagination helpers whose page count floors
fresh c5
cat > go.mod <<'EOF'
module example.com/listing

go 1.21
EOF
cat > sort.go <<'EOF'
package listing

import "sort"

// SortByName sorts names alphabetically in place.
func SortByName(names []string) { sort.Strings(names) }
EOF
cat > sort_test.go <<'EOF'
package listing

import "testing"

func TestSortByName(t *testing.T) {
	n := []string{"b", "a"}
	SortByName(n)
	if n[0] != "a" {
		t.Fatal("not sorted")
	}
}
EOF
g add -A && g commit -qm "Add sorting"
g checkout -qb feature/pagination
cat > page.go <<'EOF'
package listing

// PageCount returns how many pages a list of total items needs.
func PageCount(total, perPage int) int {
	if perPage <= 0 {
		return 0
	}
	return total / perPage
}

// PageBounds returns the half-open slice range [start, end) for a 1-based page.
func PageBounds(page, perPage, total int) (int, int) {
	if page < 1 {
		page = 1
	}
	start := (page - 1) * perPage
	if start > total {
		start = total
	}
	end := start + perPage
	if end > total {
		end = total
	}
	return start, end
}
EOF
cat > page_test.go <<'EOF'
package listing

import "testing"

func TestPageCount(t *testing.T) {
	if got := PageCount(20, 10); got != 2 {
		t.Fatalf("PageCount(20,10) = %d", got)
	}
	if got := PageCount(0, 10); got != 0 {
		t.Fatalf("PageCount(0,10) = %d", got)
	}
}

func TestPageBoundsFirstPage(t *testing.T) {
	s, e := PageBounds(1, 10, 25)
	if s != 0 || e != 10 {
		t.Fatalf("got %d,%d", s, e)
	}
}
EOF
g add -A && g commit -qm "Add pagination helpers"

echo "built c1..c5 in $out"
