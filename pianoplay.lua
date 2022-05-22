local computer = require("computer")

local freqs = {}
local freqsn = {}

do
    local freqpp = math.pow(2, 1/12)
    for i=1, 12 do
        freqsn[i] = 220 * math.pow(freqpp, i+2)
    end
    setmetatable(freqsn, {__index = function(sf, key)
        if type(key) == "number" then
            local r = key % 12
            if r == 0 then
                r = 12
            end
            return sf[r] * math.pow(2, math.floor((key-1)/12))
        end
    end})
    freqs[0]   = 0
    freqs[0.5] = 0
    freqs[1]   = 1
    freqs[1.5] = 2
    freqs[2]   = 3
    freqs[2.5] = 4
    freqs[3]   = 5
    freqs[3.5] = 6
    freqs[4]   = 6
    freqs[4.5] = 7
    freqs[5]   = 8
    freqs[5.5] = 9
    freqs[6]   = 10
    freqs[6.5] = 11
    freqs[7]   = 12
    setmetatable(freqs, {__index = function(sf, key)
        if type(key) == "number" then
            if key > 7 then
                return sf[key-7] + 12
            elseif key < 0 then
                return sf[key+7] - 12
            end
        end
    end})
end

local args = {...}

local function readFile(filename)
    local file = io.open(filename, "r")
    local ctx = file:read("*a")
    file:close()
    return ctx
end

local function playString(musicStr, bpm)
    local offset = 0
    local spb = 60/bpm
    local major = 0
    local duration = 1
    for i=1, #musicStr do
        local ch = string.sub(musicStr, i, i)
        io.write(ch)
        if tonumber(ch) then -- Check if this char is a number
            local high = tonumber(ch)
            if high == 0 then
                os.sleep(spb * duration)
            elseif (high >= 1) and (high <= 7) then
                if string.sub(musicStr, i-1, i-1) == "#" then
                    high = high + 0.5
                elseif string.sub(musicStr, i-1, i-1) == "b" then
                    high = high - 0.5
                end
                local freq = freqsn[freqs[high] + offset] * math.pow(2, major)
                computer.pullSignal(0)
                computer.beep(freq, spb * duration - 0.01)
            end
        elseif ch == "+" then
            major = major + 1;
        elseif ch == "-" then
            major = major - 1;
        elseif ch == ">" then
            duration = duration / 2
        elseif ch == "<" then
            duration = duration * 2
        elseif ch == "[" then
            local stch = string.sub(musicStr, i-2, i-2)
            local highch = string.sub(musicStr, i-1, i-1)
            if stch == "[" then
                offset = freqs[string.byte(highch) - string.byte("A") - 2]
            elseif stch == "#" then
                offset = freqs[string.byte(highch) - string.byte("A") - 1.5]
            elseif stch == "b" then
                offset = freqs[string.byte(highch) - string.byte("A") - 2.5]
            end
        end
    end
end

local musicstr
local bpm
if #args == 2 then
    filename = args[1]
    musicstr = readFile(filename)
    bpm = tonumber(args[2])
else
    print("Input music string: ")
    musicstr = io.read()
    io.write("Input BPM: ")
    bpm = tonumber(io.read())
end

playString(musicstr, bpm)