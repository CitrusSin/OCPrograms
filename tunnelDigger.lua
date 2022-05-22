local component = require("component")
local robot = require("robot")
local shell = require("shell")
local inv = component.inventory_controller

local args, options = shell.parse(...)

if #args == 3 then
  print("Hello, I'm "..robot.name().."!")
  print("Please give me a pickaxe and some torches!")
  print("When you ready, enter \"y\" to confirm.")
  while true do
    char = io.read()
    if char == "y" then
      break
    end
  end
  function digforward(i, w, h)
    robot.swing()
    robot.forward()
    robot.turnRight()
    for height=1, h do
      for weight=1, w-1 do
        robot.swing()
		robot.forward()
      end
      for j=1, w-1 do
        robot.back()
      end
      if height < tonumber(h) then
        robot.swingUp()
        robot.up()
      end
    end
    for he=1, h-1 do
      robot.down()
    end
    if i%5==0 then
      robot.turnAround()
      robot.swing()
      robot.place()
      robot.turnRight()
    else
      robot.turnLeft()
    end
    for item=1, robot.inventorySize() do
      local itemTable = inv.getStackInInternalSlot(item)
      if itemTable ~= nil then
        local itemName = itemTable.name
        if itemName == "minecraft:cobblestone" or itemName == "minecraft:stone" or itemName == "minecraft:dirt" then
          robot.select(item)
          robot.drop(64)
        end
      end
    end
    robot.select(1)
  end
  if args[1]=="neverstop" then
    i=1
    while true do
      digforward(i, args[2], args[3])
      i=i+1
    end
  else
    for i=1, args[1] do
      digforward(i, args[2], args[3])
    end
  end
  robot.turnAround()
  for length=1, args[1] do
    while true do
      local cg = robot.forward()
      if cg then
        break
      end
    end
  end
  robot.turnAround()
  print("I got it!")
else
  io.stderr:write("Illegal arguments.\n")
end