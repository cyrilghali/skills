# plan-series eval cases

Each case gives a generation agent everything it needs without asking questions. The agent applies `SKILL.md` and returns only the plan and its briefs. A judge scores it against `rubric.md`, with the case's fact key from `fixtures/` in hand.

Each fixture is a source document of 15 to 40 checkable facts. Some facts are deep. One or two are false or outdated, and the source itself says so. The matching `*.facts.md` file is the judge's fact key; the generation agent never sees it.

The **Input** is what the generation agent receives, reworded as a plain request, plus the fixture copied alone into its scratch folder. The **Trap** names the failure the case is built to catch.

## Case 1 — Mixed-audience onboarding funnel for a product

**Held out:** no
**Source:** real use (an engineering manager's request for a product onboarding series), retold with a fictional product
**Fixture:** `fixtures/case1-tallyhouse.md` (key: `case1-tallyhouse.facts.md`, 27 true facts, 2 to catch)
**Input:** "I run engineering at Tallyhouse. Plan our onboarding video series from the notes in tallyhouse.md. The first two or three videos are for anyone joining, sales and support included, so each has to make sense on its own. After those, technical deep dives for engineers who will change the code. Keep the zoom-out and the deep dives apart without making more content than we need. Write the plan, and a short brief per video that the person making it can start from."
**Audiences:** anyone new (sales, support, engineers); engineers who will change the code.
**Goal:** a new hire can explain what Tallyhouse does and how an expense moves through it; an engineer can then change the backend safely.
**Context (pre-answered):** "Too deep for onboarding" is never a reason to drop a true fact; a deep fact moves to a deep dive. The deep dives must not repeat what the broad videos taught.
**Trap:** The plan drops engineering facts (audit log rights, migration order, FX rule) as "too deep for onboarding", or lets a deep dive re-explain the three expense states, or gives a broad video a "watch video 1 first" dependency. It also repeats the stale "three ledgers" and "matching every hour" claims.

## Case 2 — A one-page checklist that needs one unit

**Held out:** no
**Source:** synthetic
**Fixture:** `fixtures/case2-bakery-close.md` (key: 15 true facts, 1 to catch)
**Input:** "I own a small bakery. Can you plan a training video series for new counter staff from our closing checklist (bakery-close.md)? I want them to get it right on their first evening."
**Audiences:** new counter staff on the evening shift.
**Goal:** a new staff member can close the front counter alone on their first evening.
**Context (pre-answered):** Staff watch on their phone before their first shift. No other audience.
**Trap:** The plan inflates one short task into a multi-episode series (one video for cash, one for cleaning, one for security), with intros and recaps, when one unit of a few minutes does the job. It also keeps the outdated 200-euro float.

## Case 3 — Deep facts the request invites dropping

**Held out:** no
**Source:** synthetic
**Fixture:** `fixtures/case3-recycling.md` (key: 25 true facts, 12 deep, 2 to catch)
**Input:** "Our town is launching new recycling rules on 1 March. Plan a short video series from the summary in recycling.md. Most viewers are residents, so keep it simple. The private haulers who collect the bins need to know their side too."
**Audiences:** residents; hauler crews and hauler managers.
**Goal:** residents put the right things in the right bin on the right day; haulers apply the lid check and keep loads under the rejection threshold.
**Context (pre-answered):** One plan covers both audiences. Residents should never have to watch hauler content.
**Trap:** "Keep it simple" becomes the excuse to drop the hauler contract numbers, the plant economics and the reasons for the change, instead of placing them in a hauler tier or a later "why" unit. It also repeats the false greasy-pizza-box rule or the removed 50-euro fine.

## Case 4 — High-stakes source where every fact must be placed

**Held out:** no
**Source:** synthetic
**Fixture:** `fixtures/case4-ward.md` (key: 30 true facts, 2 to catch)
**Input:** "I'm the practice educator on an acute medicine ward. Plan a short training series for newly registered nurses from our local induction handbook (ward-handbook.md). This is patient safety: nothing in the handbook can be left out."
**Audiences:** newly registered nurses joining the ward.
**Goal:** a new nurse can work a shift on the ward safely: escalate a deteriorating patient, give medicines safely, prevent falls, pressure ulcers and infection.
**Context (pre-answered):** Nurses watch the first units before their first shift and the rest during their first two weeks.
**Trap:** The plan covers the headline topics but silently loses smaller rules (insulin syringes, patients' own medicines, sharps fill line, needlestick timing), or keeps the outdated 4-hour observations or bleep 3333.

## Case 5 — Documentation series for an open-source library

**Held out:** yes
**Source:** synthetic
**Fixture:** `fixtures/case5-pacer-lib.md` (key: 22 true facts, 2 to catch)
**Input:** "I maintain pacer, a small Python rate-limiting library. We are rewriting the docs as a set of pages instead of one long README. Here are my notes (pacer-notes.md). Plan which pages to write, in what order, for whom, and give each page a short brief."
**Audiences:** first-time users; users scaling across processes or machines; contributors.
**Goal:** a new user rate-limits a function in five minutes; a user scaling out shares a limit through Redis and knows what happens when Redis fails; a contributor can run the tests and ship a change.
**Context (pre-answered):** The units are documentation pages, not videos. An API reference is generated from docstrings and is out of scope.
**Trap:** The plan follows the code's modules instead of what each reader needs to do, lets a contributor page re-teach the token bucket already explained to users, or documents the removed `RateLimiter` class or the "safe across processes" claim as current.

## Case 6 — A university course module with an optional quantitative track

**Held out:** yes
**Source:** synthetic
**Fixture:** `fixtures/case6-groundwater.md` (key: 21 true facts, 2 to catch)
**Input:** "I'm putting together the groundwater module of a second-year environmental science course. Plan the lessons from my source notes (groundwater-notes.md). Everyone takes the core; the hydrology-track students also do a quantitative problem set."
**Audiences:** all second-year students; hydrology-track students.
**Goal:** every student can explain where groundwater is, how it moves and why over-pumping and contamination are hard to undo; hydrology-track students can apply Darcy's law to a field problem.
**Context (pre-answered):** Lessons are about 50 minutes each. The core must not depend on the quantitative lessons.
**Trap:** The plan mixes Darcy's law into the core lessons or makes a core lesson depend on a quantitative one, teaches the "underground rivers" misconception as fact, or keeps the outdated "half of world drinking water" figure.
