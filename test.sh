#!/bin/sh
set -e

time ./screen-diff.rb tests/same_height/a.png tests/same_height/b.png tests/same_height/diff.png
time ./screen-diff.rb tests/example/a.png tests/example/b.png tests/example/diff.png
time ./screen-diff.rb tests/bigger/a.png tests/bigger/b.png tests/bigger/diff.png
