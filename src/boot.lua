re=require('rex_pcre')
inspect=require('inspect')

function __process(f, fend, lines, autosplit, irs, crs)
    if lines then
        for _ in io.lines() do
            if f then
                f(_)
            end
        end
        if fend then
            fend()
        end
        return
    end
    if f then
        f()
    end
    if fend then
        fend()
    end
end
