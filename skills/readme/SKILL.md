---
name: readme
description: Writes or rewrites the README of a project that already runs, as a front page, in this order - the question the project answers, real output captured by running it, then install, usage, reference folded into a details block, concepts, limits and development - with question headings, and with every link, anchor and number checked. Use when asked to "write a README", "rewrite the README", "the README is slop", "make the README readable", "fancy README", or "show example output in the README".
metadata:
  category: write
---

# Writing a README

Treat the README as a front page. Most readers decide on the first screen whether the project answers their question, so put the question and real output on that screen. Keep the reference material in the file, folded, below it.

## Read the project first

Read the current README, the `--help` output or the public API, the entry points, and the build and test commands. Done when you can write the question the project answers for its user in one sentence, and you hold a list of every fact the old README states.

## Size the job before you write

Keep a README that already opens on what the project does and on real output: fix only a wrong fact, a dead link or a missing flag, and say why in the reply. Give a small project (one command, a few flags) a short README: the opening, one example, at most two headings. Done when you have named the size: keep, short, or full front page.

## Capture real output by running the project

Run the project on an input the README's readers can reproduce. For a public README, use a public repository, a bundled sample file or a scratch directory you set up. For an internal README, use anything the team can run.

When the README is or will be public, confirm each input is public before you use it. For a GitHub repository, run `gh repo view OWNER/REPO --json visibility`; a repository on this machine is not public until that says so. Apply the same check to everything the old README names. Keep company names, private repositories and customer data out of a public README, and replace such examples with public ones. An internal README keeps the names its readers need.

Pick an input large enough that the output shows a contrast worth reading. Save each run's exact output to a scratch file. If the project cannot run here (missing credentials, hardware), show its `--help` or a test's output instead, and say in the reply that the main example is still to capture. Done when every example block you plan to show has a captured file behind it, and every behaviour you describe (an error message, an exit code) was observed in a run.

## Write in front-page order

For a full front page, follow the table below and drop any row the project lacks. Make every heading a question a reader asks ("How do I install it?", "What does it get wrong?"); the table's section names are not headings. Keep a section only when it says something the rest of the README does not: drop a flag table that repeats the usage block, or a development section with no test command. Make every command run as written, with no placeholder such as `<this repo>` and no invented download URL. Define each term of art (a tool name, a technique, a metric) in one sentence where it first appears.

Trim a long output block with a visible note naming every row or line that was cut, then say in two or three sentences what the output shows, using its own numbers. Done when the first screen holds the question, one short paragraph on what the project does, and the start of the real output.

| Section | Holds | Size |
|---|---|---|
| Title and badges | Name; badges only for true, checkable facts (language version, license, "no dependencies") | one line of badges at most |
| The question | One bold sentence: what the reader wants to know or do | one sentence |
| What it is | What it does, what it reads, what it never touches | two or three sentences |
| What does the output look like? | Captured output, trimmed, then what it shows | the main example plus one variant at most |
| How do I install it? | Requirements, then the install commands; how long a first run takes when it is slow | one code block |
| How do I use it? | Three to six commands, one line each, with a short comment | one code block |
| All flags / options | The full reference table, inside `<details><summary>` when it has more rows than the usage block has lines | folded when long, inline when short |
| Concepts | One table per group of terms, each defined in one sentence | tables |
| Scripts and agents | JSON output, exit codes, stderr behaviour, when the tool supports them | a short list and one sample |
| Limits | What the project gets wrong or misses, stated plainly | bullets |
| Development | Test command, then one table row per main file | one block and one table |

## Keep every fact from the old README

Check the new draft against the fact list from the first step. Done when each old fact is in the new README, or you dropped it because it is wrong or stale and you say which in the reply.

## Check links, flags, headings and numbers

Save the project's `--help` to a file when it has one, then run `python3 scripts/check_readme.py README.md help.txt` from this skill's folder, with the paths adjusted. The script checks every link and anchor, that every flag in `--help` appears in the README, and that every section heading is a question. For a README you kept in the sizing step, ignore heading failures and fix only the others. Then match every number in the prose to a line of the captured output. Done when the script reports no failures (for a kept README, none other than heading failures) and every number traces to a capture.

## Run the voice pass

Run the host's prose-register and anti-slop skills over the prose, if they are installed. Done when both passes return nothing, or the reply names the skill that was missing.

## Deliver the way the repository takes changes

Open a draft pull request when the repository uses them, otherwise commit. Done when the reply gives the link, the commands that produced each example, and any fact dropped in the keep-every-fact step.

## Compare the first screen before and after

Before:

> [badges]
>
> ## Installation
> ```
> npm install pingcheck
> ```

After:

> **Is this URL up, and how slow is it?**
>
> `pingcheck` fetches a URL and reports its status and response time.
>
> ```
> $ pingcheck https://example.org
> 200 OK in 112 ms
> ```

## Run the evals when you change this skill

`evals/cases.md` holds seven cases with fixtures under `evals/fixtures/`; `evals/rubric.md` holds the 0-2 scoring.
