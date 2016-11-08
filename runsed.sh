#!/bin/sh
BASE="`dirname $0`/.."

compile () {
    sed -E -e '
    s:\s*$::
    s:^//:#:
    s:^([a-z0-9._]+),\s([a-z0-9._]+)$:s/(pattern|tileset) = "\1"/\\1 = "\2"/:
    s:^([a-z0-9._]+)$:/"\1"/d:
    '   
}
SCRIPT="
:loop
/}/b done
N
s/\n//
b loop
/^$/d
:done
`compile < "$BASE/diff_delete"`
`compile < "$BASE/diff_replace"`
s/,/,\n/g
s/\{/{\n/g
s/\}/}\n/g
/^$/D
"
find "$BASE/data/maps" -name '*.dat' -exec echo {} \; -exec sed -i -E "$SCRIPT" {} \;