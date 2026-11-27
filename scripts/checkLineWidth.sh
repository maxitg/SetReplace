#!/usr/bin/env bash
set -eo pipefail

if [[ $# -ne 2 || ! -f $1 || ! $2 =~ ^[0-9]+$ ]]; then
  echo "Usage: ./scripts/checkLineWidth.sh filename widthLimit"
  exit 1
fi

filename="$1"
widthLimit="$2"

longLines=$(grep --line-number --extended-regexp ".{$((widthLimit + 1))}" "${filename}" | cut -d: -f1 || :)

if [[ -n ${longLines} ]]; then
  for line in ${longLines}; do
    echo "${filename}:${line}: Line is longer than ${widthLimit} characters"
  done
  exit 1
fi
