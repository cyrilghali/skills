---
name: torture-test
description: Adversarial QA pass that tries to break code and its test suite only where a named beneficiary gains from it — hostile inputs, invariant/property checks, concurrency and retry storms, resource ceilings, interrupted state — with mutation testing delegated to the mutation-test skill. Findings first, new tests second, documented confidence instead of padding. Use when the user says "break this", "torture test", "harden the tests", "QA pass", or before shipping risky logic (money, concurrency, migrations, parsers).
metadata:
  category: verify
---

# Torture testing

Find what breaks and who cares, instead of writing more tests. Before each attack, answer one question: which visible failure would this test catch, and for whom (the end user, the on-call engineer, the maintainer, or performance)? With no answer, do not run the attack. This beneficiary rule is a gate, not advice.

## Pick only the axes where this code can really fail

Never run every axis by default. Justify each axis you leave out in one line.

1. **Delegate mutation to the mutation-test skill.** It owns how well the test suite resists changes to the code: the operators, the agent contract and the scoring.
2. **Feed hostile inputs.** Try empty, huge, unicode, emoji or NUL, negative, a boundary plus or minus one, broken encoding, time zone, daylight saving or 29 February, locale, and injection in free-text fields.
3. **Check invariants that really exist in the domain.** Candidates: an encode then decode round trip, idempotent retries, a conserved sum (money!), a stable sort, monotonicity. Never invent one. Write the attack as a property test with the project's library (StreamData and `ExUnitProperties` in Elixir, Hypothesis in Python, fast-check in TypeScript), never as fixed examples. Make the generator reach the values the code treats specially, and check that it produces them before counting the property as passed.

   Check that the library is already in the dependencies. If it is not, do not add it; report an uncovered axis in the triage instead. For a bug found without the library, keep one killer test on its minimal repro, never a sample of examples.
4. **Repeat and overlap operations.** Try a double submit, a retry after a timeout (did the operation happen?), out-of-order events, and two workers on the same resource.
5. **Starve resources.** Multiply the load by 100 to find the performance ceiling (measure it, do not guess). Try a slow or dead dependency, a simulated full disk, and bounded memory.
6. **Interrupt state.** Try a crash between two writes, a replay of a half-done job, a partial migration, and a cache out of step with its source.

## Make each attack earn its place

- Give every torture an oracle: a checkable expectation. "It did not crash" is an oracle only for pure robustness attacks.
- Report findings before writing tests. Report a bug you find (minimal repro, impact, beneficiary hit) before you write anything. The fix is not part of this pass. Refuse a test that would lock in the doubtful behavior.
- Keep to about 10 attacks per pass at most. Make each attack and each test cite, in one line, who sees which concrete failure ("<who> sees <which wrong value or state>"), never a role alone.
- Add no padding. A torture that passes produces no test; it produces one line of documented confidence in the triage. Write no test to "lock" a behavior that is already correct.

## Run the attacks

For one module, run them directly in the session.

For a wide branch, run parallel executor agents under a contract in the style of the one mutation-test gives its agents. Each agent starts from a clean preflight (`git status --porcelain` prints nothing) and a green baseline before any attack. Each agent takes one axis, proves its revert, and never commits or pushes. Each agent reports `PASS` (torture passed, confidence documented), `ISSUES` (bug or bugs found, repro and beneficiary cited), or `BLOCKED` (preflight or baseline unusable), never a prose summary alone. When an agent drops out, continue with the others and relaunch it once; a second failure becomes an uncovered axis in the triage, never a torture passed by default.

## Write the triage for the user

The triage is the deliverable. Give it to the user as the final message, in four parts:

1. **List the bugs found**, each with its minimal repro, the beneficiary hit and its severity.
2. **List the real gaps**: the killer tests added, each with its beneficiary line and its kill check (the test fails on the broken behavior and passes on the healthy one).
3. **List the tortures passed** as documented confidence, with zero lines of code added.
4. **List the uncovered axes**: an agent that dropped out twice on a wide branch, or a property library missing from the dependencies. A named gap is never counted as a passed torture.

Record the run with `skill-record torture-test attacks=A bugs_found=B gaps_closed=G uncovered_axes=U`, once, only when the run finished; a dry run or an aborted run records nothing. Here attacks is the number of attacks run, and gaps_closed the number of killer tests added in part 2.

Sources : le contrat PASS/ISSUES/BLOCKED et la reprise sur décrochage
adaptent la skill `swarm` de pstack par poteto
(github.com/cursor/plugins/tree/main/pstack, MIT, Lauren Tan).
