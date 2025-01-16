-- 定义一个类来管理消息ID
local MessageContext = {}
MessageContext.__index = MessageContext

function MessageContext:new(msgId)
    local instance = setmetatable({}, self)
    instance.msgId = msgId
    return instance
end

function MessageContext:level3()
    print("Level 3 - MsgId: " .. self.msgId)
end

function MessageContext:level2()
    self:level3()
end

function MessageContext:level1()
    self:level2()
end

-- 创建一个实例并调用最上层函数
local ctx = MessageContext:new("unique_msg_id")
ctx:level1()