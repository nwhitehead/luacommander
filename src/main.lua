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

-- getopt, POSIX style command line argument parser
-- param arg contains the command line arguments in a standard table.
-- param options is a string with the letters that expect string values.
-- returns a table where associated keys are true, nil, or a string value.
-- The following example styles are supported
--   -a one  ==> opts["a"]=="one"
--   -bone   ==> opts["b"]=="one"
--   -c      ==> opts["c"]==true
--   --c=one ==> opts["c"]=="one"
--   -cdaone ==> opts["c"]==true opts["d"]==true opts["a"]=="one"
-- note POSIX demands the parser ends at the first non option
--      this behavior isn't implemented.

local function getopt(arg, options)
    local tab = {}
    local files = {}
    local k = 1
    while k <= #arg do
        local v = arg[k]
        if string.sub(v, 1, 2) == "--" then
            local x = string.find(v, "=", 1, true)
            if x then
                tab[string.sub(v, 3, x-1)] = string.sub(v, x+1)
            else
                tab[string.sub(v, 3)] = true
            end
        elseif string.sub(v, 1, 1) == "-" then
            local y = 2
            local l = string.len(v)
            local jopt
            while (y <= l) do
                jopt = string.sub(v, y, y)
                if string.find(options, jopt, 1, true) then
                    if y < l then
                        tab[jopt] = string.sub(v, y+1)
                        y = l
                    else
                        tab[jopt] = arg[k + 1]
                        k = k + 1
                    end
                else
                    tab[jopt] = true
                end
                y = y + 1
            end
        else
            files[#files + 1] = v
        end
        k = k + 1
    end
    return tab, files
end

local function usage()
    print([[
LuaCommander evaluates Lua expressions.

Usage
    luacmd [OPTIONS...] [FILES...]

Options
    -e EXPR         Evaluate EXPR
    -z EXPR         Evaluate EXPR after everything else
    -n              Evaluate once per line
    -p              Automatically print each line read
    -i              Operate in-place over files (keeping backups)
    -F REGEX        Set field separator (default: \s+)
    -I REGEX        Set line separator (default: \n)
    -v, --version   Show version info
    -h, --help      Show help

Modules and Functions
    print           Extended to display tables in human-readable form
    inspect         Convert tables into human-readable strings
    one             Returns first argument only
    ordered         Iterate through keys of table in order
    sorted          Iterate through values of table in order
    reverseordered  Iterate through keys in reverse order
    reversesorted   Iterate through values in reverse order
    keys            Convert iterator to array of keys
    values          Convert iterator to array of values
    re              Regular expression library (PCRE syntax)
    re.find         Search for regex, return first location
    re.match        Search for regex, return captures for first match
    re.gmatch       Iterate through all matches, return captures
    re.gsub         Replace pattern everywhere
    re.count        Count how many matches
    re.split        Iterate through all parts split by regex
    re.gsplit       Return array of split parts

Variables
    _       Current line (string)
    _F      Fields of current line (array of strings)
    _ln     Current line number (number)
    _IRS    Line separator regex (string)
    _CRS    Field separator regex (string)
]])
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
    local opt, files = getopt(args,
        'ezFI'
    )
    if opt.v or opt.version then
        print(version(true))
        return
    end
    if opt.h or opt.help then
        usage()
        return
    end
    expr = opt.e or expr
    exprEnd = opt.z or exprEnd
    lines = opt.n or lines
    printit = opt.p or printit
    crs = opt.F or crs
    irs = opt.I or irs
    overwrite = opt.i or overwrite

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
        usage()
        error('No expression to evaluate')
    end
    if #files == 0 then
        if overwrite then
            usage()
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
