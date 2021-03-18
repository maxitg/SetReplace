#!/usr/bin/env bash
set -eo pipefail

if [ $CIRCLE_NODE_INDEX -eq 2 ]
then
  testsToRun=matching
elif [ $CIRCLE_NODE_INDEX -eq 3 ]
then
  testsToRun=WolframModel
else
  testsToRun=$(circleci tests glob "Tests/*.wlt" \
  | sed "/Tests\/performance.wlt/d" \
  | sed "/Tests\/matching.wlt/d" \
  | sed "/Tests\/WolframModel.wlt/d" \
  | circleci tests split --total=2 --split-by=filesize \
  | sed "s/\.wlt//" \
  | sed "s/Tests\///")
fi

rm -f exit_status.txt
STATUS_FILE=1 ./test.wls -lip "$testsToRun"
[[ -f exit_status.txt && $(<exit_status.txt) == "0" ]]
