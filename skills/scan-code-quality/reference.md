# Code Quality Scan -- Reference Catalog

This catalog provides detailed detection signals, measurable thresholds, and refactor directions for each pattern covered by the code quality scan. Organized by the seven detection categories in priority order.

---

## Part 1: Pattern Catalog

### 1. Architecture Coherence

Healthy architecture: each module owns a clear boundary; dependencies flow in one direction; a feature change stays within its boundary.

#### God Object

- **Signals**: class with >20 public methods, >15 injected dependencies, or references to 4+ distinct domains; name contains broad terms like "Manager", "System", "Engine", "Driver" without a narrow qualifier.
- **Severity**: High when in core domain; Medium when isolated to infrastructure.
- **Refactor**: extract domain-specific facades or services; delegate responsibilities so each class covers one bounded context.

```
// Before: OrderManager handles pricing, shipping, notifications, and analytics
class OrderManager:
    calculate_price(order)
    apply_discount(order, code)
    estimate_shipping(order, address)
    send_confirmation(order, email)
    track_analytics(order, event)
    generate_invoice(order)
    ...20 more methods

// After: each domain gets its own service
class PricingService:    calculate_price(order) / apply_discount(order, code)
class ShippingService:   estimate_shipping(order, address)
class NotificationService: send_confirmation(order, email)
```

#### Shotgun Surgery

- **Signals**: a single conceptual change (e.g. "add a field to User") requires edits in >5 files; the same concept (type name, field name) is scattered across unrelated modules.
- **Severity**: High for frequently changed features; Medium otherwise.
- **Refactor**: colocate related logic into a single module or use a shared data structure that propagates changes automatically.

#### Feature Envy

- **Signals**: a method accesses data from another object more than from its own class; ratio of `other.field` accesses to `self.field` accesses is >2:1.
- **Severity**: Medium in domain logic; Low in utility/adapter code.
- **Refactor**: move the method to the class whose data it primarily uses, or extract the accessed data into a shared value object.

#### Circular Dependencies

- **Signals**: module A imports module B which imports module A (directly or through a chain); build tools or import analyzers report cycles.
- **Severity**: High when it crosses architectural layers (e.g. domain depends on infrastructure which depends on domain).
- **Refactor**: introduce an interface or event at the cycle boundary; invert the dependency so both depend on an abstraction.

#### Leaky Abstraction

- **Signals**: callers need knowledge of internal implementation details to use a module correctly; error messages, config keys, or data formats from an inner layer surface in an outer layer.
- **Severity**: Medium -- couples layers and makes replacement difficult.
- **Refactor**: wrap the internal details behind a stable interface; translate inner errors into domain-specific ones.

---

### 2. Design Principle Adherence

Healthy design: each class has one reason to change (SRP); new behavior extends rather than edits existing code (OCP); subtypes are substitutable (LSP); interfaces are narrow (ISP); high-level modules depend on abstractions (DIP); logic is expressed once (DRY); code solves current needs (YAGNI); the simplest solution is preferred (KISS).

Don't stop at "this could be a bit cleaner" — look for the reframing that deletes a whole branch, helper, or layer rather than rearranging it; a finding that only tidies is weaker than one that removes.

#### SRP Violation

- **Signals**: class mixes 2+ concerns (e.g. calculation + persistence + presentation); class name contains "And" or broad suffixes ("Handler", "Manager") covering multiple domains; methods operate on different data subsets with no shared state.
- **Severity**: High when mixing I/O with business logic; Medium for calculation + formatting.
- **Refactor**: split into one class per actor/reason-to-change.

#### Liskov Substitution Break

- **Signals**: subclass throws "not implemented" or "unsupported" in an overridden method; subclass narrows preconditions or widens postconditions beyond what the base class promises.
- **Severity**: High -- can cause runtime failures when callers rely on base class contract.
- **Refactor**: redesign the hierarchy so subtypes genuinely extend behavior, or use composition instead of inheritance.

#### Interface Segregation Gap

- **Signals**: interface with >5 methods; implementations that throw or no-op for >20% of interface methods; clients importing an interface but using only 1-2 of its methods.
- **Severity**: Medium -- forces implementors to carry dead weight.
- **Refactor**: split into focused interfaces grouped by client need.

#### Dependency Inversion Miss

- **Signals**: high-level module directly instantiates concrete low-level classes (`new HttpClient()`, `new Database()`) inside business logic; no constructor-injected abstractions.
- **Severity**: High in core domain (blocks testability); Low in infrastructure glue.
- **Refactor**: inject abstractions via constructor; instantiate concretes at the composition root.

#### Duplicated Logic (DRY)

- **Signals**: near-identical code blocks in 2+ locations with minor variations; same validation pattern repeated across layers; repeated string literals or magic values.
- **Severity**: High when business logic is duplicated 3+ times; Medium for 2 occurrences.
- **Refactor**: extract shared logic into a single function or module; use constants for repeated literals.
- **AHA caveat**: duplication across only 2 sites may be acceptable if the contexts diverge -- premature abstraction can be worse than duplication.

#### Speculative Feature (YAGNI)

- **Signals**: abstract class or interface with only one implementation and no planned extension; unused parameters or configuration options; "future-proof" layers with zero current consumers.
- **Severity**: Medium when it blocks simple changes; Low when isolated.
- **Refactor**: inline the abstraction; remove unused parameters; add extension points only when a second consumer appears.

#### Unnecessary Indirection (KISS)

- **Signals**: call depth >4 for a simple operation; >2 generic type parameters for a single-use flow; configuration-heavy setup for trivial behavior; wrapper classes that add no logic.
- **Severity**: Medium when it slows debugging and onboarding; Low for shallow wrappers.
- **Refactor**: collapse indirection layers; replace generic machinery with concrete implementations when there is only one use.

---

### 3. Dead Code and Unused Artifacts

Healthy codebase: every exported symbol, file, branch, and parameter is reachable and exercised.

#### Unreferenced Exports

- **Signals**: exported function, class, or constant with zero incoming references in the call graph (excluding public API entry points and plugin interfaces).
- **Severity**: Medium for internal modules; Low for public API symbols (may have external consumers).
- **Refactor**: remove the export; if uncertain, mark as deprecated and track usage.

#### Unreachable Branches

- **Signals**: code after a guaranteed `return`, `throw`, or `exit`; conditional branches guarded by a constant false condition; `catch` blocks for exceptions that are never thrown in the try body.
- **Severity**: Medium -- dead branches mislead readers and mask real error handling.
- **Refactor**: remove the unreachable code; if it guards a genuinely possible path, add a test that exercises it.

#### Unused Parameters

- **Signals**: parameter never read in the function body; parameter always passed as the same constant value.
- **Severity**: Low for a single parameter; Medium when multiple unused parameters clutter the signature.
- **Refactor**: remove the parameter; if it is part of a shared interface, consider whether the interface needs splitting.

#### Orphan Files

- **Signals**: file not imported or referenced by any other file in the project; no entry point configuration references it.
- **Severity**: Medium for large files; Low for small utility files that may be used externally.
- **Refactor**: delete the file after confirming it has no dynamic or external consumers.

#### Commented-Out Code

- **Signals**: blocks of code inside comments; version-controlled code that should live in git history rather than inline.
- **Severity**: Low -- adds noise but rarely causes bugs.
- **Refactor**: delete the commented block; recover from version control if needed later.
- **Caveat**: distinguish from documentation examples that happen to look like code.

---

### 4. Appropriate Complexity

Healthy functions: low branching (CC ≤ 15), shallow nesting (≤ 3 levels), few parameters (≤ 4), justified indirection.

#### High Cyclomatic Complexity

- **Signals**: function with CC > 15; many `if/else/switch/catch/&&/||/ternary` decision points; compound conditions (`if (a && b || c)`).
- **Thresholds**: CC 1-10 = low risk; 11-20 = moderate, consider splitting; >20 = high risk; >50 = untestable.
- **Severity**: High when CC > 20 in production logic; Medium for CC 11-20.
- **Refactor**: Extract Method to isolate branches; Replace Conditional with Polymorphism for type-based switches; decompose compound conditions into named predicates.

#### Deep Nesting

- **Signals**: nesting depth >3 levels of control structures; arrow-shaped code (indentation grows steadily rightward).
- **Severity**: Medium -- increases cognitive load and error-proneness.
- **Refactor**: use early returns (guard clauses) to flatten nesting; extract nested blocks into named functions.

```
// Before: deep nesting
function process(items):
    if items is not empty:
        for item in items:
            if item.is_valid():
                if item.needs_update():
                    result = compute(item)
                    if result.ok:
                        save(result)

// After: guard clauses + extraction
function process(items):
    if items is empty: return
    for item in items:
        process_single(item)

function process_single(item):
    if not item.is_valid(): return
    if not item.needs_update(): return
    result = compute(item)
    if not result.ok: return
    save(result)
```

#### Long Functions

- **Signals**: function body >30 LOC of logic (excluding blank lines and comments); function mixes multiple levels of abstraction (e.g. HTTP parsing + business rules + DB writes in one body).
- **Severity**: Medium -- hard to test, hard to name, hard to reuse.
- **Refactor**: extract coherent blocks into named helper functions at a single abstraction level.

#### High Parameter Count

- **Signals**: function with >4 parameters; related parameters that always travel together (data clumps).
- **Severity**: Low for 5 params; Medium for >6.
- **Refactor**: group related parameters into a value object or configuration struct.

---

### 5. Code Clarity

Healthy code: names reveal intent; constants replace magic values; control flow reads linearly; terminology is consistent.

#### Cryptic Names

- **Signals**: single-letter variables outside loop indices; abbreviations unclear to the domain (`cust` instead of `customer`); names shorter than 4 characters for non-trivial concepts.
- **Severity**: Low -- rarely causes bugs but slows comprehension.
- **Refactor**: rename to reveal intent; use the domain vocabulary.

#### Inconsistent Terminology

- **Signals**: same concept called different names across modules (e.g. `user` / `account` / `member` for the same entity); `get` prefix used for mutating operations in some places.
- **Severity**: Medium when it causes confusion about whether terms refer to the same thing.
- **Refactor**: establish a glossary; rename consistently using the domain's ubiquitous language.

#### Magic Numbers and Strings

- **Signals**: literal numeric or string values embedded in logic without explanation; same literal repeated in multiple places.
- **Severity**: Medium when the literal controls business behavior; Low for obvious values like 0, 1, empty string.
- **Refactor**: extract to a named constant or configuration value.

```
// Before: magic values
if retry_count > 3:
    sleep(86400)

// After: named constants
MAX_RETRIES = 3
ONE_DAY_SECONDS = 86400
if retry_count > MAX_RETRIES:
    sleep(ONE_DAY_SECONDS)
```

#### Misleading Names

- **Signals**: function named `get_X` that has side effects (writes, network calls); boolean named without `is/has/can/should` prefix; class named `Service` that holds state.
- **Severity**: High when the misleading name masks critical side effects; Low for minor naming style issues.
- **Refactor**: rename to match actual behavior; separate query from command if a getter mutates.

---

### 6. State Management

Healthy state: dependencies are passed explicitly; mutable scope is as narrow as possible; side effects are visible in signatures.

#### Mutable Globals

- **Signals**: module-level or static variables that are assigned after initialization; shared state written by multiple functions across modules.
- **Severity**: High in business logic or concurrent code; Medium for convenience caches.
- **Refactor**: pass state explicitly via function parameters or constructor injection; scope the mutable variable to the narrowest possible lifetime.

#### Hidden Side Effects

- **Signals**: function returns void but modifies external state; function with no parameters whose output depends on module-level variables; method that writes to a database or sends a network request without its signature indicating it.
- **Severity**: High -- callers cannot reason about what the function does without reading its body.
- **Refactor**: make side effects visible in the return type or function name; accept dependencies as parameters.

#### Overly Broad Scope

- **Signals**: variable declared at module or class scope but used only in one function; configuration object passed through many layers when only one field is needed at each layer.
- **Severity**: Low for scope issues; Medium when broad scope enables unintended mutations.
- **Refactor**: move the variable to the narrowest scope that contains all its uses; pass only the needed fields rather than entire configuration objects.

#### Singleton with Mutable State

- **Signals**: class enforcing single instance with mutable fields; global access point (`getInstance()`) used across many modules; test setup requires resetting singleton state.
- **Severity**: High when shared across threads or core domain; Medium for infrastructure singletons.
- **Refactor**: convert to a regular class instantiated once at the composition root and injected where needed.

---

### 7. Comment and Suppression Discipline

Healthy comments: rare, and each one carries something the code cannot say for itself. Everything else is meat.

The only comments that survive review:

- License or legal headers.
- A doc comment defining a public API contract.
- A link to an issue, RFC, or spec that documents a constraint the code itself can't express.
- A surprise forced by an external dependency, platform, or protocol the codebase doesn't control — and even then, the finding should still name the symbol that could be renamed, extracted, or typed to make the surprise obvious without prose.

#### Narrating Comment

- **Signals**: comment restates what the next line already says (`# increment counter` above `count += 1`); a comment explaining "why" for a decision the code makes obvious by its own structure; a block comment where the code beneath it, read alone, needs no explanation.
- **Severity**: Low when isolated; Medium when the pattern is widespread enough to signal the codebase leans on comments instead of clear structure.
- **Refactor**: delete the comment. If the "why" is genuinely non-obvious, rename the symbol or extract a well-named function/variable instead of leaving prose beside it.

#### Unjustified Suppression Directive

- **Signals**: a lint, type-checker, or static-analysis suppression (`# noqa`, `eslint-disable`, `@ts-ignore`, `@ts-expect-error`, `# credo:disable-next-line`, `@dialyzer {:nowarn_function, ...}`) with no comment proving the underlying rule is wrong for this exact line; a suppression whose adjacent comment is a justification ("too risky to fix now", "fine for now", "IMPORTANT: do not touch") rather than a proof.
- **Severity**: High when the suppressed rule catches correctness or safety issues (type mismatches, unused return values, security lints); Medium for a suppressed style-only rule.
- **Refactor**: fix the underlying code so the check passes, or scope the rule off in project config with a stated reason if the rule itself is wrong for this codebase. Never leave a bare inline suppression as the permanent fix — flag the exact guilty symbol for the rename, extract, or type change that would make the suppression unnecessary.
- **Caveat**: a suppression survives only when the rule is provably wrong here (e.g. a documented false positive in the linter itself) or the constraint is genuinely external. A long justification with no proof is a confession, not an exception.

#### Commented-Out Code as Justification

- **Signals**: a workaround wrapped in a comment explaining why the "real" fix isn't happening (`# TODO: this is a hack because X`, `// FIXME: revert once Y ships`) that has sat unreferenced by any open ticket for multiple releases.
- **Severity**: Medium — signals a known root cause nobody is tracking.
- **Refactor**: either fix the root cause now, or replace the prose with a link to a tracked issue. A comment is not a substitute for a ticket.

---

## Part 2: Detailed Examples

Each example follows the 7-field finding template from SKILL.md.

### Example 1: Architecture -- God Object (High)

> **Category**: Architecture coherence
> **Pattern**: God object
> **Location**: `src/services/platform_service.py` :: `PlatformService`
> **Evidence**: 28 public methods across 5 domains (user management, billing, email dispatch, report generation, audit logging); 14 constructor-injected dependencies; class body is 1,100 LOC.
> **Impact**: every new feature touches this class, creating merge conflicts; test setup requires mocking 14 dependencies; onboarding developers take 2x longer to understand the service layer because all logic funnels through one entry point.
> **Refactor direction**: extract `UserService`, `BillingService`, `EmailService`, `ReportService`, and `AuditService` as separate classes; `PlatformService` becomes a thin coordinator delegating to them.
> **Severity**: High

### Example 2: Design Principles -- DRY Violation (Medium)

> **Category**: Design principle adherence
> **Pattern**: Duplicated logic (DRY)
> **Location**: `src/api/orders.py` :: `validate_order()` and `src/api/returns.py` :: `validate_return()`
> **Evidence**: both functions contain a near-identical 18-line block that checks inventory availability, applies business rules for item eligibility, and formats validation errors -- differing only in the error message prefix ("Order" vs "Return").
> **Impact**: a business rule change (e.g. new eligibility criterion) requires updating both locations and risks drift if one is missed; bug fixes must be applied twice.
> **Refactor direction**: extract shared validation into `src/domain/inventory_validator.py` :: `check_item_eligibility(items, context_label)` and call from both endpoints.
> **Severity**: Medium

### Example 3: Complexity -- High CC + Deep Nesting (Medium)

> **Category**: Appropriate complexity
> **Pattern**: High cyclomatic complexity
> **Location**: `src/engine/rule_evaluator.py` :: `evaluate()`
> **Evidence**: CC = 23; function is 85 LOC with nesting depth reaching 5 levels; contains a 12-branch switch on rule type, each branch with its own conditional guards.
> **Impact**: function is difficult to unit test (requires 23+ test paths for full branch coverage); minor edits risk breaking unrelated branches; new rule types require modifying the switch.
> **Refactor direction**: replace the switch with a strategy map (`rule_type -> handler`); extract each handler into a focused function with its own tests; flatten nesting with guard clauses.
> **Severity**: Medium

### Example 4: Counter-Signal -- Justified Pattern (Not a Finding)

This example shows a pattern that looks like a violation but is justified:

> **Observation**: `src/adapters/payment_gateway.py` contains three nearly identical functions: `charge_stripe()`, `charge_paypal()`, `charge_bank_transfer()`. Each is ~25 LOC with similar structure but different API calls, error codes, and retry policies.
>
> **Initial signal**: DRY violation -- three functions with ~70% structural similarity.
>
> **Counter-signal analysis**: each function handles a different external API with distinct error semantics, retry behavior, and timeout configuration. Abstracting these into a shared function would require a parameter object with gateway-specific fields and conditional branches for each provider's quirks -- the resulting abstraction would be more complex than the duplication.
>
> **Verdict**: acceptable duplication following the AHA principle. The three functions evolve independently as each payment provider changes its API. A shared abstraction would create coupling between providers that change for different reasons.
>
> **Action**: do not report as a finding. Document the rationale in a brief code comment if not already present.

---

## Part 3: Orchestrator Process Detail

Referenced from SKILL.md's Workflow section.

### Architecture diagram

```
orchestrator (this session)
  │  1. scope + build a shared context brief
  ├──► find phase  (parallel, model = --find-model) ───────────────┐
  │      reviewer: architecture coherence                          │
  │      reviewer: design principle adherence                      │  one subagent
  │      reviewer: dead code & unused artifacts                    │  per in-scope
  │      reviewer: appropriate complexity                          │  category
  │      reviewer: code clarity                                    │
  │      reviewer: state management                                │
  │      reviewer: comment & suppression discipline                │
  │  2. collect raw findings, assign stable ids                ◄───┘
  ├──► check phase (parallel, model = --check-model) ──────────────┐
  │      checker: re-read cited code, confirm/refute,              │  verify + rank
  │               apply counter-signals, score priority           │  every finding
  │  3. keep confirmed findings, sort by priority              ◄───┘
  └──► 4. synthesize the report
```

### Find subagent — prompt template

Fill the placeholders and dispatch with `model = --find-model`, one per category:

> You are a senior code reviewer auditing code for **ONE** quality aspect: **{CATEGORY_NAME}**. Ignore every other aspect — other reviewers cover those.
>
> Context brief: {languages, frameworks, target paths, exclusions, layering notes}
>
> Read the **{CATEGORY_NAME}** section of `{abs path to reference.md}` for the detection signals, thresholds, and refactor recipes for this aspect. Use them — don't rely on memory. Scan only the target paths.
>
> For every issue with **concrete evidence** (file path, symbol, a metric/count, or a specific construct), emit a finding. If you cannot point to evidence, do not emit it — unsubstantiated flags waste the reviewer's time. Respect the project's existing conventions; refactor directions must be non-breaking and behavior-preserving.
>
> Return **only** a JSON array (no prose), each element with these fields — this is the **find output contract**:
> `{ "category", "pattern", "location", "evidence", "impact", "refactor_direction", "severity" }`
> where `severity` ∈ `high|medium|low` per the rubric I gave you. Return `[]` if you find nothing.

### Check subagent — prompt template

Fill with the collected findings and dispatch with `model = --check-model`:

> You are an adversarial verifier and triager. For each candidate finding below, independently re-read the cited code and judge whether it is a **real** defect — do not trust the finding's own claims.
>
> Findings: {JSON array of findings, each including its `id`}
>
> For each finding decide:
> - **verdict**: `confirmed` (evidence holds and it's a genuine defect), `refuted` (evidence doesn't hold, the cited code differs, or a counter-signal applies), or `uncertain` (can't tell from the cited location). Default to `refuted` when evidence is thin and you can't substantiate it.
> - **confidence**: 0.0–1.0.
> - **adjusted_severity**: `high|medium|low` (you may overrule the reviewer's severity).
> - **priority_score**: 0–100 — rank by **severity × blast radius × fix-leverage**: how bad it is if left, how many files/consumers/paths it touches, and how much improvement a non-breaking fix buys per unit of effort. A high-severity issue confined to one dead file outranks nothing; a medium issue rippling across the hot path outranks an isolated high.
> - **rationale**: one or two sentences, citing what you saw in the code.
>
> Counter-signals that should push a finding to `refuted`: proven reuse across 3+ independent consumers; a compliance/regulatory mandate; an actively-used extension point; intentional AHA duplication (cheaper than the wrong abstraction); a suppression comment that names the specific external reason the check is wrong here, proven true today.
>
> Filtering judgment, apply before scoring: a **hypothetical** finding ("what if someone passes nil here") is only real if you can trace an actual caller that can produce that input — refute it if the type or an upstream check already rules it out. A finding that amounts to **"I would have done it differently"** with no concrete defect shown is not a finding — refute it. A suggested extraction or abstraction is **premature** if the code has only one call site and no second one is coming — refute it. If a category's findings are all nits with no high or medium among them, the code is probably fine there — say so instead of inflating a nit's severity to fill the report.
>
> Return **only** a JSON array, each element: `{ "id", "verdict", "confidence", "adjusted_severity", "priority_score", "rationale" }`.

### Severity Rubric

Both find and check subagents apply this. Pass it into their prompts.

| Level | Criteria |
| --- | --- |
| **High** | Causes or risks runtime failures, blocks testability, or forces changes across 5+ files for a single feature |
| **Medium** | Increases maintenance cost measurably: duplicated logic in 2+ places, functions with CC > 15, or classes mixing 2+ unrelated concerns |
| **Low** | Friction point that slows comprehension: unclear naming, minor style inconsistency, or single unused parameter |

### Report structure

Use this template:

```
# Code Quality Scan

**Config**: target=… · depth=… · focus=… · find-model=… · check-model=…
**Summary**: N findings confirmed (H high / M medium / L low), K refuted in verification.

## Ranked findings
<table: rank | priority | severity | category | location | pattern>

## Findings in detail
<for each confirmed finding, the 7-field template from SKILL.md, highest priority first>

## Considered but not flagged
<refuted findings + counter-signalled patterns: location, why it was dismissed>
```

A pattern that hits a counter-signal (see the check prompt template above) is `refuted`, not dropped: it still appears under "Considered but not flagged" so the reader sees it was looked at and ruled acceptable.

See Example 1 above for a worked instance of the 7-field template applied to a real finding.
