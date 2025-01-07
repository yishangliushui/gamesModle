-- lastuseditem.lua
local LastUsedItem = Class(function(self, inst)
    self.inst = inst
    self.last_item = nil -- 存储最后使用的物品
end)

function LastUsedItem:SetLastItem(item)
    if item and item:IsValid() then
        self.last_item = item
    end
end

function LastUsedItem:GetLastItem()
    return self.last_item
end

return LastUsedItem