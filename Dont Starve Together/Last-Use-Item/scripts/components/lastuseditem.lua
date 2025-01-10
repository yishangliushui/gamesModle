-- lastuseditem.lua
local LastUsedItem = Class(function(self, inst)
    self.inst = inst
    self.last_item = nil -- 存储最后使用的物品
end)

function LastUsedItem:SetLastItem(item)
    if item and item:IsValid() then
        self.last_item = item
        if self._setlastitem then
            self._setlastitem:set(item.GUID) -- 传递GUID而不是实体本身
        end
    end
end

function LastUsedItem:GetLastItem()
    return self.last_item
end


return LastUsedItem