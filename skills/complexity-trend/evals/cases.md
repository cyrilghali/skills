# complexity-trend eval cases

Each case gives a generation agent everything it needs without asking questions: the
script's printed output (step 1 already ran). The agent applies `SKILL.md` step 2 and
returns only the weekly reading. A judge scores it against `rubric.md`. The `Trap`
field names the failure mode the case is designed to catch. The real-checkout proof
(step 1 on an actual repo) is `run.md`, not a case here.

## Case 1 — a real rise

**Input:**
```
2026-03-02 @ 9f1c2ab: 1302 complexity findings (41 under the project's own Credo config), 2210 Credo findings, 88 duplicated-code findings, 301200 lines in 3120 modules, 4.32 complexity findings per 1,000 lines.
Week on week (since 2026-02-23, 151 PRs merged): complexity +34 (+2.7%) (own config +1), per 1,000 lines +0.08, Credo +12 (+0.5%), duplicated +3 (+3.5%), lines +1400 (+0.5%), modules +9 (+0.3%).
30-day (since 2026-01-30, 604 PRs merged): complexity +121 (+10.2%) (own config +2), per 1,000 lines +0.30, Credo +40 (+1.8%), duplicated +11 (+14.3%), lines +7300 (+2.5%), modules +40 (+1.3%).
History: /var/lib/complexity-trend/history.tsv
```
**Trap:** Leading with raw counts, or omitting the merged pull request count from the answer line.

## Case 2 — growth, not decay

**Input:**
```
2026-03-02 @ 1ab22cd: 1188 complexity findings (40 under the project's own Credo config), 2150 Credo findings, 80 duplicated-code findings, 330000 lines in 3300 modules, 3.60 complexity findings per 1,000 lines.
Week on week (since 2026-02-23, 140 PRs merged): complexity +20 (+1.7%) (own config +0), per 1,000 lines -0.02, Credo +5 (+0.2%), duplicated +0 (+0.0%), lines +6000 (+1.9%), modules +30 (+0.9%).
30-day (since 2026-01-30, 590 PRs merged): complexity +88 (+8.0%) (own config +1), per 1,000 lines -0.07, Credo +21 (+1.0%), duplicated +2 (+2.6%), lines +30000 (+10.0%), modules +150 (+4.8%).
History: /var/lib/complexity-trend/history.tsv
```
**Trap:** Reporting "complexity rose 8%" as the headline when density fell; the honest reading is growth.

## Case 3 — first run

**Input:**
```
2026-03-02 @ 77aa001: 1250 complexity findings (38 under the project's own Credo config), 2190 Credo findings, 85 duplicated-code findings, 300000 lines in 3100 modules, 4.17 complexity findings per 1,000 lines.
Week on week: no earlier row yet.
30-day: no earlier row yet.
History: /var/lib/complexity-trend/history.tsv
```
**Trap:** Reading a trend or a verdict ("complexity is high") into a single data point.

## Case 4 — the config cannot see it

**Input:**
```
2026-03-02 @ 3c3c3c3: 940 complexity findings (0 under the project's own Credo config), 1500 Credo findings, 60 duplicated-code findings, 250000 lines in 2800 modules, 3.76 complexity findings per 1,000 lines.
Week on week (since 2026-02-23, 120 PRs merged): complexity +15 (+1.6%) (own config +0), per 1,000 lines +0.04, Credo +0 (+0.0%), duplicated +1 (+1.7%), lines +600 (+0.2%), modules +4 (+0.1%).
20-day (30-day baseline not reached yet) (since 2026-02-10, 360 PRs merged): complexity +44 (+4.9%) (own config +0), per 1,000 lines +0.14, Credo +2 (+0.1%), duplicated +4 (+7.1%), lines +2000 (+0.8%), modules +12 (+0.4%).
The project's own Credo config reports zero complexity findings; only the force-enabled checks see any.
History: /var/lib/complexity-trend/history.tsv
```
**Trap:** Suggesting to enable checks in `.credo.exs` or lower thresholds as the fix, or reading the 20-day window as a full 30-day trend.

## Case 5 — the measurement failed

**Input:**
```
** (Mix) Could not fetch dependency: hex package tls_certificate_check (network timeout)
Traceback (most recent call last):
  ...
subprocess.CalledProcessError: Command '['mix', 'deps.get']' returned non-zero exit status 1.
```
Running `scripts/complexity_trend.py --report` afterwards printed:
```
2026-02-23 @ 5d5d5d5: 1268 complexity findings (41 under the project's own Credo config), 2198 Credo findings, 85 duplicated-code findings, 299800 lines in 3111 modules, 4.23 complexity findings per 1,000 lines.
Week on week (since 2026-02-16, merged PR count unavailable): complexity +10 (+0.8%) (own config +0), per 1,000 lines +0.02, Credo +3 (+0.1%), duplicated +1 (+1.2%), lines +500 (+0.2%), modules +2 (+0.1%).
7-day (30-day baseline not reached yet) (since 2026-02-16, merged PR count unavailable): complexity +10 (+0.8%) (own config +0), per 1,000 lines +0.02, Credo +3 (+0.1%), duplicated +1 (+1.2%), lines +500 (+0.2%), modules +2 (+0.1%).
```
**Context (pre-answered):** Today is 2026-03-02.
**Trap:** Presenting last week's numbers as today's reading, or dropping the error.

## Case 6 — the config sees it

**Input:**
```
2026-03-02 @ 6e6e6e6: 1410 complexity findings (402 under the project's own Credo config), 2300 Credo findings, 90 duplicated-code findings, 310000 lines in 3200 modules, 4.55 complexity findings per 1,000 lines.
Week on week (since 2026-02-23, 133 PRs merged): complexity +34 (+2.5%) (own config +30), per 1,000 lines +0.10, Credo +14 (+0.6%), duplicated +2 (+2.3%), lines +900 (+0.3%), modules +6 (+0.2%).
30-day (since 2026-01-30, 570 PRs merged): complexity +120 (+9.3%) (own config +105), per 1,000 lines +0.29, Credo +30 (+1.3%), duplicated +6 (+7.1%), lines +7000 (+2.3%), modules +35 (+1.1%).
History: /var/lib/complexity-trend/history.tsv
```
**Trap:** Saying the project's config cannot see the trend when its own count rises in step.

## Case 7 — a quiet month

**Input:**
```
2026-03-02 @ 7f7f7f7: 1260 complexity findings (41 under the project's own Credo config), 2200 Credo findings, 85 duplicated-code findings, 300500 lines in 3110 modules, 4.19 complexity findings per 1,000 lines.
Week on week (since 2026-02-23, 112 PRs merged): complexity +1 (+0.1%) (own config +0), per 1,000 lines +0.00, Credo +1 (+0.0%), duplicated +0 (+0.0%), lines +100 (+0.0%), modules +0 (+0.0%).
30-day (since 2026-01-30, 470 PRs merged): complexity +0 (+0.0%) (own config +0), per 1,000 lines +0.00, Credo +2 (+0.1%), duplicated +0 (+0.0%), lines +300 (+0.1%), modules +1 (+0.0%).
History: /var/lib/complexity-trend/history.tsv
```
**Trap:** Inventing a direction or padding judgment lines when density held and nothing needs flagging.
