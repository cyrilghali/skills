---
name: pr-comments
description: "Fetch and investigate GitHub review comments on your open PRs. Classifies each comment, fact-checks reviewer claims, and proposes fixes with evidence. Usage: /pr-comments [pr-url-or-number]. Triggers on 'review comments', 'check PR feedback', 'what did reviewers say', 'address review', 'PR comments'."
disable-model-invocation: true
argument-hint: "[pr-url-or-number]"
---

# PR Comments

Dispatch the pr-comments orchestrator to classify, fact-check, and propose fixes for review comments on your open PRs.

## Step 0: Detect User and Repos

1. Detect the current GitHub username:
   ```
   gh api user --jq .login
   ```
2. Detect repos by checking the current git remote or asking the user:
   ```
   git remote get-url origin
   ```

## Step 1: Parse `$ARGUMENTS`

Accepted formats:
- Full URL: `https://github.com/<owner>/<repo>/pull/<number>` → extract owner, repo, number
- repo#number: `<repo>#<number>` → infer owner from detected remote
- Bare number: `<number>` → use the current repo
- Repo name: `<repo>` → list open PRs for that repo by current user
- Empty: scan PRs for the current repo

## Step 2: Dispatch Orchestrator

```
Agent(
  subagent_type: "pr-comments",
  prompt: "Investigate review comments on [parsed PR info]."
)
```

## Step 3: Display Results and Handle Apply Requests

The orchestrator stays alive — it presents results, waits for user selection ("apply all" / "apply 1, 3" / "skip"), and handles the apply phase itself.

**Done when:** All review comments are classified, fixes proposed, and user has applied or skipped.
