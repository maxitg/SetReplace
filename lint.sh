#!/usr/bin/env bash
set -eo pipefail

setReplaceRoot=$(cd "$(dirname "$0")" && pwd)
cd "$setReplaceRoot"

lsfilesOptions=(
  --cached
  --others           # untracked files
  --exclude-standard # exclude .gitignore
  '*'
  ':(exclude)*.png'
  ':(exclude)Dependencies/*'
  ':(exclude)libSetReplace/WolframHeaders/*'
  ':(exclude)*.xcodeproj/*' # Xcode manages these automatically
)

mapfile -t filesToLint < <(LC_ALL=C comm -13 <(git ls-files --deleted) <(git ls-files "${lsfilesOptions[@]}"))

formatInPlace=0
formatOnly=0

for arg in "$@"; do
  case $arg in
  -i)
    formatInPlace=1
    shift
    ;;
  -f)
    formatOnly=1
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

for file in "${filesToLint[@]}"; do
  if [[ "$file" == *.cpp || "$file" == *.hpp || "$file" == *.h ]]; then
    cppFiles+=("$file")
  elif grep -rIl '^#![[:blank:]]*/usr/bin/env bash' "$file" >/dev/null; then
    # Some bash files don't use .sh extension, so find by shebang
    bashFiles+=("$file")
  elif [[ "$file" == *.md ]]; then
    markdownFiles+=("$file")
  else
    remainingFiles+=("$file")
  fi
done

# Formatting

red="\\\033[0;31m"
green="\\\033[0;32m"
endColor="\\\033[0m"

function formatWithCommand() {
  local command="$1"
  local file="$2"
  diff=$(diff -U0 --label "$file" "$file" --label formatted <("$command" "$file") || :)
  if [ $formatInPlace -eq 1 ]; then
    "$command" -i "$file"
  fi
  if [[ -n "$diff" ]]; then
    echo -e "$(echo -e "$diff\n\n" | sed "s|^-|$red-|g" | sed "s|^+|$green+|g" | sed "s|$|$endColor|g")"
    exitStatus=1
  fi
}

for file in "${cppFiles[@]}"; do
  formatWithCommand clang-format "$file"
done

for file in "${bashFiles[@]}"; do
  if [ $formatInPlace -eq 1 ]; then
    shfmt -w -i 2 "$file"
  else
    shfmt -l -d -i 2 "$file" || exitStatus=1
  fi
done

for file in "${remainingFiles[@]}"; do
  formatWithCommand ./scripts/whitespaceFormat.sh "$file"
done

if [ $exitStatus -eq 1 ]; then
  echo "Found formatting errors. Run ./lint.sh -i to automatically fix by applying the printed patch."
fi

if [ $formatOnly -eq 1 ]; then
  exit $exitStatus
fi

# Linting

for file in "${cppFiles[@]}"; do
  cpplint --quiet --extensions=hpp,cpp "$file" || exitStatus=1
done

for file in "${bashFiles[@]}"; do
  shellcheck "$file" || exitStatus=1
done

for file in "${markdownFiles[@]}"; do
  if [ $formatInPlace -eq 1 ]; then
    markdownlint -f "$file" || :
  else
    markdownlint "$file" || exitStatus=1
  fi
done

widthLimit=120
checkLineWidthOutput=$(
  for file in "${remainingFiles[@]}" "${bashFiles[@]}"; do
    ./scripts/checkLineWidth.sh "$file" "$widthLimit"
  done
)
if [ -n "$checkLineWidthOutput" ]; then
  exitStatus=1
  echo "Found lines exceeding the maximum allowed length of $widthLimit:"
  echo "$checkLineWidthOutput"
fi

exit $exitStatus
