# comment-review eval cases

Each case gives a generation agent everything it needs without asking questions.
The agent applies `SKILL.md` and returns only the review report. A judge scores it against `rubric.md`.

## Case 1 — Canonical: mixed diff, several classes

**Input:** Review the comments in this diff.

```diff
diff --git a/lib/acme/assistant/rating_feedback.ex b/lib/acme/assistant/rating_feedback.ex
index 6e75764..d43d1e9 100644
--- a/lib/acme/assistant/rating_feedback.ex
+++ b/lib/acme/assistant/rating_feedback.ex
@@ -1,5 +1,17 @@
 defmodule Acme.Assistant.RatingFeedback do
+  @moduledoc """
+  Sends a rating to the metrics service. We discussed in the ENG-482 review thread and decided to log
+  failures instead of retrying, since Alex thought retries would double-count on flaky sends.
+  """
+
   alias Acme.Clock
   alias Acme.ExternalApi.MetricsApi

+  # TODO: remove this once the v1 feedback endpoint is retired
+  def legacy_submit(rating), do: MetricsApi.submit_rating(%{trace_id: nil, label: "legacy", value: rating})
+
+  # sends the rating for all three channels: like, dislike, and retraction
+  def send(conversation, message_id, feedback) do
+    :ok
+  end
+
   @doc "Returns the count of ratings sent so far, and the count of ratings dropped."
   def stats, do: %{sent: sent_count(), dropped: 0}
 end
```

Final line numbers, so you don't need to derive them from the hunk header: moduledoc is lines 2-5, the TODO is line 10, the "three channels" comment is line 13, `def send/3` is line 14 (it takes `conversation`, `message_id`, `feedback` — three arguments), the `@doc` is line 18.

Context: `router.ex` in this repo was already fully migrated off the v1 feedback endpoint two releases ago (no route mounts it) — `legacy_submit/1`'s TODO condition already happened. `send/3`'s body is only `:ok`, no branching on `feedback` at all — the "three channels" comment describes intended future behavior the body doesn't implement yet. `stats/0`'s `dropped: 0` is hardcoded and always has been; this predates the diff (the diff doesn't touch `stats/0`), but the `@doc` right above it ("the count of ratings dropped") reads as if a real count is tracked, which is false today and was already false before this diff — it's an already-stale comment sitting in the same reviewed hunk as context.

**Trap:** Five comments, four different problems, plus a genuinely fine-sounding one (`@doc "Returns the count..."` would be unguessable-only if its content were true — but it's inaccurate right now, testing whether the agent verifies against real state rather than approving on style alone, and whether it still flags a comment that the diff itself didn't touch but left sitting in view). A weak skill either lumps everything under one vague "these comments are bad" note, misses the accuracy problem in the `@doc` because "this diff didn't change that line," or nitpicks the acceptable parts of the moduledoc's tone instead of naming the discussion-rationale violation precisely.

## Case 2 — Trivial diff that must not get inflated

**Input:** Review the comments in this diff.

```diff
diff --git a/lib/acme/billing/invoice_number.ex b/lib/acme/billing/invoice_number.ex
index a1b2c3d..e4f5a6b 100644
--- a/lib/acme/billing/invoice_number.ex
+++ b/lib/acme/billing/invoice_number.ex
@@ -12,7 +12,7 @@ defmodule Acme.Billing.InvoiceNumber do
   # Padded to 6 digits so invoice numbers sort lexicographically same as numerically.
   def format(seq) when is_integer(seq) do
-    String.pad_leading(Integer.to_string(seq), 5, "0")
+    String.pad_leading(Integer.to_string(seq), 6, "0")
   end
 end
```

**Trap:** Only one comment in scope, and it is already accurate, unguessable (padding width and the reason are not visible from the code alone), problem-free, and not rot. The diff even fixed a bug that made the comment's claim true again. A weak skill invents extra findings to look thorough — flagging the function for a "missing @doc", proposing a rewrite the comment doesn't need, or padding the report with unrelated style notes.

## Case 3 — File review where the honest answer is "nothing to do"

**Input:** Review the comments in this file.

```elixir
defmodule Acme.ExternalApi.MetricsApi do
  @moduledoc "https://docs.datadoghq.com/llm_observability/instrumentation/api/#evaluations-api"

  def configured?, do: is_binary(config()[:api_key]) and is_binary(config()[:ml_app])

  # Unlike the tracing spans, feedback given after a turn's trace already closed has nowhere
  # else to attach, so it goes through this side-channel intake instead.
  def submit_rating(%{trace_id: trace_id, label: label, value: value, assessment: assessment} = feedback)
      when assessment in ["pass", "fail"] do
    post(build_payload(trace_id, label, value, assessment))
  end

  defp config, do: Application.get_env(:acme, __MODULE__, [])
end
```

**Trap:** Every comment here already passes all seven checks (moduledoc is a bare doc link, the inline comment names the counterpart — tracing spans — and the problem — nowhere else to attach — in one sentence over two lines, one fact, so brevity passes, no rot, no discussion). A weak skill manufactures a finding anyway ("the moduledoc could say more", "add a @doc to configured?") to avoid returning an empty report, or under-verifies and declares things fine without stating what it checked.

## Case 4 — High-stakes: exhaustive, must catch staleness outside the diff

**Input:** Review the comments in this diff. The repo is large; check for anything this rename made false elsewhere.

```diff
diff --git a/src/docs/permissions.ts b/src/docs/permissions.ts
index 50a6097..f597d0d 100644
--- a/src/docs/permissions.ts
+++ b/src/docs/permissions.ts
@@ -40,7 +40,7 @@ export function listVisible(user: User): Doc[] {
   return allDocs().filter((d) => canView(user, d));
 }
 
-export const isEditable = (doc: Doc) => !doc.lockedBy;
+export const canEditDoc = (doc: Doc) => !doc.lockedBy && doc.status !== "archived";
```

You have access to the rest of the repository; grep it for `isEditable` before concluding.

Other files in the repo (pre-existing, not part of this diff):

```ts
// src/api/docs.ts
/** Saves changes to a doc. Only call this for docs where permissions.isEditable() is true. */
export function saveDoc(doc: Doc, patch: Patch) { ... }
```

```ts
// test/docs/permissions.test.ts
// isEditable excludes locked docs; archived docs are covered separately below
test("only editable docs accept a patch", () => { ... });
```

**Trap:** The rename (`isEditable` to `canEditDoc`, plus a new archived-status condition) makes two comments elsewhere in the repo wrong: the JSDoc in `docs.ts` names a function that no longer exists under that name, and the test comment's "archived docs are covered separately below" is now false, because the function itself excludes archived docs and nothing else handles them. A weak skill reviews only the two diff lines and never greps, missing both stale comments; a merely-adequate one finds the renamed reference but misses that the test comment's claim about archived docs is now factually wrong, not just a naming mismatch.

## Case 5 — Curse of knowledge: comment reads fine to a project insider

**Input:** Review the comments in this diff. This is for the billing team, who all know the PLAT-212 ticket and the currency-fallback convention already.

```diff
diff --git a/billing/totals.py b/billing/totals.py
index 93f6538..2ac14df 100644
--- a/billing/totals.py
+++ b/billing/totals.py
@@ -40,3 +40,10 @@ def format_money(amount):
     return f"{amount:.2f}"
 
 
+# Per PLAT-212: after syncing with the finance team we agreed the old per-line rounding
+# was wrong, so as we said in retro this now rounds per invoice. Dana wanted the
+# currency fallback to stay the way it already worked.
+def invoice_total(invoice, rates):
+    rate = rates.get(invoice.currency) or rates.default
+    return round(sum(line.amount for line in invoice.lines) * rate, 2)
+
```

Final line numbers: the three-line comment is lines 43-45, `def invoice_total(invoice, rates):` is line 46, the body is lines 47-48. The code is complete above (no elided lines), so every claim in the comment is checkable against what is shown: the `round` call wraps the whole sum, and `rates.get(invoice.currency) or rates.default` is the whole fallback rule.

**Trap:** The comment is grammatically fine and uses vocabulary the team recognizes (PLAT-212, "currency fallback", "already worked"), which can read as acceptable house style to a generation pass that pattern-matches on project jargon. It is pure discussion transcript ("after syncing with the finance team", "as we said in retro", "Dana wanted") with no stated technical reason a future reader who wasn't in the meeting can use, and it never explains the actual invariant the code shows (rounding happens once on the invoice sum, so per-line rounding errors do not accumulate). A weak skill accepts it because it "sounds like it belongs here", or produces a rewrite that drops the chat language but still doesn't name what the single `round` is for.

## Case 6 — Brevity: one fact over two lines passes, two facts on one line does not

**Input:** Review the comments in this file.

```go
package ratelimit

import "time"

// Window matches the gateway's per-minute quota reset; it lasts 60 seconds.
const window = 60 * time.Second

const limit = 1000

type Limiter struct{ used int }

// Counted at reserve time, not on completion: the gateway bills on the first byte,
// so a retried upload costs quota twice.
func (l *Limiter) Reserve(n int) bool {
	if l.used+n > limit {
		return false
	}
	l.used += n
	return true
}
```

Final line numbers: the `window` comment is line 5, the two-line `Reserve` comment is lines 12-13.

**Trap:** The two-line comment on `Reserve` carries one fact the code cannot show (why quota is counted at reserve time), so it must be kept despite spanning two lines. The line-5 comment carries two facts, and the second one restates the `60 * time.Second` value of `window`. A weak skill flags every multi-line comment, or keeps the line-5 comment because it is a single line.
