-- Some definitions, change these if you like
local circuitBoardColor  = 0x00a400
local backgroundColor    = 0x003300
local pointColor         = 0x888888
local lineColor          = 0x00ff00
local succeedColor       = 0x00ff00
local failColor          = 0xff0000
local intervalForSeconds = 0.1
local caption            = "VLSI Circuit Breaker 2.0"
local defaultgame        = [[
           XXXXXXXXXXXXXXXXXX                            XXXXXXXXXXXXXXXXXXXXXX
NN         XXXXXXXXXXXXXXXXXX                            XXXXXXXXXXXXXXXXXXXXXX
NS                      XXXXX                            XXXXXXXXXXXXXXXXXXXXXX
NN                      XXXXX      XXXXXXXXXXXXXXXX      XXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXX        XXXXX      XXXXXXXXXXXXXXXX      XXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXX        XXXXX      XXXXXXXXXXXXXXXX      XXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXX                   XXXXXXXXXXXXXXXX      XXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXX                   XXXXXXXXXXXXXXXX                            
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX           XXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     XXXXXXXXXXXXXXXXX
XXXXXXXX               XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     XXXXXXXXXXXXXXXXX
XXXXXXXX               XXXXXXXX                               XXXXXXXXXXXXXXXXX
XXXXXXXX      XXX      XXXXXXXX                               XXXXXXXXXXXXXXXXX
XXXXXXXX      XXX      XXXXXXXX      XXXXXXXXXXXXXX     XXXXXXXXXXXXXXXXXXXXXXX
NE            XXX      XXXXXXXX      XXXXXXXXXXXXXX     XXXXXXXXXXXXXXXXXXXXXXX
NE            XXX                    XXXXXXXXXXXXXX     XXXXXXXXXXXXXXXXXXXXXXX
NE            XXX                    XXXXXXXXXXXXXX     XXXXXXXXXXXXXXXXXXXXXXX
]]
-- The real program
local term = require("term")
local event = require("event")
local keyboard = require("keyboard")
local unicode = require("unicode")
local computer = require("computer")
local gpu = term.gpu()
local mainKeyboardAddress = term.keyboard()
local args = {...}

local linechar = {
    {unicode.char(0x2552), unicode.char(0x2550), unicode.char(0x2555)},
    {unicode.char(0x2502), nil, unicode.char(0x2502)},
    {unicode.char(0x2514), unicode.char(0x2500), unicode.char(0x2518)}
}

local gamestr = ""
local game = {}
local oldWidth, oldHeight, oldBackground, oldForeground

local function saveScreen()
    oldWidth, oldHeight = gpu.getResolution()
    oldBackground = gpu.getBackground()
    oldForeground = gpu.getForeground()
end

local function restoreScreen()
    gpu.setResolution(oldWidth, oldHeight)
    gpu.setBackground(oldBackground)
    gpu.setForeground(oldForeground)
end

local function showMessage(msg, color)
    local ob = gpu.getBackground()
    local of = gpu.getForeground()
    local sx, sy = gpu.getResolution()
    local x = (sx/2)-(#msg/2)-1
    local y = sy/2-1
    gpu.setBackground(color)
    gpu.fill(x, y, #msg+2, 3, " ")
    gpu.setBackground(0xFFFFFF)
    gpu.setForeground(color)
    gpu.set(x+1, y+1, msg)
    gpu.setBackground(ob)
    gpu.setBackground(of)
end

local function split(str, seperators)
    local tabl = {}
    string.gsub(str, "[^"..seperators.."]+", function(s)
        table.insert(tabl, s)
    end)
    return tabl
end

local function readCrackFile()
    local filename
    if #args == 0 then
        gamestr = defaultgame
    else
        filename = args[1]
        local file = io.open(filename, "r")
        gamestr = file:read("*a")
        file:close()
    end
end

local function checkGame()
    local rows = split(gamestr, "\n")
    local length = #(rows[1])
    for k, v in ipairs(rows) do
        if (not (#v == length)) or string.find(v, "[^ XESN]") then
            restoreScreen()
            io.stderr:write("Error: the crack file is not regular")
            os.exit()
        end 
    end
end

local function loadGame()
    local rows = split(gamestr, "\n")
    local length = #(rows[1])
    for k, v in ipairs(rows) do
        local tabl = {}
        for i=1, length do
            table.insert(tabl, string.sub(v, i, i))
        end
        table.insert(game, tabl)
    end
end

local function runGame()
    local X, Y
    local width = #(game[1])
    local height = #game
    gpu.setResolution(width, height+1)
    gpu.setBackground(backgroundColor)
    gpu.setForeground(lineColor)
    gpu.fill(1, 1, width, 1, " ")
    gpu.set(width/2-(#caption/2), 1, caption)
    for y, rowtable in ipairs(game) do
        for x, block in ipairs(rowtable) do
            if block == "X" then
                gpu.setBackground(circuitBoardColor)
            elseif block == " " then
                gpu.setBackground(backgroundColor)
            elseif (block == "E") or (block == "S") or (block == "N") then
                gpu.setBackground(pointColor)
                if block == "S" then
                    X = x
                    Y = y
                end
            end
            gpu.set(x, y+1, " ")
        end
    end
    gpu.setBackground(backgroundColor)
    gpu.setForeground(lineColor)
    local nowFacing = 3 -- nowFacing:
                        --   0
                        -- 1 + 3
                        --   2
                        -- so when game starts, the line will always go right
    while true do
        local pack = table.pack(event.pullMultiple(intervalForSeconds, "key_down", "interrupt"))
        if pack[1] == "key_down" then
            local keyboardAddress = pack[2]
            local key = pack[4]
            if keyboardAddress == mainKeyboardAddress then
                local lastFacing = nowFacing
                if key == keyboard.keys.w then
                    nowFacing = 0
                elseif key == keyboard.keys.a then
                    nowFacing = 1
                elseif key == keyboard.keys.s then
                    nowFacing = 2
                elseif key == keyboard.keys.d then
                    nowFacing = 3
                end
                if math.abs(nowFacing - lastFacing) == 2 then   -- The player tries to turn around! How could this happen!
                    nowFacing = lastFacing
                elseif not (lastFacing == nowFacing) then
                    local turnchar = ""
                    if lastFacing == 0 then
                        if nowFacing == 1 then
                            turnchar = linechar[1][3]
                        elseif nowFacing == 3 then
                            turnchar = linechar[1][1]
                        end
                    elseif lastFacing == 1 then
                        if nowFacing == 0 then
                            turnchar = linechar[3][1]
                        elseif nowFacing == 2 then
                            turnchar = linechar[1][1]
                        end
                    elseif lastFacing == 2 then
                        if nowFacing == 1 then
                            turnchar = linechar[3][3]
                        elseif nowFacing == 3 then
                            turnchar = linechar[3][1]
                        end
                    elseif lastFacing == 3 then
                        if nowFacing == 0 then
                            turnchar = linechar[3][3]
                        elseif nowFacing == 2 then
                            turnchar = linechar[1][3]
                        end
                    end
                    gpu.set(X, Y+1, turnchar)
                end
            end
        elseif pack[1] == nil then
            if nowFacing == 0 then
                Y = Y - 1
            elseif nowFacing == 1 then
                X = X - 1
            elseif nowFacing == 2 then
                Y = Y + 1
            elseif nowFacing == 3 then
                X = X + 1
            end
            -- Collision detection
            if (X<0) or (Y<1) or (X>width) or (Y>height) then
                showMessage("FAILED", failColor)
                os.sleep(0.1)
                computer.beep(234, 1)
                return false
            elseif game[Y][X] == "X" then
                showMessage("FAILED", failColor)
                os.sleep(0.1)
                computer.beep(234, 1)
                return false
            elseif game[Y][X] == "E" then
                showMessage("SUCCEEDED", succeedColor)
                os.sleep(0.1)
                computer.beep(873, 1)
                return true
            else
                if (nowFacing == 0) or (nowFacing == 2) then
                    gpu.set(X, Y+1, linechar[2][1])
                else
                    gpu.set(X, Y+1, linechar[1][2])
                end
            end
        elseif pack[1] == "interrupt" then
            restoreScreen()
            term.clear()
            os.exit()
        end
    end
end

saveScreen()
readCrackFile()
checkGame()
print("Crack program is loading. Please wait...")
loadGame()
while not runGame() do term.clear() end
restoreScreen()
term.clear()
os.exit()