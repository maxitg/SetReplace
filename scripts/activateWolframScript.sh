#!/usr/bin/env bash

# Activation is flaky, try up to 3 times.
n=0
until [[ ${n} -ge 3 ]]; do
  ((n++))
  echo "Attempt ${n}..."

  # Run the activation
  if wolframscript -authenticate "${WOLFRAM_ID}" "${WOLFRAM_PASSWORD}" && wolframscript -activate; then
    echo "Activation succeeded on attempt ${n}."
    break
  fi

  echo "Activation failed on attempt ${n}. Retrying..."
  sleep 5
done

# If after the loop it's still not activated, fail the build
if [[ ${n} -eq 3 ]]; then
  echo "Activation failed after 3 attempts."
  exit 1
fi
