#!/usr/bin/env bash
set -eo pipefail

formatInPlace=0

for arg in "$@"; do
  case $arg in
  -i)
    formatInPlace=1
    shift
    ;;
  *)
    break
    ;;
  esac
done

if [[ $# -ne 1 || ! -f "$1" ]]; then
  echo "Usage: ./scripts/whitespaceFormat.sh [-i] filename"
  exit 1
fi

filename="$1"

formatted=$(
  expand -t 2 "$filename" |                # Tabs to spaces
    sed "s/\r$//" |                        # Use Unix-style end of lines
    sed -E "s/[[:space:]]+$//" |           # Remove trailing spaces
    awk '/./ {e = 0} /^$/ {e += 1} e <= 1' # Remove repeated empty lines
)

if [ "$formatInPlace" -eq 1 ]; then
  echo "$formatted" >"$filename"
else
  echo "$formatted"
fi
