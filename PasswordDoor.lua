print("loading graphicslib.....")
-------------------------绘图库内容-----------------------------
local graphicslib = {gui = {}}
local gpu = require("component").gpu

local function drawLineFunction(sX, sY, eX, eY, color)
	local offsetX = eX - sX
	local offsetY = eY - sY
	local k
	if math.abs(offsetX) > math.abs(offsetY) then
		k = math.abs(offsetX)
	else
		k = math.abs(offsetY)
	end
	local xIncrement = offsetX/k
	local yIncrement = offsetY/k
	local x, y = sX, sY
	local background = gpu.setBackground(color)
	for i=1, k do
		x=x+xIncrement
		y=y+yIncrement
		gpu.set(math.floor(x+0.5), math.floor(y+0.5), " ") --math.floor(x+0.5)是对x进行四舍五入取整
	end
	gpu.setBackground(background)
end

local function drawRectangleFunction(sX, sY, eX, eY, color, isHollow)
	local hollow = isHollow
	if isHollow == nil then
		hollow = true
	end
	if hollow then
		drawLineFunction(sX, sY, sX, eY, color)
		drawLineFunction(sX, sY, eX, sY, color)
		drawLineFunction(sX, eY, eX, eY, color)
		drawLineFunction(eX, sY, eX, eY, color)
	else
		local background = gpu.setBackground(color)
		for x=sX, eX do
			for y=sY, eY do
				gpu.set(x, y, " ")
			end
		end
		gpu.setBackground(background)
	end
end


local function drawHollowCircleFunction(cX, cY, r, color)
	local background = gpu.setBackground(color)
	for angle=0, 2*math.pi, 1/(math.abs(r)+1) do
		local offsetX = math.sin(angle)*r
		local offsetY = -math.cos(angle)*r
		local x = math.floor(cX + offsetX + 0.5)
		local y = math.floor(cY + offsetY + 0.5)
		gpu.set(x, y, " ")
	end
	gpu.setBackground(background)
end

function graphicslib.gui.drawProgressBar(x, y, length, width, backcolor, forecolor, percent)
	drawRectangleFunction(x, y, x+length-1, y+width-1, backcolor, false)
	local foreLength = math.floor(percent/100*length)
	drawRectangleFunction(x, y, x+foreLength-1, y+width-1, forecolor, false)
end

function graphicslib.drawLine(sX, sY, eX, eY, color)
	drawLineFunction(sX, sY, eX, eY, color)
end

function graphicslib.drawRectangle(sX, sY, eX, eY, color, isHollow)
	drawRectangleFunction(sX, sY, eX, eY, color, isHollow)
end

function graphicslib.drawCircle(cX, cY, radius, color, isHollow)
	local hollow = isHollow
	if isHollow == nil then
		hollow = true
	end
	if hollow then
		drawHollowCircleFunction(cX, cY, radius, color)
	else
		for r=0, radius, 0.5 do
			drawHollowCircleFunction(cX, cY, r, color)
		end
	end
end

-----------------------------------------------------------------------------------------------------
print("loading complete.")
print("Remember that the redstone signal output is on the top of the I/O block or the case.")
os.sleep(0.5)

local component = require("component")
local term = require("term")
local sides = require("sides")
local fs = require("filesystem")
local event = require("event")
if not component.isAvailable("redstone") then
	io.write("\n\n\n\n")
	local curX, curY = term.getCursor()
	curY = curY - 4
	local maxX, maxY = gpu.getResolution()
	graphicslib.drawRectangle(2, curY+1, maxX-1, curY+3, 0xFF0000)
	gpu.set(3, curY+2, "Error: Redstone card or Redstone I/O block not found.")
	return
end
local redstone = component.redstone

term.clear()
local maxX, maxY = gpu.getResolution()
local oldBackground = gpu.setBackground(0xFF9900)
graphicslib.drawRectangle(maxX/2-12, 2, maxX/2+12, 7, 0xFF9900, false)
gpu.set(maxX/2-9, 5, "oran_ge's PassLocks")
gpu.setBackground(oldBackground)
local function status(message, color)
	gpu.fill(1, maxY/2-1, maxX, 3, " ")
	graphicslib.drawRectangle(1, maxY/2-1, maxX, maxY/2+1, color, false)
	local oldBackground = gpu.setBackground(color)
	gpu.set(maxX/2-(string.len(message)/2), maxY/2, message)
	gpu.setBackground(oldBackground)
end
if not fs.exists("/etc/PassLock") then
	status("Creating password:", 0xAAAAFF)
	local pass = ""
	while true do
		local _, _, key = event.pull("key_down")
		if key == 13 then
			break
		elseif key == 8 then
			pass = string.sub(pass, 1, string.len(pass)-1)
		else
			local kc = string.char(key)
			pass = pass..kc
		end
		status("Creating password: "..pass, 0xAAAAFF)
	end
	local passf = fs.open("/etc/PassLock", "a")
	passf:write(pass)
	passf:close()
	status("Password created!", 0x00FF00)
	os.sleep(0.5)
end
status("Loading password", 0xFF0000)
local passf = fs.open("/etc/PassLock", "r")
local passRight = passf:read(fs.size("/etc/PassLock"))
passf:close()
while true do
	status("Waiting for password:", 0xFF9900)
	local pass = ""
	while true do
		local _, _, key = event.pull("key_down")
		if key == 13 then
			break
		elseif key == 8 then
			pass = string.sub(pass, 1, string.len(pass)-1)
		else
			local kc = string.char(key)
			pass = pass..kc
		end
		status("Waiting for password: "..string.rep("*", string.len(pass)), 0xFF9900)
	end
	if pass == passRight then
		status("Password right! Opening...", 0x00FF00)
		redstone.setOutput(sides.top, 15)
		os.sleep(3)
		redstone.setOutput(sides.top, 0)
	else
		status("Password wrong!", 0xFF0000)
		os.sleep(1)
	end
end