# Install

1. Copy this folder to `~/.claude/skills/stacked-prs`.
2. Install the `gh stack` extension and check it:

   ```sh
   gh extension install github/gh-stack
   gh stack --help
   ```

3. Smoke test the size check from any git repository that has two branches:

   ```sh
   ~/.claude/skills/stacked-prs/scripts/layer-sizes.sh main <branch>
   ```

   It prints one row per layer and exits 1 when a layer passes 500 changed lines.

4. Optional, for fewer restack conflicts: install [mergiraf](https://mergiraf.org/) and register it as git's merge driver for every language it knows.

   ```sh
   brew install mergiraf
   git config --global merge.mergiraf.name mergiraf
   git config --global merge.mergiraf.driver 'mergiraf merge --git %O %A %B -s %S -x %X -y %Y -p %P -l %L'
   mergiraf languages --gitattributes >> ~/.config/git/attributes
   git config --global rebase.updateRefs true
   ```
