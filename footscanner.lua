local redstone = component.proxy(component.list("redstone")())
local gpu = component.proxy(component.list("gpu")())

local function sleep(second)
  local deadline = computer.uptime() + second
  repeat
  until computer.uptime() >= deadline
end

local screen = component.list("screen")()
component.proxy(screen).turnOn()
gpu.bind(screen)
local sx, sy = 12, 6
gpu.setResolution(sx, sy)
while true do
  gpu.setBackground(0xFFFFFF)
  gpu.setForeground(0x000000)
  gpu.fill(1, 1, sx, sy, " ")
  local name, _, _, _, player = computer.pullSignal()
  if name == "walk" then
    gpu.set(1, 1, "Scanning...-")
    sleep(0.1)
    gpu.set(1, 1, "Scanning...\\")
    sleep(0.1)
    gpu.set(1, 1, "Scanning.../")
    sleep(0.1)
    gpu.set(1, 1, "Scanning...-")
    sleep(0.1)
    gpu.set(1, 1, "Scanning...\\")
    sleep(0.1)
    gpu.set(1, 1, "Scanning.../")
    sleep(0.1)
    gpu.set(1, 1, "Scanning...-")
    sleep(0.1)
    gpu.set(1, 1, "Scanning...\\")
    sleep(0.1)
    gpu.set(1, 1, "Scanning.../")
    sleep(0.1)
    gpu.set(1, 1, "Scanning...-")
    sleep(0.1)
    gpu.set(1, 1, "Scanning...\\")
    sleep(0.1)
    gpu.set(1, 1, "Scanning.../")
    sleep(0.1)
    gpu.set(1, 1, "Scanning...-")
    sleep(0.1)
    gpu.set(1, 1, "Scanning...\\")
    sleep(0.1)
    gpu.set(1, 1, "Scanning.../")
    sleep(0.1)
    gpu.set(1, 1, "Scanning...-")
    sleep(0.1)
    gpu.set(1, 1, "Scanning...\\")
    sleep(0.1)
    gpu.set(1, 1, "Scanning.../")
    sleep(0.1)
    if player == "oran_ge" then
      gpu.setBackground(0x00FF00)
      for x=1, sx do
        for y=1, sy do
          local c = gpu.get(x, y)
          gpu.set(x, y, c)
        end
      end
      gpu.set(1, 2, "Done!")
      computer.beep(1000, 1)
      redstone.setOutput(1, 15)
      sleep(0.2)
      redstone.setOutput(1, 0)
    else
      gpu.setBackground(0xFF0000)
      for x=1, sx do
        for y=1, sy do
          local c = gpu.get(x, y)
          gpu.set(x, y, c)
        end
      end
      gpu.set(1, 2, "Failed!")
      computer.beep(500, 1)
    end
  end
end