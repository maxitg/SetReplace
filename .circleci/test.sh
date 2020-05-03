#!/bin/bash

rm -f exit_status.txt
STATUS_FILE=1 ./test.wls
if [[ -f exit_status.txt && $(< exit_status.txt) == "0" ]]; then
  true
else
  false
fi
