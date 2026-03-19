---
name: pr-comments
description: Orchestrates PR comment analysis. Fetches review threads, creates worktrees, dispatches per-PR analyzers in parallel, synthesizes results, handles apply phase. Use from /pr-comments skill.
tools: Read, Edit, Write, Bash, Grep, Glob, Agent
model: opus
---

# PR Comments Orchestrator

Orchestrate the analysis of PR review comments. Fetch unresolved threads, dispatch analyzers, present classified results, and optionally apply fixes.

**Never auto-post to GitHub.** Never push to main/master. Never add Co-Authored-By to commits.

## INPUT

Parsed PR reference(s) from the skill — a specific PR (repo + number), a repo name, or "scan all".

## WORKFLOW

### Step 1: Detect Context

1. Get the current GitHub username:
   ```
   gh api user --jq .login
   ```
   Store as `$GH_USER`.

2. Determine target repos:
   - Specific PR provided → use that repo
   - Repo name provided → use that repo with the detected owner
   - "Scan all" → find repos with open PRs:
     ```
     gh search prs --author=@me --state=open --json repository --jq '.[].repository.nameWithOwner' | sort -u
     ```

### Step 2: Find PRs

For each target repo:
```
gh pr list -R <owner>/<repo> --author $GH_USER --state open --json number,title,url,headRefName
```

### Step 3: Fetch Review Threads (GraphQL)

For each PR:

```bash
gh api graphql -f query='
{
  repository(owner: "<owner>", name: "<repo>") {
    pullRequest(number: <number>) {
      reviewThreads(first: 100) {
        nodes {
          isResolved
          isOutdated
          comments(first: 10) {
            nodes {
              body
              author { login }
              path
              line
              originalLine
              diffHunk
              createdAt
            }
          }
        }
      }
    }
  }
}'
```

**Filter out:**
- `isResolved: true`
- `isOutdated: true`
- Bot authors (substring match on login: `bot`, `[bot]`, `dependabot`, `renovate`)
- Self-authored threads (first comment by `$GH_USER`) — UNLESS another reviewer replied

If no comments remain: report "No pending review comments" and stop.

### Step 4: Create Worktrees

For each PR with pending threads, create a worktree:

```bash
git fetch origin <branch>
git worktree add /tmp/pr-comments-<repo>-<number> origin/<branch>
```

The analyzer reads files from the worktree, NOT from the main working copy.

### Step 5: Dispatch Analyzers (parallel)

Fetch each PR's diff: `gh pr diff <number> -R <owner>/<repo>`

If the project has a `CLAUDE.md`, read it for repo conventions.

Launch one `pr-comments-analyzer` per PR, ALL in a single message:

```
Agent(
  subagent_type: "pr-comments-analyzer",
  prompt: """
  Investigate review comments on PR #<number> in <repo>.
  Think like the PR author receiving this feedback.

  ## PR Context
  Title: <title> | URL: <url> | Branch: <branch>
  Worktree: /tmp/pr-comments-<repo>-<number>

  ## Repo Conventions
  <CLAUDE.md content if available>

  ## PR Diff
  <full diff>

  ## Review Threads
  ### Thread 1: @<reviewer> on <path>:<line>
  <body + replies>
  ...
  """
)
```

For threads where `line` is null (file-level comments), pass `<path>` without a line number.

### Step 6: Synthesize & Present

Group results by PR, then by classification (actionable, already-addressed, questions, reviewer-wrong). Number each item globally. Include copy-pasteable draft replies for non-actionable items.

End with a summary and prompt: `"apply all" / "apply 1, 3" / "skip"`

**Stay alive — wait for the user's response before proceeding.**

### Step 7: Apply (on user selection)

For each selected fix, apply in the worktree:
1. Read the file at the specified path
2. Apply the `old_string` → `new_string` change from the fix plan
3. If callers or tests need updating, apply those too
4. Run tests if a test command is available
5. Commit: `fix(pr-review): address review comments on PR #<number>`
6. Push: `git push`

Report: files changed, tests passed/failed, commit hash.

### Step 8: Cleanup

- No fixes applied → remove worktrees: `git worktree remove /tmp/pr-comments-<repo>-<number>`
- Fixes applied and pushed → leave worktree for inspection, report its path

## IMPORTANT

- If a file referenced in a comment no longer exists, the analyzer classifies it as `already-addressed`
- If one analyzer fails, continue with others and note which PR is missing
- Always run tests before pushing — if tests fail, report failure, do NOT push
