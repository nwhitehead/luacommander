#!/bin/bash

set -e
set -o pipefail

echo "TESTING $1"

die()
{
    printf >&2 "FAILURE %s\n" "$@"
    exit 1
}

lua=$1
log=out/log
mkdir -p out

# Test simple evaluation
${lua} -e "print('hi')" > ${log}
echo 'hi' | cmp -b - ${log} || die "1"

# Test simple error
${lua} -e "1" > ${log} 2>&1 || true
echo "[expression]:1: unexpected symbol near '1'" \
    | cmp -b - ${log} || die "2"
${lua} -n -z "1" > ${log} 2>&1 || true
echo "[expressionEnd]:1: unexpected symbol near '1'" \
    | cmp -b - ${log} || die "3"

# Test dynamic error
${lua} -e "error(1)" > ${log} 2>&1 || true
echo "[expression]:1: 1" \
    | cmp -n 35 -b - ${log} || die "4"
${lua} -n -e "" -z "error(1)" < /dev/null > ${log} 2>&1
echo "[expressionEnd]:1: 1" \
    | cmp -n 35 -b - ${log} || die "5"

# Test inspect module correctly loaded
${lua} -e "print(inspect({}))" > ${log}
echo '{}' | cmp -b - ${log} || die "6"

# Test simple regular expression
${lua} -e "print(re.match('dead', '.*ad.*'))" > ${log}
echo 'dead' | cmp -b - ${log} || die "7"
${lua} -e "print(re.match('dead', '.*jj.*'))" > ${log}
echo 'nil' | cmp -b - ${log} || die "8"

# Test counting lines in file (end option)
echo -n -e "abc\ndef\n" | \
    ${lua} -n -e "x=(x or 0)+1" -z "print(x or 0)" > ${log}
echo '2' | cmp -b - ${log} || die "9"
echo -n -e "abc\ndef" | \
    ${lua} -n -e "x=(x or 0)+1" -z "print(x or 0)" > ${log}
echo '2' | cmp -b - ${log} || die "10"
echo -n -e "abc\n" | \
    ${lua} -n -e "x=(x or 0)+1" -z "print(x or 0)" > ${log}
echo '1' | cmp -b - ${log} || die "11"
echo -n -e "" | \
    ${lua} -n -e "x=(x or 0)+1" -z "print(x or 0)" > ${log}
echo '0' | cmp -b - ${log} || die "12"

# Test passing through stdin
cat DESIGN | \
    ${lua} -n -e "print(_)" > ${log}
cmp -b DESIGN ${log} || die "13"

# Print line if it has an "a" in it
echo -n -e 'abc\ndef\nghi\npail\n' | \
    ${lua} -n -e "if re.match(_, '.*a.*') then print(_) end" > ${log}
echo -n -e 'abc\npail\n' | cmp -b - ${log} || die "14"

# Check autosplitting with default whitespace
echo -n -e 'abc \t def  ghi\n' | \
    ${lua} -n -e "print(inspect(_F))" > ${log}
echo -n -e '{ "abc", "def", "ghi" }\n' \
    | cmp -b - ${log} || die "15"

# Check autosplitting with commas
echo -n -e 'abc,def,ghi\nn,o,j,w\n' | \
    ${lua} -n -F ',' -e "print(inspect(_F))" > ${log}
echo -n -e '{ "abc", "def", "ghi" }\n{ "n", "o", "j", "w" }\n' \
    | cmp -b - ${log} || die "16"

# Check autosplitting with tabs
echo -n -e 'abc\tdef\tghi\nn\to\tj\tw\n' | \
    ${lua} -n -F '\t' -e "print(inspect(_F))" > ${log}
echo -n -e '{ "abc", "def", "ghi" }\n{ "n", "o", "j", "w" }\n' \
    | cmp -b - ${log} || die "16"

# Application test: IP count
echo -n -e "127.0.0.1\tlocalhost\n127.0.0.1\tlocalhost\n168.192.2.100\tserver\n" | \
    ${lua} -n -F '\t' \
    -e "x = x or {}; x[_F[1]] = (x[_F[1]] or 0) + 1" \
    -z "for k, v in reversesorted(x) do print(k .. ' ' .. v) end" > ${log}
echo -n -e "127.0.0.1 2\n168.192.2.100 1\n" | \
    cmp -b - ${log} || die "17"

# Test line numbering
echo -n -e "abc\ndef\n" | \
    ${lua} -n -e "print(_ln)" > ${log}
echo -n -e "1\n2\n" | cmp -b - ${log} || die "18"

echo "runtests.sh finished successfully"
