local component = require("component")
local term = require("term")

local reactor = component.nc_fission_reactor
local gpu = term.gpu()

local rx, ry = gpu.maxResolution()
gpu.setResolution(rx, ry)
term.clear()

local GREY = 0x303030
local RED = 0xFF0000
local GREEN = 0x00FF00
local YELLOW = 0xFFFF00
local BLUE = 0x0000FF

local function drawProgressBarVertical(x, y, w, h, foreColor, backColor, percent)
    local prevColor = gpu.setBackground(backColor)
    gpu.fill(x, y, w, h, " ")
    local height = math.floor(h*percent/100)
    gpu.setBackground(foreColor)
    gpu.fill(x, y+h-height, w, height, " ")
    gpu.setBackground(prevColor)
end

local function progressVerticalWithName(name, x, y, w, h, foreColor, backColor, percent)
    drawProgressBarVertical(x, y, w, h-1, foreColor, backColor, percent)
    local med = math.floor(x+(w/2))
    local startX = med - math.floor(#name/2)
    gpu.set(startX, y+h-1, name)
end

local function unitOptimize(num, unit, resDigit)
    resDigit = resDigit or 2
    local m = math.pow(10, resDigit)
    local digits = math.log(num) / math.log(10)
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

while true do
    local energyStored = reactor.getEnergyStored()
    local maxEnergy = reactor.getMaxEnergyStored()
    local energyPercent = energyStored / maxEnergy * 100

    local processTime = reactor.getCurrentProcessTime()
    local fuelTime = reactor.getFissionFuelTime()
    local timePercent = processTime / fuelTime * 100

    progressVerticalWithName("ENER", 2, 2, 4, ry-2, RED, GREY, energyPercent)
    progressVerticalWithName("TIME", 7, 2, 4, ry-2, GREEN, GREY, timePercent)
    local statusText = "Status: "
    if reactor.isProcessing() then
        statusText = statusText .. "RUNNING"
    else
        statusText = statusText .. "IDLE   "
    end
    gpu.set(12, 2, statusText)

    gpu.set(12, 3, "Efficiency: " .. tostring(math.floor(reactor.getEfficiency())) .. "%     ")
    gpu.set(12, 4, "Energy: " .. unitOptimize(reactor.getEnergyStored(), "RF") .. "(" .. tostring(math.floor(energyPercent)) .. "%)     ")
    if energyPercent > 60 then
        reactor.deactivate()
    elseif energyPercent < 40 then
        reactor.activate()
    end
    os.sleep(0.1)
end

