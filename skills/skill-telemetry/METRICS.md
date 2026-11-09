# Metrics registry

One row per skill whose run ends with a countable outcome the owner would act on. A skill records with the sentence in its last column, as the last step of its SKILL.md. `up` means a higher number is the better sign, `down` the opposite, `volume` means the number sizes the run and has no good direction. A ratio metric is written `k/n` and lands as two numbers, `k` and `k_of`.

## Verification skills

| Skill | Metrics (unit, direction) | Sentence for the skill's last step |
|---|---|---|
| mutation-test | `mutants` (count, volume), `killed` (k/n, up), `real_survivors` (count, up: a real gap found earns the run), `cosmetic_survivors` (count, down), `tests_added` (count, up) | Record the run: `skill-record mutation-test mutants=N killed=K/N real_survivors=R cosmetic_survivors=C tests_added=T` |
| torture-test | `attacks` (count, volume), `bugs_found` (count, up), `gaps_closed` (count, up), `uncovered_axes` (count, down) | Record the run: `skill-record torture-test attacks=A bugs_found=B gaps_closed=G uncovered_axes=U` |
| blast-radius | `facts_proven` (count, up), `breaks_found` (count, up) | Record the run: `skill-record blast-radius facts_proven=F breaks_found=B` |
| domain-review | `findings_total` (count, volume), `findings_p1` (count, up), `findings_p2` (count, up), `dismissed` (count, down: findings the adversarial check threw out) | Record the run: `skill-record domain-review findings_total=T findings_p1=A findings_p2=B dismissed=D` |
| roast | `rounds` (count, down: fewer rounds to a clean critic), `findings_total` (count, volume) | Record the run: `skill-record roast rounds=R findings_total=F` |
| comment-review | `comments_reviewed` (count, volume), `flagged` (count, up) | Record the run: `skill-record comment-review comments_reviewed=N flagged=F` |

## Shipping skills

| Skill | Metrics (unit, direction) | Sentence for the skill's last step |
|---|---|---|
| babysit | `cubic_findings` (count, volume), `fixed` (count, up), `minutes_to_green` (minutes, down) | Record the run: `skill-record babysit cubic_findings=C fixed=F minutes_to_green=M` |
| intent-pr | `gate_rejections` (count, down: how many times the PR gate refused the body before it passed) | Record the run: `skill-record intent-pr gate_rejections=R` |
| rewrite-commits | `commits_before` (count, volume), `commits_after` (count, down) | Record the run: `skill-record rewrite-commits commits_before=B commits_after=A` |
| pr-breakdown | `decisions` (count, volume), `claims_checked` (count, volume), `claims_dropped` (count, up: a contradicted claim caught before the owner repeats it) | Record the run: `skill-record pr-breakdown decisions=D claims_checked=C claims_dropped=X` |
| perf-factory | `regression_groups` (count, volume), `fixes_proposed` (count, up), `before_ms` and `after_ms` (milliseconds of the top fix's query, after down) | Record the run: `skill-record perf-factory regression_groups=G fixes_proposed=F before_ms=B after_ms=A` |

## Writing and research skills

| Skill | Metrics (unit, direction) | Sentence for the skill's last step |
|---|---|---|
| deep-research | `sources` (count, volume), `claims` (count, volume), `triangulated` (k/n of claims held by two independent sources, up) | Record the run: `skill-record deep-research sources=S claims=C triangulated=K/C` |
| prose | `tells_before` (count, volume), `tells_after` (count, down) | Record the run: `skill-record prose tells_before=B tells_after=A` |
| trace | `hops` (count, volume), `wrong_turns` (count, up: the trace found the step where the code goes wrong) | Record the run: `skill-record trace hops=H wrong_turns=W` |

## Routine skills: a verdict plus one count the skill already computes

| Skill | Metrics (unit, direction) | Sentence for the skill's last step |
|---|---|---|
| deploy-watch | `verdict` (text: healthy, watch or regression), `signals_measured` (count, volume) | Record the run: `skill-record deploy-watch verdict=healthy signals_measured=N` |
| weekly-weeding | `verdict` (text: the first line), `candidates` (count, down) | Record the run: `skill-record weekly-weeding verdict="..." candidates=C` |
| complexity-trend | `verdict` (text: the one-line answer), `findings_per_kloc` (findings per 1,000 lines, down) | Record the run: `skill-record complexity-trend verdict="..." findings_per_kloc=F` |
| observability-trend | `verdict` (text: the one-line answer), `regressions` (count, down) | Record the run: `skill-record observability-trend verdict="..." regressions=R` |
| linear-project-hygiene | `verdict` (text: daily or weekly), `repaired` (count, volume), `flagged` (count, down) | Record the run: `skill-record linear-project-hygiene verdict=daily repaired=R flagged=F` |
| context-hygiene | `verdict` (text: the one-sentence answer), `tokens_saved` (tokens, up), `cut_items` (count, volume) | Record the run: `skill-record context-hygiene verdict="..." tokens_saved=T cut_items=C` |

## Not eligible, and why

A skill is dropped when its run ends in something the owner reads or uses later, with no count that says whether it worked.

| Skill | Why its outcome is not countable |
|---|---|
| bro | Restates the last reply in plain words. It worked when the owner understood, which only the owner's next message shows. |
| ascii-graph | Draws a diagram. Node and edge counts size the drawing and say nothing about whether it explained anything. |
| handoff | Opens another session with a brief. The outcome belongs to that session's own skills, which record their own runs. |
| teach | Weaves `how` and `why` into one account. Its outcome is understanding, with no number at the end of the run. |
| how | Explains a subsystem. Same reason as teach; it also runs inside teach, so a count would land twice. |
| why | Grades each claim about a code decision as confirmed, supported or inferred, but the grades describe the evidence, not whether the answer helped. |
| readme | Rewrites a front page. Its quality shows when a stranger uses the project, not at the end of the run. |
| recall | Returns a digest of past sessions. A bullet count sizes the digest; whether the right bullets came back shows only in the work that follows. |
