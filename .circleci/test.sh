#!/bin/bash

rm -f exit_status.txt
STATUS_FILE=1 ./test.wls -e performance
[[ -f exit_status.txt && $(< exit_status.txt) == "0" ]]
