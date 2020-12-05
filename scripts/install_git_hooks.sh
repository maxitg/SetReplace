#!/bin/bash
# Adapted from https://stackoverflow.com/a/3464399

hookNames="pre-push pre-commit"
repoRoot=$(git rev-parse --show-toplevel)
hookDir=$repoRoot/.git/hooks

for hook in $hookNames
do
  # If the hook already exists and is not a symlink, move it out of the way
  if [[ -e $hookDir/$hook && ! -h $hookDir/$hook ]]
  then
    echo "Moving an existing hook $hookDir/$hook to $hookDir/$hook.local"
    mv $hookDir/$hook $hookDir/$hook.local
  fi
  # create the symlink, overwriting the file if it exists
  echo "Symlinking $repoRoot/scripts/git_hooks/$hook to $hookDir/$hook"
  ln -s -f $repoRoot/scripts/git_hooks/$hook $hookDir/$hook
done
