---
name: verify
description: Verify documentation accuracy against actual source code. Cross-references every claim, code example, file path, and behavior description. Catches stale docs, wrong examples, and outdated instructions. Triggers on "verify docs", "check accuracy", "are these docs correct", "truth-check this page", "is this documentation still accurate".
argument-hint: "[file path]"
---

# Verify Documentation Accuracy

Cross-reference a doc page against the source code. Catch lies before readers do.

## Step 1: Read the Page

If a file path was provided, read it. Otherwise ask which doc to verify.

## Step 2: Extract Verifiable Claims

Scan the page and extract every claim that can be checked against code:

- **File paths** — Do they exist? (`lib/app/auth/permissions.ex`)
- **Code examples** — Do they match the current API/function signatures?
- **Behavior descriptions** — "When X happens, Y occurs" — does the code confirm this?
- **Configuration keys** — Do these keys exist in the actual config?
- **Default values** — Are the stated defaults correct?
- **Parameter names and types** — Do they match the source?
- **Prerequisites** — Are the stated requirements still accurate?
- **URLs and links** — Do internal doc links point to existing pages?

## Step 3: Verify Each Claim

For each extracted claim:
1. Find the source of truth in the codebase
2. Compare the doc's statement against the code
3. Mark as: **correct**, **outdated**, **wrong**, or **unverifiable**

## Step 4: Report

```markdown
# Verification Report: [page path]

**Claims checked:** [count]
**Correct:** [count] | **Outdated:** [count] | **Wrong:** [count] | **Unverifiable:** [count]

## Issues Found

### Wrong
- **Line X:** States `timeout defaults to 30s` but source shows `@default_timeout 60_000` (60s)
  - File: `lib/app/config.ex:42`

### Outdated
- **Line Y:** References `Auth.Permissions.check/2` but function was renamed to `Auth.Authorization.verify/2`
  - Renamed in: [commit or PR if findable]

### Broken Links
- **Line Z:** Links to `../setup.md` which does not exist

## Unverifiable Claims
- [Claims that reference external systems or undocumented behavior]
```

## Step 5: Fix or Flag

For each issue:
- **Wrong/outdated:** Offer to auto-fix with the correct value from source code
- **Broken links:** Offer to fix or remove
- **Unverifiable:** Flag for human review

Apply fixes on user approval.
