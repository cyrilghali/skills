---
name: trace
description: "Explains one concrete user action as a numbered front-to-back call trace: from what the person does in the interface, hop by hop through the entry point, the save, the event, the listener, the job and the query that picks the row, to the data that changes and what the person then sees. Each step is one plain sentence with a file:line read in the session, and the step where the behavior goes wrong is marked. Use when the user asks 'what happens when someone does X', 'trace X front to back', 'follow the request from the button to the database', 'give me the call chain for X', \"what's the trace of X\", \"what event makes X happen\", 'when is X called', 'when are those events emitted', or types '/trace X'. Not for how a whole subsystem works (investigate-first), learning a change or module in depth (teach), why code was built a certain way (why), or adding tracing spans to code."
metadata:
  category: research
---

# Trace one user action front to back

Answer "what happens when someone does X" with a hop list: one numbered step per hop, from the person's action to what they see, each step tied to the line of code that does it.

## Build the hop list in this order

1. **Pin the action and the expected outcome.** Name who acts, what they do and where: a page, a button, an API call, or a scheduled job when no person acts. When the request reports a symptom ("it still asks me", "nothing happens"), write down what the person expected instead. You are done when both fit in one sentence each.

2. **Find the entry point by search.** Grep for the route, GraphQL mutation, controller action, LiveView or channel event, or job that the action reaches. When the front end lives in another repo, grep there for the call it makes, then grep the backend for the matching route. Before you read any code, run `git fetch`, then read and cite every file from the base branch with `git show origin/<base>:<path>`, because a line number from the local checkout may be stale after a merge. You are done when you have read the entry point at a `file:line`.

3. **Follow every hop by reading the callee.** Open each function the flow calls on its way to the effect; never work from recall. A hop is any place where control or data changes hands:
   - validation and the write that saves, with the transaction around it;
   - an event, message or broadcast sent, then every handler that receives it;
   - a job enqueued, then its `perform`;
   - a query that picks rows: read its filters, ordering and limit;
   - a call to another service or repo, then its handler on the far side;
   - notifications, emails, logs and counters the flow fires.

   Treat a call named for its effect (save, send, sync) as the middle of a hop, not its end: open its body down to the query and the write that do it, because the row they pick decides the outcome. At a branch, follow the one this person's case takes and name the other in a clause. You are done when the trace reaches the line that writes the last data change and nothing the flow enqueued or sent is left unread.

4. **Hunt the wrong turn.** At each step that selects or decides, ask what the person's real data holds there: several candidates, none, or a stale one. Check whether the code picks what the person expects. The wrong turn is the first step where the code's choice differs from the expected outcome of step 1. You are done when you can point at that step, or state that every step does what the person expects.

5. **Check the draft.** Write the trace to a scratch file, then run `scripts/check-trace.sh <draft-file> <repo-root> [other repo roots]`. It fails on a step with more than one sentence or citation, a citation that does not resolve, or more than two lines after the list, and it prints the cited line for each step. You are done when it passes and each printed line shows what its step says.

6. **Write the trace** in the format below. You are done when nothing stands before the first step except its title. Record the run with `skill-record trace hops=H wrong_turns=W`. H is the number of steps in the list; W is 1 when a step is marked as the wrong turn and 0 otherwise. Record once, only when the run finished; a dry run or an aborted run records nothing.

## Write the trace in this format

```
**When <person> <does X>**

1. <What happens, one plain sentence.> (`path/to/file.ext:LINE`)
2. ...
4. **Wrong turn:** <what the code picks, and why it is not what the person expects.> (`path:LINE`)
5. <What the person sees or gets.> (`path:LINE`)
```

- Give each step one hop and one sentence. Say what happens to the person's data in plain words; a function name goes in the citation, not the sentence.
- Cite in every step a repo-relative `file:line` checked in this session, the last step included: cite the line that decides what the person sees (the response, the render, or the query that keeps showing the item).
- Mark the wrong turn on its own step, where it happens. When nothing goes wrong, add one line after the list: "No wrong turn: <why the outcome matches>."
- Make step 1 what the person does (clicks, submits, opens), citing the front-end line when that code is reachable, else the entry point.
- Make the last step what appears on the person's screen or in their inbox, not the response body or a database column.
- Write at most two lines after the list: the "no wrong turn" line, or a hop you could not read, labeled "not verified" with the reason.

## Shape the trace like this example

A shopper applies a coupon and the total does not change:

```
**When a shopper applies a coupon at checkout**

1. The shopper submits the code from the cart page, which posts to the coupon endpoint. (`web/cart/coupon_form.tsx:41`)
2. The endpoint looks up the code and attaches it to the cart. (`api/checkout/coupons_controller.rb:18`)
3. **Wrong turn:** the total is recomputed from the cached cart, which was read before the coupon was attached. (`api/checkout/pricing.rb:73`)
4. The cart page shows the old total, with the coupon listed but no discount. (`web/cart/summary.tsx:22`)
```
