# Fact key: case 1 (judge only; the generator never sees this file)

Depth tag: broad = anyone new should know it; deep = an engineer who changes the code needs it.

| id | fact | depth | status |
|---|---|---|---|
| F01 | Tallyhouse matches card spending to receipts and to the accounting ledger | broad | true |
| F02 | Buyers are finance teams at companies of 50 to 2,000 people | broad | true |
| F03 | The controller signs; accountants use it daily | broad | true |
| F04 | Three expense states: captured, matched, booked; none is skipped | broad | true |
| F05 | Receipts come by mobile photo or forwarded email | broad | true |
| F06 | About 70% of receipts come by email | broad | true |
| F07 | Auto-match needs an exact amount and dates within 3 days; else review queue | broad | true |
| F08 | Pricing is per active card per month; active = at least one transaction that month | broad | true |
| F09 | Two ledgers supported (Ledgermate, Booksy); one at a time | broad | true |
| F10 | One Python service, Postgres, one JSON API for web and mobile | deep | true |
| F11 | Webhook stores raw payload first, parses in a background job | deep | true |
| F12 | Matching job runs every 10 minutes over captured expenses of the last 60 days | deep | true |
| F13 | Unique index on issuer transaction ID stops duplicate webhooks creating duplicates | deep | true |
| F14 | Receipts in object storage; DB keeps file key and SHA-256; hash warns on duplicate upload | deep | true |
| F15 | OCR calls retried 3 times with backoff, then "needs manual entry" | deep | true |
| F16 | Booking runs as a separate job per customer, isolating ledger outages | deep | true |
| F17 | Ledger tokens encrypted at rest with a cloud key-manager key | deep | true |
| F18 | Audit log is append-only; app DB user has no UPDATE/DELETE on it | deep | true |
| F19 | Booked expenses are fixed by reversal plus a corrected booking, never edited | broad or deep | true |
| F20 | Money stored as integer minor units plus ISO currency code; no floats | deep | true |
| F21 | FX uses the issuer's rate on the transaction date | deep | true |
| F22 | PRs need one approval and green CI; CI uses a real Postgres | deep | true |
| F23 | Main deploys automatically several times a day | deep | true |
| F24 | A column-dropping migration ships in a deploy after the code stops reading it | deep | true |
| F25 | Feature flags are per customer | deep | true |
| F26 | On-call paged when webhook error rate > 2% for 5 minutes | deep | true |
| F27 | Engineer-needed tickets tagged "eng-escalation", answered within one working day | broad or deep | true |
| X1 | Tallyhouse supports a third ledger, Countwise | — | outdated: must be dropped or flagged |
| X2 | Matching job runs every hour | — | false: must be dropped or flagged |

27 true facts, 2 to catch. 18 of the true facts are deep or mostly deep.
