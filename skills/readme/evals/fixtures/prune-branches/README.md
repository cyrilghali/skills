# prune-branches

prune-branches is a script for cleaning up your git branches. It is a handy utility that finds branches that have been merged and removes them, keeping your repository tidy and organized.

Run it with `./prune-branches.sh`. By default it only shows what it would delete (dry run). Pass `--delete` to actually delete. Pass `--base=develop` if your base branch isn't `main`.

IMPORTANT: it compares against your LOCAL base branch. If you haven't pulled, your local `main` is behind and branches merged on the remote won't show up, so update your local base branch from the remote first. It never touches remote branches, and it never deletes the branch you are on or the base branch. Deletion uses `git branch -d`, so git refuses to delete a branch it doesn't consider merged.
