local component = require("component")
local fs = require("filesystem")
local event = require("event")
local shell = require("shell")
local computer = require("computer")
local card = component.os_cardwriter

local args, ops = shell.parse(...)

print("Press a key to verify your biometrics: ")
local _, _, _, _, playerName = event.pull("key_down")
print("Hello, " .. playerName .. "!")
print("Now insert your card into the card writer...")
local randomRFIDarray = {}
math.randomseed(computer.uptime())
for i=1, 64 do
  randomRFIDarray[i] = math.random(32, 126)
end
local RFID = string.char(table.unpack(randomRFIDarray))
while true do
  local result, error = card.write(RFID, playerName, false, math.random(1, 15))
  if result then break end
  os.sleep(0)
end
print("The card has written now.")
print("Registering your card's ID...")
local doc = fs.open("secsys/"..playerName, "w")
doc:write(RFID)
doc:close()
print("Registration complete. Now you can pull your card out.")