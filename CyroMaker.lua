local component = require("component")
local robot = require("robot")
local sides = require("sides")

local invc = component.inventory_controller
local crafting = component.crafting

-- Expected working environment:
-- ------------------------------
-- |       |   Input  |         |
-- |       |Cyro fluid|         |
-- ------------------------------
-- |Charger|   Robot  |  Input  |
-- |       |   Init-> |PipeChest|
-- ------------------------------
-- |       |  Output  |         |
-- |       |   Chest  |         |
-- ------------------------------
--
-- Note: Put some empty buckets in Slot4
--       and keep other slots ALWAYS EMPTY

local function info(msg)
    print(string.format("[%s INFO] %s", os.date(), msg))
end

while true do
    local size = invc.getInventorySize(sides.front)
    local pipeAmount = 0
    local slots = {}
    for i=1, size do
        local stack = invc.getStackInSlot(sides.front, i)
        if stack then
            if string.match(stack.name, "duct") and string.match(stack.label, "Cryo") then
                pipeAmount = pipeAmount + stack.size
                slots[i] = stack.size
            end
        end
    end

    if pipeAmount >= 1 then
        info("Input detected.")
        robot.select(1)

        -- Limiting single crafting task maximum count to 64
        local suckPipeAmount = 0
        for slot, size in pairs(slots) do
            if (suckPipeAmount + size) < 64 then
                invc.suckFromSlot(sides.front, slot, size)
                suckPipeAmount = suckPipeAmount + size
            elseif suckPipeAmount < 64 then
                invc.suckFromSlot(sides.front, slot, 64-suckPipeAmount)
                suckPipeAmount = 64
                break
            end
        end
        -- Reset slots variable
        slots = {}

        -- Keep pipe amount to an even number
        if suckPipeAmount % 2 == 1 then
            suckPipeAmount = suckPipeAmount - 1
            robot.drop(1)
        end

        -- Split pipes into two stacks
        robot.transferTo(2, suckPipeAmount/2)
        -- Prepare for fluid filling
        robot.select(4)
        local bucketCount = robot.count()
        local craftCount = suckPipeAmount / 2

        info("-----NEW CRAFT TASK-----")
        info(string.format("Craft count: %d", craftCount))
        info(string.format("Bucket: %d", bucketCount))
        info("------------------------")

        invc.equip()
        -- Turn to fluid source
        robot.turnLeft()
        robot.select(5)
        for i=1, craftCount do
            if (i % bucketCount) == 0 then
                -- If there're only one bucket in the toolbar
                -- The buck wouldn't automatically eject into the selected slot
                -- So the procedure should be done by program
                robot.use()
                invc.equip()
                local stack = invc.getStackInInternalSlot(5)
                while stack.name == "minecraft:bucket" do
                    invc.equip()
                    os.sleep(0.1)
                    robot.use()
                    invc.equip()
                    stack = invc.getStackInInternalSlot(5)
                end
            else
                -- Otherwise we just keep trying to fill the bucket
                robot.use()
                while robot.count() == 0 do
                    os.sleep(0.1)
                    robot.use()
                end
            end

            -- Craft!
            robot.select(8)
            crafting.craft()

            -- Return the empty bucket
            robot.select(5)
            robot.transferTo(4)

            -- If the bucket is used up, equip those buckets again
            if (i % bucketCount) == 0 then
                robot.select(4)
                invc.equip()
                robot.select(5)
            end
        end

        -- Reset buckets
        if (craftCount % bucketCount) == 0 then
            robot.select(4)
            invc.equip()
        else
            -- Avoid exchanging stacks between slots, only extract buckets from the tool slot
            -- Slot 12 must be always empty
            robot.select(12)
            invc.equip()
            robot.transferTo(4)
        end

        -- Dropping products
        robot.turnAround()
        robot.select(8)
        robot.drop()
        robot.turnLeft()
        robot.select(1)

        info("Completed.")
    end
    os.sleep(0.1)
end