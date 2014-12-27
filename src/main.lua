require('boot')

-- Check if string starts with another string (no patterns)
function startswith(s, x)
    return s:sub(1, #x) == x
end

function lchomp(s, prefix)
    if startswith(s, prefix) then
        return s:sub(#prefix + 1, -1)
    end
    return s
end

function report(result, err)
    if not status and err ~= nil then
        error(err)
    end
end

function main(args)
    local lines = false
    local printit = false
    local irs = nil
    local crs = nil
    local expr = nil
    local exprEnd = nil
    local i = 1
    while i <= #args do
        v = args[i]
        i = i + 1
        if v == '-e' then
            expr = args[i]
            i = i + 1
        else if v == '-z' then
            exprEnd = args[i]
            i = i + 1
        else if v == '-n' then
            lines = true
        else if v == '-p' then
            printit = true
        else if v == '-F' then
            crs = args[i]
            i = i + 1
        else if v == '-I' then
            irs = args[i]
            i = i + 1
        else
            error('Unknown option ' .. v)
        end end end end end end
    end
    local exprF
    if expr then
        exprF, err = loadstring(string.format('return function(_, _F) %s end', expr), '=[expression]')
        report(exprF, err)
        exprF = exprF()
    end
    local exprEndF
    if exprEnd then
        exprEndF, err = loadstring(string.format('return function() %s end', exprEnd), '=[expressionEnd]')
        report(exprF, err)
        exprEndF = exprEndF()
    end
    if not exprF and not exprEndF then
        error('No expression to evaluate')
    end
    __process(exprF, exprEndF, lines, printit, irs, crs)
end

function errorHandler(err)
    if err then
        -- Try to simplify message to not include compiler file
        err = lchomp(err, [[[string "luacmd"]:0: ]])
    end
    print(err)
    -- No stacktrace
end

xpcall(function() main(arg) end, errorHandler)
