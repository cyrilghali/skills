---
name: roast
description: Roasts a finished output against a written definition of excellent for its category, and sets the output's own bar first. Start it when a deliverable task begins, before the first file or draft is written, not only once the output is finished. Each round, a fresh independent critic asks hard questions against the category's checks, references and known failures; the author fixes what holds up; rounds repeat until one finds nothing new. Works on reports and pages, docs, replies, PRs, code, skills, UI, research answers and video. Use when the user says "roast this", "roast it", "is this excellent", "push it further", "done is not good", before publishing an Artifact, or before showing a finished output that a category file covers.
metadata:
  category: verify
---

# Roasting a finished output

Done is not good. Take an output that looks finished and ask, round after round, whether it meets the bar its category file names. Never grade your own work: every round is a fresh critic that has not seen the reasoning behind the output.

## Gather the output and its category file

Get the output: a file, a URL, a PR, a video, or pasted text.

Find its category file, `<category>.md`, in the excellence folder. That folder is `$ROAST_DIR`; when it is not set, use `excellence/` in the folder that holds the skills folder. Each category file follows `CATEGORY.md`: observable checks, references, and the owner's recurring failures. List the folder to pick the category. Only a file that follows `CATEGORY.md` is a bar; the other files there are not. When no category fits, say so and stop, because a roast without a bar is an opinion.

When the owner judges the result by taste (a video, a page, a design), roast the plan once, then build one finished sample and roast that sample. Do not run more plan rounds or score the plan: the owner needs to see a result to judge.

## Run the roast

0. **Have the bar set by someone else.** The category file is the general bar. This output also has its own bar, and the author never writes it. Before the first draft, start a fresh subagent at high effort: the `bar-setter` agent from `INSTALL.md`, else any fresh subagent. Hand it `BAR.md` filled in with the request word for word, the facts about its reader, and the category file. Never hand it a draft; when the output already exists, the bar-setter still never sees it. Create a run folder (the host's scratchpad, else `./.roast/<slug>/`) and save the reply word for word as `bar.md`. Write the category file's absolute path on one line in `category.txt` next to it, so every later round reads the same file after a compaction. Done when `bar.md` holds a reader, their tasks, and observable situational and bias checks.
1. **Freeze the before.** Copy the output into the run folder as `before.<ext>`. For a page or a video, run `scripts/capture.sh <output> <run>/shots before`, then look at every PNG it prints. Done when the copy and the captures exist and you have seen them.
2. **Run a round.** Start one fresh subagent on the strongest model at high effort: the `roast-critic` agent from `INSTALL.md`, whose hook blocks state-changing commands, else a `verifier` agent if the host defines one. Hand it `ROUND.md` filled in: the round number and lens, the output path, the captures, the category file, `bar.md`, and `ledger.md` (empty in round 1). Hand it nothing else: not your reasoning and not the brief that produced the output, because a critic who knows the intent forgives the output. Done when it returns findings in the `ROUND.md` format, with PASS, FAIL or N/A and its evidence for every check in the category file and in `bar.md`, and you have saved them word for word as `round-<n>.md` in the run folder.
3. **Triage each finding.** First list the check numbers scored FAIL in `round-<n>.md` and the `check:` values of its findings. A FAIL check with no finding gets one, written from the scorecard evidence, with the fix that answers that evidence, before triage starts, because a FAIL with no finding is never fixed. Then give each finding one of three statuses. `fix`. `dismiss`, with a reason that cites the category file. `open`, with a reason, when the fix needs a fact no source holds or a decision only the owner can make. Decide this way:
   - A finding that names a check, a reference or a measured value wins, unless the output proves it wrong.
   - A finding that rests on taste alone, with no check or reference behind it, is dismissed.
   - A finding whose fix adds an operation outside the output's stated scope gets `dismiss` or `open`, never `fix`. When you dismiss it for scope, write the reader's question behind it in the ledger and apply the smallest in-scope answer to that question: a line saying where or how, not the dismissed operation.
   - A finding that rests on a fact about the subject is triaged only after you check the source that settles it, and the reason quotes that source.
   - A finding that asks to fact-check the output's own claims is `fix` in the round it is raised, never deferred or `open`. Check each claim against its source in that round and correct or cut the false and partly true ones.

   Append every finding to `ledger.md` with its round, status and reason. Done when no finding lacks a status.
4. **Fix.** Apply every `fix` to the output itself, then re-capture it as `after-r<n>` (for text, copy it as `after-r<n>.<ext>`). Prefer the fix that cuts. A fix that adds words or elements names the check that requires them, and the output stays as short as its checks allow. Record the output's size in `ledger.md` after each round. When a round's new blocker or major findings land in text that the previous round's fixes added, cut that text instead of patching it. A fix adds no fact that the output's own sources do not hold. Done when each fixed finding points to the change that answers it.
5. **Decide whether to stop.** Run at least two rounds. Stop when a round returns no new blocker or major finding. New means not already in the ledger under the same check and location. A finding the critic skipped as already in the ledger still counts as open until the ledger's smallest in-scope answer to its reader's question is in the output; the critic checks that it is. Stop after five rounds in any case. If you continue, go to step 2 with the next lens. When you stop, save the output as `scored.<ext>` in the run folder and run one more fresh critic on that copy with the lens Score only, so the after scorecard describes what the user gets. The output is frozen once that critic starts: list its findings as open and never apply them, because an edit after the score ships unscored text. The one exception is a factual error the critic backs with a source: fix it, save the result as a new `scored.<ext>`, and run the score-only critic again, or pull the output. Never ship it as "open".
6. **Show the user the before and after.** First compare the live output with `scored.<ext>`: `cmp`, `shasum` for a page or video, or fetch the URL again. When they differ, the score does not describe what the user gets: say so, and either run the score-only critic again on the live output or report the score as stale. Then give the user the scorecard (each check, its result in round 1 and in the last round), the ledger, and the before and after side by side: captures for pages and video, a diff for text. Done when the user can judge the change without opening the run folder. Record the run with `skill-record roast rounds=R findings_total=F`, once, only when the run finished; a dry run or an aborted run records nothing. R is the number of numbered rounds run, without the score-only critic. F is the number of entries in `ledger.md`.

## Give each round its lens

| Round | Lens | The critic's main question |
|---|---|---|
| 1 | Checks | Does each check in the category file pass, with evidence? |
| 2 | Reader | Experienced cold, as the intended reader would, does it solve the problem, hang together, and leave no question open? |
| 3 | References | Put next to each reference in the category file, where does it fall short? |
| 4 | One level deeper | Which detail would the owner notice that a customer never would: a word, a pixel, an easing, an edge case? |
| 5 | Checks again | Did the fixes break a check that passed before? |
| final | Score only | Score every check on the final version; no new rounds follow. |

Every round scores every check. N/A counts in neither the passes nor the total. The final critic gives the after scorecard.

## Follow this example

Roast a doc with a category file `docs.md`. Round 1 fails check 3 ("the first screen states the goal"): the page opens on history. The critic also flags a link that points to a moved page. Fix both. Round 2, the reader lens, finds that step 4 has no expected output. Fix that too. Round 3 finds only one minor wording point, so stop. Report 7 of 10 checks passing before and 10 of 10 after, with the two versions side by side.

## Open these files when a step needs them

- `BAR.md`: the bar-setter prompt and the format of `bar.md`.
- `ROUND.md`: the critic prompt and the format of its findings.
- `CATEGORY.md`: the shape of a category file, for writing a new one.
- `scripts/capture.sh`: page captures (light and dark themes, desktop and phone widths) and video frames.
