require('boot')

local config = require('config')

function version(long)
    local v = config.version
    if long then
        local line = string.rep('=', 60)
        return table.concat({
            line,
            string.format('LuaCommander-v%s.%s.%s',
            v.major, v.minor, v.patch) ..
            string.format('\t\t[git: %s-%s]', v.branch, v.commit),
            string.format('%s', v.copyright),
            line,
        }, '\n')
    end
    return string.format('v%s.%s.%s', v[1], v[2], v[3])
end

-- Check if string starts with another string (no patterns)
local function startswith(s, x)
    return s:sub(1, #x) == x
end

-- Remove prefix string if present
local function lchomp(s, prefix)
    if startswith(s, prefix) then
        return s:sub(#prefix + 1, -1)
    end
    return s
end

-- Report errors from protected calls
local function report(result, err)
    if not status and err ~= nil then
        error(err)
    end
end

-- Check if file exists
local function fileExists(name)
    local f = io.open(name, 'r')
    if f ~= nil then
        io.close(f)
        return true
    end
    return false
end

-- Iterator that generates backup filenames
-- Suffix should include %n for numbering
-- Suffix may include %- for optional dashes (removed for n=0)
-- Iterator returns (number, filename)
local function backupNames(file, suffix)
    function f(_, n)
        local suffixR = suffix
        if n > 1000 then return end
        if n > 0 then
            suffixR = suffixR:gsub('%%n', tostring(n))
            suffixR = suffixR:gsub('%%%-', '-')
        else
            suffixR = suffixR:gsub('%%n', '')
            suffixR = suffixR:gsub('%%%-', '')
        end
        return n + 1, file .. suffixR
    end
    return f, nil, 0
end

-- Main processing function
-- f is -e user function
-- lines is boolean, should we run on every line of stdin?
-- irs is input record separator (newline by default)
-- crs is column record separator (any amount of whitespace by default)
local function __process(f, lines, printit, irs, crs)
    irs = irs or [[\n]]
    crs = crs or [[\s+]]
    _IRS = irs
    _CRS = crs
    if lines then
        local _ln = 1
        if irs == [[\n]] then
            -- IRS is newline, can use lines()
            for _ in io.lines() do
                local _F = re.gsplit(_, crs)
                if f then f(_, _F, _ln) end
                if printit then print(_) end
                _ln = _ln + 1
            end
        else
            -- IRS is not newline, read all file then split
            local data = io.read('*a')
            for k, _ in pairs(re.gsplit(data, irs)) do
                local _F = re.gsplit(_, crs)
                if f then f(_, _F, _ln) end
                if printit then print(_) end
                _ln = _ln + 1
            end
        end
        _ln = _ln - 1 -- update to number of lines read
        return _ln
    end
    -- No lines handling
    if f then f() end
    return nil
end

-- End of input processing function
local function __processEnd(fEnd, _ln)
    if fEnd then
        fEnd(_ln)
    end
end

local function main(args)
    local lines = false
    local printit = false
    local overwrite = false
    local backupSuffix = '.bak%-%n'
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
            else if v == '-i' then
                overwrite = true
            else if v == '-v' or v == '--v' or v == '-version' or v == '--version' then
                print(version(true))
                return
            else
                if v:sub(1,1) == '-' then
                    error('Unknown option ' .. v)
                end
                files[#files + 1] = v
                allowFlags = false
            end
        end end end end end end end else
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
        if overwrite then
            error('Cannot overwrite standard input')
        end
        local _ln = __process(exprF, lines, printit, irs, crs)
        __processEnd(exprEndF, _ln)
    else
        local _ln = 0
        for _, file in ipairs(files) do
            if overwrite then
                -- Read contents of file
                local fin = io.open(file, 'r')
                local data = fin:read('*a')
                fin:close()
                -- Save backup
                local foutname = nil
                for _, testname in backupNames(file, backupSuffix) do
                    if not fileExists(testname) then
                        foutname = testname
                        break
                    end
                end
                if not foutname then
                    error('Could not find unused name for backup file ' .. file)
                end
                local fout = io.open(foutname, 'w')
                fout:write(data)
                fout:close()
                -- Setup default intput and output
                io.input(io.open(foutname, 'r'))
                io.output(io.open(file, 'w'))
            else
                io.input(file)
            end
            _ln = __process(exprF, lines, printit, irs, crs)
            io.input():close()
            io.output():close()
        end
        io.input(io.stdin)
        io.output(io.stdout)
        __processEnd(exprEndF, _ln)
    end
end

local function errorHandler(err)
    if err then
        -- Try to simplify message to not include compiler file
        err = lchomp(err, [[[string "luacmd"]:0: ]])
    end
    io.stderr:write(err .. '\n')
    -- No stacktrace
end

xpcall(function() main(arg) end, errorHandler)
