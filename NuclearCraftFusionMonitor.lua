local LOOP_SLEEP_TIME = 0.5

local ln10 = math.log(10) -- Optimize speed

local component = require("component")
local keys = require("keyboard").keys
local event = require("event")
local term = require("term")
local gpu = term.gpu()

local reactors = {}
for addr in component.list("nc_fusion_reactor") do
    table.insert(reactors, component.proxy(addr))
end

if #reactors == 0 then
    io.stderr:write("No reactors connected! exiting\n")
    os.exit()
end

local reactorsCount = #reactors
local rx, ry = gpu.maxResolution()
gpu.setResolution(rx, ry)

local function rectangle(x, y, w, h, c)
    local oc = gpu.setBackground(c)
    gpu.fill(x, y, w, h, " ")
    gpu.setBackground(oc)
    gpu.fill(x+1, y+1, w-2, h-2, " ")
end

local function fixedRectangle(x, y, w, h, c)
    local oc = gpu.setBackground(c)
    gpu.fill(x, y, w, h, " ")
    gpu.setBackground(oc)
    gpu.fill(x+2, y+1, w-4, h-2, " ")
end

local function progress(x, y, w, h, bc, fc, pct)
    local oc = gpu.setBackground(bc)
    gpu.fill(x, y, w, h, " ")
    local sw = math.max(math.min(math.floor(w * pct / 100), w), 0)
    gpu.setBackground(fc)
    gpu.fill(x, y, sw, h, " ")
    gpu.setBackground(oc)
end

local function unitOptimize(num, unit, resDigit)
    resDigit = resDigit or 2
    local m = math.pow(10, resDigit)
    local digits = math.log(num) / ln10 -- math.log10 is deprecated so i use this
    local showText
    if digits < 3 then
        showText = tostring(math.floor(num * m) / m) .. unit
    elseif (digits >= 3) and (digits < 6) then
        showText = tostring(math.floor(num / 1000 * m) / m) .. "k" .. unit
    elseif (digits >= 6) and (digits < 9) then
        showText = tostring(math.floor(num / 1000000 * m) / m) .. "M" .. unit
    elseif digits >= 9 then
        showText = tostring(math.floor(num / 1000000000 * m) / m) .. "G" .. unit
    end
    return showText
end

local rects = {}

local function showReactorInRect(index, x, y, w, h, reactor)
    local processing = reactor.isProcessing()
    local complete = reactor.isComplete()
    local rectColor = 0xFF273A
    if complete and (not processing) then
        rectColor = 0x007C00
    elseif complete and processing then
        rectColor = 0xC673FF
    end
    fixedRectangle(x + math.floor(w/2) - 12, y + 2, 24, 12, rectColor)
    local ob = gpu.setBackground(0x3F3FFE)
    gpu.fill(x + math.floor(w/2) - 4, y + 6, 8, 4, " ")
    gpu.setBackground(ob)

    local cursor = 16


    local size = reactor.getToroidSize()
    gpu.set(x + 1, y + cursor, "Toroid Size: " .. tostring(math.floor(size)))
    cursor = cursor + 1
    gpu.set(x + 1, y + cursor, "First Fuel: " .. reactor.getFirstFusionFuel())
    gpu.set(x + 1, y + cursor + 1, "Second Fuel: " .. reactor.getSecondFusionFuel())
    cursor = cursor + 2

    local power = reactor.getReactorProcessPower()
    local digits = math.log(power) / ln10 -- math.log10 is deprecated so i use this
    gpu.set(x+1, y+cursor, "Energy Produce Rate: " .. unitOptimize(power, "RF/t") .. "      ")
    cursor = cursor + 1

    local efficiency = reactor.getEfficiency()
    gpu.set(x + 1, y + cursor, "Efficiency: " .. tostring(math.floor(efficiency * 10) / 10) .. "%      ")
    progress(x + 1, y + cursor + 1, w - 2, 3, 0x4C4C4C, 0x6CFF6C, efficiency)
    cursor = cursor + 4

    local temp = reactor.getTemperature()
    local maxTemp = reactor.getMaxTemperature()
    local tempPct = temp / maxTemp * 100
    local showText = tostring(math.floor(tempPct*10)/10) .. "% (" .. unitOptimize(temp, "K") .. "/" .. unitOptimize(maxTemp, "K") .. ")"
    gpu.fill(x, y+cursor, w, 1, " ")
    gpu.set(x+1, y+cursor, "Temperature: " .. showText)
    progress(x+1, y+cursor+1, w-2, 3, 0x4C4C4C, 0xFFFF54, tempPct)
    cursor = cursor + 4

    local comboTime = reactor.getFusionComboTime()
    local cpt = reactor.getCurrentProcessTime()
    local comboPct = cpt / comboTime * 100
    gpu.set(x+1, y+cursor, "Fusion Combo Progress: " .. tostring(math.floor(comboPct)) .. "%      ")
    progress(x+1, y+cursor+1, w-2, 3, 0x4C4C4C, 0xFEACEC, comboPct)
    cursor = cursor + 4

    local es = reactor.getEnergyStored()
    local mes = reactor.getMaxEnergyStored()
    local energyPct = es / mes * 100
    showText = tostring(math.floor(energyPct*10)/10) .. "% (" .. unitOptimize(es, "RF") .. "/" .. unitOptimize(mes, "RF") .. ")"
    gpu.fill(x, y+cursor, w, 1, " ")
    gpu.set(x+1, y+cursor, "Stored Energy: " .. showText)
    progress(x+1, y+cursor+1, w-2, 3, 0x4C4C4C, 0xFF4C52, energyPct)
    cursor = cursor + 4

    if tempPct >= 95 then
        rects[index].overheat = true
        reactor.deactivate()
    end
    if rects[index].overheat then
        local of = gpu.setForeground(0xFF7C7D)
        gpu.set(x+1, y+cursor, "OVERHEATED")
        gpu.set(x+1, y+cursor+1, "Overheat protection enabled")
        gpu.set(x+1, y+cursor+2, "This reactor is now deactivated.")
        gpu.set(x+1, y+cursor+2, "Manually restart by pressing Enter.")
        cursor = cursor + 4
        gpu.setForeground(of)
    else
        local of = gpu.setForeground(0x5CFF5C)
        gpu.set(x+1, y+cursor, "NO EXCEPTIONS")
        cursor = cursor + 1
        gpu.setForeground(of)
    end
end

gpu.setBackground(0x000000)
gpu.setForeground(0xFFFFFF)
local singleWidth = math.floor(rx / reactorsCount)
for i, v in ipairs(reactors) do
    rects[i] = {}
    rects[i].x = singleWidth * (i-1) + 1
    rects[i].y = 1
    rects[i].w = singleWidth
    rects[i].h = ry - 4
    rects[i].overheat = false
end
rects[#rects].w = rx - (singleWidth * (reactorsCount - 1))
for i, v in ipairs(reactors) do
    local r = rects[i]
    rectangle(r.x, r.y, r.w, r.h, 0x9C9C9C)
    gpu.set(r.x+1, r.y, "Reactor #"..tostring(i))
end
rectangle(1, ry-4, rx, 5, 0x9C9C9C)

while true do
    for i, v in ipairs(reactors) do
        local r = rects[i]
        showReactorInRect(i, r.x+1, r.y+1, r.w-2, r.h-2, v)
    end
    local totalPower = 0
    for i, v in ipairs(reactors) do
        totalPower = totalPower + v.getReactorProcessPower()
    end
    gpu.set(2, ry-2, "Total Power Rate: " .. unitOptimize(totalPower, "RF/t", 2) .. "        ")
    local pack = table.pack(event.pullMultiple(LOOP_SLEEP_TIME, "interrupted", "key_down"))
    if pack[1] == "interrupted" then
        term.clear()
        break
    elseif pack[1] == "key_down" then
        if pack[4] == keys.enter then
            term.clear()
            for i, v in pairs(reactors) do
                v.activate()
                rects[i].overheat = false
                local r = rects[i]
                rectangle(r.x, r.y, r.w, r.h, 0x9C9C9C)
                gpu.set(r.x+1, r.y, "Reactor #"..tostring(i))
            end
            rectangle(1, ry-4, rx, 5, 0x9C9C9C)
        end
    end
end