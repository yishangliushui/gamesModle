require "modinfo"

print("启动-..........")

local moddir = KnownModIndex:GetModsToLoad(true)
local enablemods = {}

for k, dir in pairs(moddir) do
    local info = KnownModIndex:GetModInfo(dir)
    local name = info and info.name or "unknow"
    enablemods[dir] = name
end

-- MOD是否开启
function IsModEnable(name)
    for k, v in pairs(enablemods) do
        if v and (k:match(name) or v:match(name)) then return true end
    end
    return false
end

if IsModEnable(modinfo.name) then
    local useHotkeyEable = GetModConfigData("useHotkeyEable")
    local useHotkey = GetModConfigData("useHotkey")

    if useHotkeyEable == 0 then
        return
    end

    -- 添加监听事件
    GLOBAL.TheInput:AddKeyHandler(function(key, down)  -- 监听键盘事件
        print("key: "..key.." down: "..tostring(down))
        PrintInventoryItems()
        if down then
            if key == useHotkey then
                SwapToLastEquippedItem()
            elseif key == GLOBAL.KEY_RIGHTBRACKET then
            end
        end
    end)

    -- 确保监听器只添加一次
    if not ThePlayer.onequip_swap_listener_added then
        ThePlayer:ListenForEvent("equip", OnEquip)
        ThePlayer.onequip_swap_listener_added = true
    end

    function OnEquip(inst, equipInst)
        if equipInst and equipInst.prefab then
            inst._lastEquippedItem = equipInst
        end
    end
end

function PrintInventoryItems()
    local player = ThePlayer
    local inventory = player and player.components.inventory

    if inventory then
        print("Player Inventory Items:")
        for i, v in pairs(inventory.itemslots) do
            if v then
                print(i, v.prefab)
            end
        end
    else
        print("Player does not have an inventory component.")
    end
end

function SwapToLastEquippedItem()
    local player = ThePlayer
    if player and player.components.inventory.equipslots then
        -- 获取当前手持物品
        local currentEquipped = player.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        -- 如果有上一次使用的物品
        if player._lastEquippedItem and player._lastEquippedItem ~= currentEquipped then
            -- 判断上一个物品是否还在物品栏或背包内
            local lastEquippedItem = player._lastEquippedItem
            local foundItem = player.components.inventory:FindItem(function(item)
                return item == lastEquippedItem
            end)
            -- 如果上一个物品仍在物品栏或背包内，则进行切换
            if foundItem then
                player._secondLastEquippedItem = currentEquipped
                player.components.inventory:Equip(foundItem)
                player._lastEquippedItem = player._secondLastEquippedItem
            else
                print("Last equipped item is no longer in inventory.")
            end
        end
    end
end

