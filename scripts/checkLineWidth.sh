#!/usr/bin/env bash
set -eo pipefail

setReplaceRoot=$(dirname "$(cd "$(dirname "$0")" && pwd)")
cd "$setReplaceRoot"

lsfilesOptions=(
  --cached
  --others           # untracked files
  --exclude-standard # exclude .gitignore
  '*'
  ':(exclude)*.png'
  ':(exclude)*.md'          # Markdown files do not yet follow the line width limit
  ':(exclude)*.xcodeproj/*' # Xcode manages these automatically
  ':(exclude)*.?pp'         # Handled by clang-format
  ':(exclude)*.h'
)

mapfile -t filesToCheck < <(LC_ALL=C comm -13 <(git ls-files --deleted) <(git ls-files "${lsfilesOptions[@]}"))

widthLimit=120

grepOutput=$(grep --line-number --color=never --extended-regexp ".{$((widthLimit + 1))}" "${filesToCheck[@]}")

if [ -n "$grepOutput" ]; then
  echo "Found lines exceeding the maximum allowed length of ${widthLimit}:"
  echo "$grepOutput"
  exit 1
fi
