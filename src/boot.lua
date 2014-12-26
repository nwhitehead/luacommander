re=require('rex_pcre')
inspect=require('inspect')

-- Polyfill pack and unpack
table.unpack = table.unpack or unpack
table.pack = table.pack or function(...) return {...} end

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
function string.split(str, delim, opts)
    local result = {}
    for m in re.split(str, delim, opt) do
        result[#result + 1] = m
    end
    return result
end

-- Find a pattern in a string
-- Try to keep backwards compatibility option
local old_string_find = string.find
function string.find(str, pattern, index, opts)
    if opts == true or opts == false then
        return old_string_find(str, pattern, index, opts)
    end
    return re.find(str, pattern, index, opts)
end

-- Match pattern as a Lua iterator (for generic 'for' loop)
function string.gmatch(str, pattern)
    return re.gmatch(str, pattern)
end

-- Count number of occurrences of a regex
function string.count(str, pattern)
    return re.count(str, pattern)
end

function __process(f, fend, lines, irs, crs)
    if lines then
        for _ in io.lines() do
            local _F = string.split(_, crs)
            if f then
                f(_, _F)
            end
        end
        if fend then
            fend()
        end
        return
    end
    -- No lines handling
    if f then
        f()
    end
    if fend then
        fend()
    end
end
