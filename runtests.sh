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

# Check autosplitting with default whitespace
echo -n -e 'abc \t def  ghi\n' | \
    ${lua} -n -e "print(inspect(_F))" > ${log}
echo -n -e '{ "abc", "def", "ghi" }\n' | cmp -b - ${log}

# Check autosplitting with commas
echo -n -e 'abc,def,ghi\nn,o,j,w\n' | \
    ${lua} -n -F ',' -e "print(inspect(_F))" > ${log}
echo -n -e '{ "abc", "def", "ghi" }\n{ "n", "o", "j", "w" }\n' | cmp -b - ${log}

# Check autosplitting with tabs
echo -n -e 'abc\tdef\tghi\nn\to\tj\tw\n' | \
    ${lua} -n -F '\t' -e "print(inspect(_F))" > ${log}
echo -n -e '{ "abc", "def", "ghi" }\n{ "n", "o", "j", "w" }\n' | cmp -b - ${log}
