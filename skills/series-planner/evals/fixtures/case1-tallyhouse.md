# Tallyhouse: internal product notes

Compiled from the product wiki and the engineering handbook. Last reviewed this quarter.

## What Tallyhouse is

Tallyhouse is a web app that matches a company's card spending to its receipts and its accounting ledger. Finance teams at companies of 50 to 2,000 people buy it. The person who signs the contract is usually the finance controller, but the people who use it every day are accountants.

Every expense goes through three states: **captured** (the card transaction arrived), **matched** (a receipt is linked to it), and **booked** (it is written to the customer's accounting ledger). An expense never skips a state.

Employees send receipts by taking a photo in the mobile app or by forwarding an email to their personal Tallyhouse address. About 70% of receipts come in by email.

Tallyhouse links a receipt to a transaction automatically when the amount matches exactly and the dates are no more than 3 days apart. Anything else lands in the accountant's review queue.

Customers pay per active card per month. A card counts as active in a month if it had at least one transaction that month.

Tallyhouse connects to two accounting ledgers today: Ledgermate and Booksy. A customer can connect only one ledger at a time.

## How it is built

The backend is one Python service with a Postgres database. The web app and the mobile app both talk to the same JSON API.

Card transactions arrive by webhook from the card issuer. The webhook handler stores the raw payload first and parses it in a background job, so a parsing bug never loses a transaction.

The matching job runs every 10 minutes. It looks only at expenses in the captured state from the last 60 days.

Each expense row stores the issuer's transaction ID. A unique index on that column is what stops a webhook that is delivered twice from creating two expenses.

Receipts are stored in object storage. The database keeps only the file key and a SHA-256 hash of the file. The hash lets the app warn an employee who uploads the same receipt twice.

Text is read from receipt images by an external OCR service. Calls to it are retried 3 times with backoff, then the receipt is marked "needs manual entry".

Booking to a ledger runs as a separate job per customer, so one customer's ledger outage never blocks another customer.

Ledger API tokens are encrypted at rest with a key held in the cloud key manager. Engineers cannot read them from a database console.

Every change to an expense writes a row to the audit log table. The audit log is append-only: the application's database user has no UPDATE or DELETE right on it.

A booked expense cannot be edited in Tallyhouse. To fix it, an accountant reverses it, which books a negative copy, and then books a corrected one.

Amounts are stored as integers in the smallest currency unit (cents for euros) together with an ISO currency code. Floats are never used for money.

When the card currency differs from the company currency, the exchange rate used is the issuer's rate on the transaction date, not the rate on the booking date.

## How the team works

Every pull request needs one approval and green CI. CI runs the test suite against a real Postgres, not a mock.

Deploys go out automatically from the main branch, several times a day. A database migration that drops a column ships in a separate deploy after the code that stops reading it.

Feature flags are kept per customer, so a feature can be turned on for one customer first.

The on-call engineer is paged when the webhook error rate goes over 2% for 5 minutes.

Support tickets that need an engineer are tagged "eng-escalation" and answered within one working day.

## Notes on stale or wrong statements

- Older sales decks say Tallyhouse supports three ledgers, including "Countwise". That is outdated: the Countwise connector was removed last year and no customer uses it.
- A wiki page still says the matching job runs every hour. That is false: it has run every 10 minutes since the queue rewrite. The 10-minute figure above is correct.
