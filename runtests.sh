#!/bin/bash

lua=$1
log=out/log

# Test simple evaluation
${lua} -e "print('hi')" > ${log}
echo 'hi' | cmp -b - ${log}

# Test inspect module correctly loaded
${lua} -e "print(inspect({}))" > ${log}
echo '{}' | cmp -b - ${log}

# Test simpe regular expression
${lua} -e "print(re.match('dead', '.*ad.*'))" > ${log}
echo 'dead' | cmp -b - ${log}
${lua} -e "print(re.match('dead', '.*jj.*'))" > ${log}
echo 'nil' | cmp -b - ${log}

# Test counting lines in file (end option)
echo -n -e "abc\ndef\n" | \
    ${lua} -n -e "x=(x or 0)+1" -z "print(x or 0)" > ${log}
echo '2' | cmp -b - ${log}
echo -n -e "abc\ndef" | \
    ${lua} -n -e "x=(x or 0)+1" -z "print(x or 0)" > ${log}
echo '2' | cmp -b - ${log}
echo -n -e "abc\n" | \
    ${lua} -n -e "x=(x or 0)+1" -z "print(x or 0)" > ${log}
echo '1' | cmp -b - ${log}
echo -n -e "" | \
    ${lua} -n -e "x=(x or 0)+1" -z "print(x or 0)" > ${log}
echo '0' | cmp -b - ${log}

# Test passing through stdin
cat DESIGN | \
    ${lua} -n -e "print(_)" > ${log}
cmp -b DESIGN ${log}

# Print line if it has an "a" in it
echo -n -e 'abc\ndef\nghi\npail\n' | \
    ${lua} -n -e "if re.match(_, '.*a.*') then print(_) end" > ${log}
echo -n -e 'abc\npail\n' | cmp -b - ${log}
