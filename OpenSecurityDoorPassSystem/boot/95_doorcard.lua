local rfid = require("component").os_rfidreader
local reds = require("component").redstone
local sides = require("sides")
local fs = require("filesystem")
require("event").timer(2, function()
  rfid.scan(2)
end, math.huge)
require("event").listen("rfidData", function(_, _, name, _, RFID)
  local doc = fs.open("secsys/"..name, "r")
  if doc then
    local realRFID = doc:read(fs.size("secsys/"..name))
    if realRFID == RFID then
      reds.setOutput(sides.top, 15)
      require("event").timer(1, function() reds.setOutput(sides.top, 0) end)
    end
  end
end)