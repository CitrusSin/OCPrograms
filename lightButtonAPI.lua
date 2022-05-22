local buttonAPI = {}

local buttonProto = { onClick = function() end }

function buttonProto:draw()
    local gpu = require("term").gpu()
    local ob = gpu.setBackground(self.backColor)
    local of = gpu.setForeground(self.foreColor)
    gpu.fill(self.x, self.y, self.w, self.h, " ")
    local textX = math.floor(self.x + (self.w - #self.text)/2)
    local textY = math.floor(self.y + self.h/2)
    gpu.set(textX, textY, self.text)
    gpu.setBackground(ob)
    gpu.setForeground(of)
end

function buttonProto:clear()
    require("term").gpu().fill(self.x, self.y, self.w, self.h, " ")
end

function buttonProto:setText(text)
    self.text = text
    self:draw()
end

function buttonProto:getText(text)
    return self.text
end

function buttonProto:remove()
    self:clear()
    require("event").cancel(self.evtId)
end

function buttonAPI.button(x, y, w, h, text, backColor, foreColor)
    local btn = setmetatable({x=x, y=y, w=w, h=h, text=text, backColor=backColor, foreColor=foreColor}, {__index = buttonProto})
    local function listener(...)
        local pack = table.pack(...)
        local x = pack[3]
        local y = pack[4]
        if (x >= btn.x) and (y >= btn.y) then
            if (x < btn.x + btn.w) and (y < btn.y + btn.h) then
                if btn.onClick ~= nil then
                    btn:onClick(x, y)
                    btn:draw()
                end
            end
        end
    end
    btn.evtId = require("event").listen("touch", listener)
    btn:draw()
    return btn
end

return buttonAPI