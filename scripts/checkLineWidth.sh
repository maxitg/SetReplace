#!/usr/bin/env bash
set -eo pipefail

if [[ $# -ne 2 || ! -f "$1" || ! "$2" =~ ^[0-9]+$ ]]; then
  echo "Usage: ./scripts/checkLineWidth.sh filename widthLimit"
  exit 1
fi

filename="$1"
widthLimit="$2"

grepOutput=$(grep --line-number --color=never --extended-regexp ".{$((widthLimit + 1))}" "$filename" || :)

if [ -n "$grepOutput" ]; then
  filename="$filename"
  echo "$grepOutput" | awk -v filename="$filename" '{print filename ":" $0}'
  exit 1
fi
