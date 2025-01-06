print("启动-..........")
local require = GLOBAL.require
local STRINGS = GLOBAL.STRINGS
local Ingredient = GLOBAL.Ingredient
local RECIPETABS = GLOBAL.RECIPETABS
local Recipe = GLOBAL.Recipe
local TECH = GLOBAL.TECH
local TUNING = GLOBAL.TUNING
local Player = GLOBAL.ThePlayer
local TheNet = GLOBAL.TheNet
local IsServer = GLOBAL.TheNet:GetIsServer()
local TheInput = GLOBAL.TheInput
local TimeEvent = GLOBAL.TimeEvent
local FRAMES = GLOBAL.FRAMES
local EQUIPSLOTS = GLOBAL.EQUIPSLOTS
local EventHandler = GLOBAL.EventHandler
local SpawnPrefab = GLOBAL.SpawnPrefab
local State = GLOBAL.State
local DEGREES = GLOBAL.DEGREES
local Vector3 = GLOBAL.Vector3
local ACTIONS = GLOBAL.ACTIONS
local FOODTYPE = GLOBAL.FOODTYPE
local PLAYERSTUNLOCK = GLOBAL.PLAYERSTUNLOCK
local GetTime = GLOBAL.GetTime
local HUMAN_MEAT_ENABLED = GLOBAL.HUMAN_MEAT_ENABLED
local TheSim = GLOBAL.TheSim
local ActionHandler = GLOBAL.ActionHandler
local KnownModIndex = GLOBAL.KnownModIndex

local constant = require "scripts.constant"
require("modindex")

-- 获取是客服端还是服务端
if TheNet:GetIsClient() then
    print("启动-客户端")
elseif TheNet:GetIsServer() then
    print("启动-服务端")
end

local moddir = KnownModIndex:GetModsToLoad(true)
local enablemods = {}
local modIndex = {}

for k, dir in pairs(moddir) do
    local info = KnownModIndex:GetModInfo(dir)
    local name = info and info.name or "unknow"
    enablemods[dir] = name
    modIndex[name] = dir
    print("已启用的Mod: "..name..k)
end

-- MOD是否开启
function IsModEnable(name)
    return modIndex[name] ~= nil or enablemods[name] ~= nil
end

if IsModEnable(constant.name) then
    local useHotkeyEable = GetModConfigData("useHotkeyEable")
    local useHotkey = GetModConfigData("useHotkey")

    if useHotkeyEable == 0 then
        return
    end

    -- 添加监听事件
    function AddInputHandler(handler)
        GLOBAL.TheInput:AddKeyHandler(function(key, down)
            handler(key, down, "keyboard")
        end)
        GLOBAL.TheInput:AddMouseButtonHandler(function(key, down)
            handler(key, down, "mouse")
        end)
    end

    AddInputHandler(function(key, down, inputType)
        print("【【【【"..inputType.." key: "..key.." down: "..tostring(down))
        PrintInventoryItems()
        if down then
            if key == useHotkey then
                SwapToLastEquippedItem()
            elseif key == GLOBAL.KEY_RIGHTBRACKET then
                -- 其他逻辑
            end
        end
    end)

    -- 定义一个函数来绑定快捷键
    function BindSwitchWeaponKey()
        local player = GLOBAL.ThePlayer
        print(debug.getmetatable(player))
        print(player)
        -- 确保监听器只添加一次
        if not player.onequip_swap_listener_added then
            player:ListenForEvent("equip", OnEquip)
            player.onequip_swap_listener_added = true
        end
    end

    function OnEquip(inst, equipInst)
        print("【【【【路径1")
        if equipInst and equipInst.prefab then
            print("【【【【路径2")
            inst._lastEquippedItem = equipInst
            return
        end
        print("【【【【路径3")
        local currentEquipped = player.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        inst._lastEquippedItem = currentEquipped
    end

    --GLOBAL.TheSim:PushEvent("playerloaded", { fn = BindSwitchWeaponKey })
    GLOBAL.AddEventCallback("ms_playerjoinedworld", BindSwitchWeaponKey)
    -- 监听所有物品的 onbreak 事件（如果需要）
    -- AddComponentPostInit("inventoryitem", function(item)
    --     if item.prefab == "yellowamulet" then
    --         item:ListenForEvent("onbreak", OnAmuletBreak)
    --     end
    -- end)
end

function PrintInventoryItems()
    local player = GLOBAL.ThePlayer
    print("Player: " ..tostring(player))
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
    local player = GLOBAL.ThePlayer
    print(player)
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
