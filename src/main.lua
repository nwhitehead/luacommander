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

-- Main processing function
-- f is -e user function
-- fend is -z end function
-- lines is boolean, should we run on every line of stdin?
-- irs is input record separator (newline by default)
-- crs is column record separator (any amount of whitespace by default)
function __process(f, fend, lines, printit, irs, crs)
    irs = irs or [[\n]]
    crs = crs or [[\s+]]
    _IRS = irs
    _CRS = crs
    if lines then
        local _ln = 1
        if irs == [[\n]] then
            -- IRS is newline, can use lines()
            for _ in io.lines() do
                local _F = string.split(_, crs)
                if f then f(_, _F, _ln) end
                if printit then print(_) end
                _ln = _ln + 1
            end
        else
            -- IRS is not newline, read all file then split
            local data = io.read('*a')
            for k, _ in pairs(string.split(data, irs)) do
                local _F = string.split(_, crs)
                if f then f(_, _F, _ln) end
                if printit then print(_) end
                _ln = _ln + 1
            end
        end
        _ln = _ln - 1 -- update to number of lines read
        if fend then fend(_ln) end
        return
    end
    -- No lines handling
    if f then f() end
    if fend then fend() end
end

function main(args)
    local lines = false
    local printit = false
    local irs = nil
    local crs = nil
    local expr = nil
    local exprEnd = nil
    local allowFlags = true
    local files = {}
    local i = 1
    while i <= #args do
        v = args[i]
        i = i + 1
        if allowFlags then
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
                if v:sub(1,1) == '-' then
                    error('Unknown option ' .. v)
                end
                files[#files + 1] = v
                allowFlags = false
            end
        end end end end end else
            if v:sub(1,1) == '-' then
                error('No more options allowed after filename (' .. v .. ')')
            end
            files[#files + 1] = v
        end
    end
    local exprF
    if expr then
        exprF, err = loadstring(string.format('return function(_, _F, _ln) %s end', expr), '=[expression]')
        report(exprF, err)
        exprF = exprF()
    end
    local exprEndF
    if exprEnd then
        exprEndF, err = loadstring(string.format('return function(_ln) %s end', exprEnd), '=[expressionEnd]')
        report(exprF, err)
        exprEndF = exprEndF()
    end
    if not exprF and not exprEndF then
        error('No expression to evaluate')
    end
    if #files == 0 then
        __process(exprF, exprEndF, lines, printit, irs, crs)
    else
        for _, file in ipairs(files) do
            io.input(file)
            __process(exprF, exprEndF, lines, printit, irs, crs)
        end
    end
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
