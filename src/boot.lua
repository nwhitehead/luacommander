inspect = require('inspect')

-- Remember original functions
old = {
    print=print,
    table={
        pack=table.pack,
        unpack=table.unpack,
    },
}

-- Make print use inspect for tables
function print(...)
    local n = select('#', ...)
    local args = {...}
    local prev = false
    for i=1,n do
        if prev then
            io.write('\t')
        end
        local v = args[i]
        if type(v) == 'table' then
            io.write(inspect(v))
        else
            io.write(tostring(v))
        end
        prev = true
    end
    io.write('\n')
end

-- Polyfill pack and unpack
table.unpack = table.unpack or unpack
table.pack = table.pack or function(...) return {...} end

-- Limit number of return values of function (e.g. for print)
function one(x) return x end

-- Iterate over a table following a comparison function
-- Comparison can look at keys and values of both spots
-- By default compares the keys (so iterates by ordering on keys)
function ordered(tbl, f)
    local a = {}
    for k in pairs(tbl) do
        table.insert(a, k)
    end
    if f == nil then
        -- Simple case
        table.sort(a)
    else
        function newf(kx, ky)
            return f(kx, ky, tbl[kx], tbl[ky])
        end
        table.sort(a, newf)
    end
    local i = 0
    return function ()
        i = i + 1
        if a[i] == nil then 
            return nil
        else
            return a[i], tbl[a[i]]
        end
    end
end

-- Iterate over keys in default reverse order
function reverseordered(tbl)
    return ordered(tbl, function(x, y) return y < x end)
end

-- Iterate over elements in table by ordering on value
function sorted(tbl, f)
    if f == nil then
        return ordered(tbl, function(_, _, x, y) return x < y end)
    end
    return ordered(tbl, function(_, _, x, y) return f(x, y) end)
end

-- Iterate over elements in table by reverse value order
function reversesorted(tbl)
    return ordered(tbl, function(_, _, x, y) return y < x end)
end

-- Flatten an iterator into array of values
-- Default: array of keys visited (first result of iterator function)
function array(iter, s0, i, f)
    if f == nil then f = function(k, v) return k end end
    -- Record results
    local r = {}
    -- Keep track of our own position
    local ii = 1
    while true do
        local ir = table.pack(iter(s0, i))
        i = ir[1]
        if i == nil then break end
        r[ii] = f(table.unpack(ir))
        ii = ii + 1
    end
    return r
end

-- Flatten an iterator into an actual array of keys visited
function keys(iter, s0, i)
    return array(iter, s0, i, function(k, v) return k end)
end

-- Flatten an iterator into an actual array of values visited
function values(iter, s0, i)
    return array(iter, s0, i, function(k, v) return v end)
end

-- Split a string based on a delimeter
function re.gsplit(str, delim, opts)
    local result = {}
    for m in re.split(str, delim, opt) do
        result[#result + 1] = m
    end
    return result
end
