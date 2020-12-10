#!/usr/bin/env bash
set -eo pipefail

setReplaceRoot=$(dirname $(cd $(dirname $0) && pwd))
cd "$setReplaceRoot"

lsfilesOptions=(
  --cached
  --others                   # untracked files
  --exclude-standard         # exclude .gitignore
  '*'
  ':(exclude)*.png'
  ':(exclude)*.md'           # Markdown files do not yet follow the line width limit
  ':(exclude)*.xcodeproj/*'  # Xcode manages these automatically
  ':(exclude)*.?pp'          # Handled by clang-format
  ':(exclude)*.h'
)

filesToCheckIncludingDeleted=$(git ls-files "${lsfilesOptions[@]}")
deletedFiles=$(git ls-files --deleted)

if [ -n "$deletedFiles" ]; then
  filesToCheck=$(echo "$filesToCheckIncludingDeleted" \
                 | grep --invert-match --word-regexp --fixed-strings "$deletedFiles")
else
  filesToCheck="$filesToCheckIncludingDeleted"
fi

widthLimit=120

# If colors are printed using escape sequences, they stop working if the script is called from another script
# If the terminal is not explicitly specified, CI fails with $TERM unspecified error.
terminal=xterm-256color
bold=$(tput -T$terminal bold)
yellow=$(tput -T$terminal setaf 3)
green=$(tput -T$terminal setaf 2)
endColor=$(tput -T$terminal sgr0)

exitCode=0
for file in $filesToCheck; do
  lineWidths=($(awk '{ print length }' $file))
  for lineIndex in "${!lineWidths[@]}"; do
    lineWidth=${lineWidths[$lineIndex]}
    if (( $lineWidth > $widthLimit )); then
      oneIndexedLineIndex=$(( $lineIndex + 1 ))
      formattedFilename="${bold}$setReplaceRoot/${yellow}$file:$oneIndexedLineIndex${endColor}"
      formattedErrorMessage="${bold}: line length ${lineWidth} exceeds the maximum of $widthLimit${endColor}"
      echo "${formattedFilename}${formattedErrorMessage}"
      echo "$(sed "${oneIndexedLineIndex}q;d" $file)"
      echo "$(head -c 120 < /dev/zero | tr '\0' ' ')${green}^${endColor}"
      exitCode=1
    fi
  done
done

exit $exitCode
