local component = require("component")
local robot = require("robot")
local sides = require("sides")
local term = require("term")

local gpu = term.gpu()
local ic = component.inventory_controller

local rX, rY = gpu.getResolution()

local function info(msg)
    gpu.copy(1, 4, rX, rY-3, 0, -1)
    gpu.fill(1, rY, rX, 1, " ")
    gpu.set(1, rY, "["..os.date().." INFO] "..msg)
end

term.clear()
print("Auto-Wither v1.0 working...")
while true do
    info("Dropping items")
    for i=1, robot.inventorySize() do
        robot.select(i)
        robot.drop(64)
    end
    robot.select(1)
    local skullDone = false
    local sandDone = false
    while not (skullDone and sandDone) do
        info("Collecting materials")
        for i=1, ic.getInventorySize(sides.bottom) do
            local stack = ic.getStackInSlot(sides.bottom, i)
            if stack then
                if (not skullDone) and (stack.name == "minecraft:skull") and (stack.damage == 1) and (stack.size >= 3) then
                    robot.select(1)
                    ic.suckFromSlot(sides.bottom, i, 3)
                    skullDone = true
                elseif (not sandDone) and (stack.name == "minecraft:soul_sand") and (stack.size >= 4) then
                    robot.select(2)
                    ic.suckFromSlot(sides.bottom, i, 4)
                    sandDone = true
                end
                if skullDone and sandDone then
                    break
                end
            end
        end
        if not (skullDone and sandDone) then
            info("Waiting for 1 minute")
            os.sleep(30)
        end
    end
    info("Placing wither pattern")
    robot.select(2)
    robot.place()
    robot.up()
    robot.place()
    robot.turnLeft()
    robot.forward()
    robot.turnRight()
    robot.place()
    robot.turnRight()
    robot.forward()
    robot.forward()
    robot.turnLeft()
    robot.place()
    robot.up()
    robot.select(1)
    robot.place(sides.down)
    for i=1, 2 do
        robot.turnLeft()
        robot.forward()
        robot.turnRight()
        robot.place(sides.down)
    end
    robot.turnRight()
    robot.forward()
    robot.turnLeft()
    robot.down()
    robot.down()
    info("Waiting for 40 seconds")
    os.sleep(40)
end