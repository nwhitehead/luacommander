re=require('rex_pcre')
inspect=require('inspect')

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
