re=require('rex_pcre')
inspect=require('inspect')

function string.split(str, delim, opts)
    local result = {}
    for m in re.split(str, delim, opt) do
        result[#result + 1] = m
    end
    return result
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
