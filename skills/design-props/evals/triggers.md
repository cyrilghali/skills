# design-props trigger queries

Ten queries need the skill and ten are near misses that share its words but need another job.
Eight are held out (four of each kind) and were never read while tuning the description.
Each query ran three times in a fresh headless session; Result is the majority.

| # | Query (as a user would type it) | Should trigger | Held out | Result |
|---|---|---|---|---|
| 1 | Give me three or four design options for our notification system and compare them. | yes | no | fired (3/3), pass |
| 2 | Compare event sourcing vs a stateful table vs a hybrid for our order history, grounded in the actual code. | yes | no | fired (2/3), pass |
| 3 | I need a comparative architecture study for moving our job queue off Redis: several approaches, a matrix, a recommendation. | yes | no | fired (2/3), pass |
| 4 | Propose several designs for multi-tenant rate limiting and tell me which tradeoff is the real one. | yes | yes | fired (3/3), pass |
| 5 | Write up competing technical approaches for caching user sessions, with costs and migration risk for each. | yes | no | fired (2/3), pass |
| 6 | Before we pick, lay out several distinct ways to model subscriptions in our codebase and compare them. | yes | no | fired (3/3), pass |
| 7 | design study: 3 philosophies for audit logging, critique each one, then a synthesis | yes | yes | fired (3/3), pass |
| 8 | We keep arguing about how to store analytics events. Produce competing proposals and a comparison so the decision is obvious. | yes | no | fired (2/3), pass |
| 9 | compare approaches for offline sync in our mobile app, options side by side with what each one costs | yes | yes | fired (2/3), pass |
| 10 | Lay out the design alternatives for search (pgvector, Elasticsearch, Typesense) against our schema, with a phased path. | yes | yes | fired (2/3), pass |
| 11 | Write a design spec for the new export feature. | no | no | not fired (0/3), pass |
| 12 | Grill me on my plan to split the monolith into services. | no | no | not fired (0/3), pass |
| 13 | Which is better for a side project, Postgres or MongoDB? Just a quick answer. | no | yes | not fired (0/3), pass |
| 14 | Review this PR's architecture and tell me what to fix. | no | no | not fired (0/3), pass |
| 15 | Try this refactor three ways in parallel and merge the best attempt. | no | no | not fired (0/3), pass |
| 16 | Give me three UI mockup options for the settings page. | no | yes | not fired (0/3), pass |
| 17 | Decide the module boundaries and interfaces for the new billing feature before I start coding. | no | yes | not fired (0/3), pass |
| 18 | Explain how our current caching layer works. | no | no | not fired (0/3), pass |
| 19 | Compare the pricing of AWS and GCP for a small VM. | no | yes | not fired (0/3), pass |
| 20 | Stress test this diff and poke holes in it. | no | no | not fired (0/3), pass |

All twenty pass, held-out queries included (8 of 8). The only other skill that fired on a near miss was a plan-grilling skill, on query 12.
