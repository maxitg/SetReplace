#!/usr/bin/env bash
set -eo pipefail

setReplaceRoot=$(cd "$(dirname "$0")" && pwd)
cd "$setReplaceRoot"

sourceFiles=$(find libSetReplace -type f -name "*pp")
# Some bash files don't use .sh extension, so find by shebang
bashFiles=$(grep -rIl '^#![[:blank:]]*/usr/bin/env bash' --exclude-dir={*build*,*.git*} .)
markdownFiles=$(find . -type f -name "*.md" -not -path "*build*")

red="\\\033[0;31m"
green="\\\033[0;32m"
endColor="\\\033[0m"

formatInPlace=0

for arg in "$@"; do
  case $arg in
  -i)
    formatInPlace=1
    shift
    ;;
  *)
    echo "Argument $arg is not recognized."
    echo
    echo "Usage: ./lint.sh [-i]"
    echo "Analyze the C++ code with clang-format and cpplint."
    echo
    echo "Options:"
    echo "  -i  Inplace edit files with clang-format."
    exit 1
    ;;
  esac
done

exitStatus=0

for file in $sourceFiles; do
  diff=$(diff -U0 --label "$file" "$file" --label formatted <(clang-format "$file") || :)
  if [ $formatInPlace -eq 1 ]; then
    clang-format -i "$file"
  fi
  if [[ -n "$diff" ]]; then
    echo -e "$(echo -e "$diff\n\n" | sed "s|^-|$red-|g" | sed "s|^+|$green+|g" | sed "s|$|$endColor|g")"
    exitStatus=1
  fi
done

for file in $bashFiles; do
  if [ $formatInPlace -eq 1 ]; then
    shfmt -w -i 2 "$file"
  else
    shfmt -l -d -i 2 "$file" || exitStatus=1
  fi
done

for file in $markdownFiles; do
  if [ $formatInPlace -eq 1 ]; then
    markdownlint -f "$file"
  else
    markdownlint "$file" || exitStatus=1
  fi
done

if [ $exitStatus -eq 1 ]; then
  echo "Found formatting errors. Run ./lint.sh -i to automatically fix by applying the printed patch."
fi

for file in $sourceFiles; do
  cpplint --quiet --extensions=hpp,cpp "$file" || exitStatus=1
done

for file in $bashFiles; do
  shellcheck "$file" || exitStatus=1
done

./scripts/checkLineWidth.sh || exitStatus=1

exit $exitStatus
