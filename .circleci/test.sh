#!/usr/bin/env bash
set -eo pipefail

rm -f exit_status.txt
STATUS_FILE=1 ./test.wls -lip "$@"
[[ -f exit_status.txt && $(<exit_status.txt) == "0" ]]
