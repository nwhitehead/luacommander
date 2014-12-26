# Lua Commander

Do you pine for the days of Perl one-liners invoked from the command line?
Enjoy the benefits of quick one-liners to process text files from the
command line using the Lua language. Lua Commander is an alternate frontend
to LuaJIT that lets you quickly get stuff done.

## Features

Some of the features:
* Scripts are executed efficiently at blazing fast speed using the LuaJIT engine
* Regular expressions come pre-installed and hooked into builtin Lua library functions
* Easily print out complicated tables using the pre-installed `inspect` function
* Run code for each line of a file, then run more code to print summary results
* Automatically splits lines into fields with a programmable field separator
* Handy iterators predefined for common tasks (order by keys, order by values)

## Examples

Here are some simple example demonstrating how to use Lua Commander.

Execute code:
```
luacmd -e "print('hello world')"
```

Print the lines in a file:
```
luacmd -n -e "print(_)" < FILE
```

Count the lines in a file:
```
luacmd -n -e "x=(x or 0)+1" -z "print(x or 0)"
```

Only print lines that start with a hash or two slashes:
```
luacmd -n -e "if(string.find(_, '(^#)|(^//)')) then print(_) end" < FILE
```

Count the number of lines that do not start with a hash:
```
luacmd -n -e "if(not string.find(_, '^#')) then x=(x or 0)+1 end" \
          -z "print(x)" < FILE
```

Print how many words on each line:
```
luacmd -n -e "print(#_F)" < FILE
```

Print second column in text file with fields separated by colons:
```
luacmd -n -F ":" -e "print(_F[2])" < FILE
```

## Usage Notes

Input is always read from standard input unless redirected from the shell.

Regular expressions are in PCRE standard syntax. Functions extended include
`string.match`, `string.gmatch`, `string.find`, `string.count`, and `string.split`.

The `-n` option means that the Lua script will be processed for each line
of input. By default lines are assumed to be separated by `\n`. For each
line of the file, the variable `_` is set to the contents of the line
and `_F` is set to an array representing the fields of the line.

The default field separator is `\s+` which means one or more whitespace
characters.
The field separator can be set to any regular expression using the `-F`
option. The input line is split based on the expression which means that
each field element does not contain the field separator characters.

The line separator can be changed with the `-I' option. The input
file is split using this regular expression. So by default each line
stored in the `_` variable does not include a newline at the end.

The `-z` option lets you provide code that will be executed after all the
lines are processed on the input. This code is always executed, even if
there are no lines of input.

The `inspect` function is included by default. This function provides
a human-readable string representation of tables.

Several table iterators are provided for convenience. The usually table iterator
`pairs` iterates through a table in arbitrary order, while `ipairs`
iterates in order through a table that has array structure (sequential numeric keys
starting from 1). The iterator `ordered` iterates through keys in the table
in order. The iterator `sorted` iterates through elements of the table sorted by
value. The iterator `reverseordered` iterates through keys in reverse order, while
`reversesorted` interates through elements from largest value to smallest value.

The function `keys` converts an iterator into an array of key
values that are visited by the iterator. The function `values` converts an iterator
into an array of values that are visited by the iterator.

When using `string.match`, be careful because on a successful match
it returns multiple values that represent the way the string matched
the pattern. If the pattern includes the choice operator `|`, the multiple
return values may start with `false` for a choice not matched. If you
want to detect whether a match occurred at all the function `string.find` should
be used because it will always return a truthy value on successful match.

