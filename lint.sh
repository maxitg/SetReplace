#!/usr/bin/env bash
set -eo pipefail

# Runs formatters and linters using Trunk (https://docs.trunk.io/code-quality), which is downloaded on the first run.
# By default, only checks files changed relative to master. Arguments are passed to `trunk check`, for example:
#   ./lint.sh --all             check all files
#   ./lint.sh --fix             apply all fixes without asking
#   ./lint.sh path/to/file      check a specific file

setReplaceRoot=$(cd "$(dirname "$0")" && pwd)
exec "${setReplaceRoot}"/trunk check "$@"
