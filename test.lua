local inspect = require('inspect')
local re = require('rex_pcre')

function string.split(str, delim, opts)
    local result = {}
    for m in re.split(str, delim, opt) do
        result[#result + 1] = m
    end
    return result
end

print(inspect(string.split('abc,def', ',')))
print(inspect(string.split('abc', '')))
print(inspect(string.split('', ',')))
print(inspect(string.split('abc', ',')))
print(inspect(string.split('a,b,c', ',')))
print(inspect(string.split('a,b,c,', ',')))
print(inspect(string.split(',a,b,c,', ',')))
print(inspect(string.split('x,,,y', ',')))
print(inspect(string.split(',,,', ',')))
print(inspect(string.split('x!yy!zzz!@', '!')))
print(inspect(string.split('hr  br p  span', '\\s+')))
print(inspect(string.split('hr  br p  span', [[\s+]])))
