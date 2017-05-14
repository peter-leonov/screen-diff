#!/bin/sh
set -e

function check_diff {
  if [[ -n $(git status -s ./tests) ]]; then
    echo The reference diff has been changed >&2
    exit 1
  fi
}

for TEST in tests/*; do
  echo Testing $TEST...
  time -p ./screen-diff.rb $TEST/a.png $TEST/b.png $TEST/diff.png
  check_diff
  echo OK
  echo
done
