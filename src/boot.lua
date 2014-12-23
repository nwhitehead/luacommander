re=require('rex_pcre')
inspect=require('inspect')

function __process(f, lines, autosplit, irs, crs)
    if __debug then
        print('__process', f, lines, autosplit, irs, crs)
    end
    if lines then
        for _ in io.lines() do
            f(_)
        end
        if final then final() end
        return
    end
    f()
end
