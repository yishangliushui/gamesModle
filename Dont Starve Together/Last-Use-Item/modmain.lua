GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})
print("启动-..........")
-- 全局的require函数，用于加载模块
local require = GLOBAL.require
-- 字符串资源，用于界面显示和支持
local STRINGS = GLOBAL.STRINGS
-- Ingredient类，用于定义食谱中的材料
local Ingredient = GLOBAL.Ingredient
-- RECIPETABS，用于分类食谱
local RECIPETABS = GLOBAL.RECIPETABS
-- Recipe类，用于定义制作食谱
local Recipe = GLOBAL.Recipe
-- 技术等级，用于控制食谱的解锁
local TECH = GLOBAL.TECH
-- 调优参数，用于控制游戏平衡
local TUNING = GLOBAL.TUNING
-- 玩家对象，用于获取当前玩家的信息
local Player = GLOBAL.ThePlayer
-- 网络功能，用于判断是否为服务器
local TheNet = GLOBAL.TheNet
-- 判断当前是否为服务器，用于后续的服务器端逻辑判断
local IsServer = GLOBAL.TheNet:GetIsServer()
-- 输入功能，用于获取玩家输入
local TheInput = GLOBAL.TheInput
-- 时间事件，用于时间相关的事件处理
local TimeEvent = GLOBAL.TimeEvent
-- 帧数常量，用于动画和更新频率控制
local FRAMES = GLOBAL.FRAMES
-- 装备槽位，用于管理角色装备
local EQUIPSLOTS = GLOBAL.EQUIPSLOTS
-- 事件处理器，用于处理各种游戏事件
local EventHandler = GLOBAL.EventHandler
-- 生成预设物体函数，用于在游戏中生成物体
local SpawnPrefab = GLOBAL.SpawnPrefab
-- 状态类，用于管理角色或物体的状态
local State = GLOBAL.State
-- 角度转换常量，用于角度和弧度的转换
local DEGREES = GLOBAL.DEGREES
-- 三维向量类，用于表示三维空间中的位置
local Vector3 = GLOBAL.Vector3
-- 动作常量，用于表示游戏中的各种动作
local ACTIONS = GLOBAL.ACTIONS
-- 食物类型，用于分类食物和影响角色属性
local FOODTYPE = GLOBAL.FOODTYPE
-- 玩家解锁系统，用于控制玩家的解锁进度
local PLAYERSTUNLOCK = GLOBAL.PLAYERSTUNLOCK
-- 获取时间函数，用于获取当前游戏时间
local GetTime = GLOBAL.GetTime
-- 人类肉质是否启用的标志，用于控制某些游戏内容的可用性
local HUMAN_MEAT_ENABLED = GLOBAL.HUMAN_MEAT_ENABLED
-- 模拟世界对象，用于访问和操作游戏世界
local TheSim = GLOBAL.TheSim
-- 动作处理器，用于处理玩家的输入动作
local ActionHandler = GLOBAL.ActionHandler
-- 已知模组索引，用于管理加载的模组信息
local KnownModIndex = GLOBAL.KnownModIndex

--local lastuseditem = require "scripts/lastuseditem"

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

local function turnoff_yellow(inst)
    if inst._light ~= nil then
        if inst._light:IsValid() then
            inst._light:Remove()
        end
        inst._light = nil
    end
end

local function miner_perish(inst)
    local equippable = inst.components.equippable
    if equippable ~= nil and equippable:IsEquipped() then
        local owner = inst.components.inventoryitem ~= nil and inst.components.inventoryitem.owner or nil
        if owner ~= nil then
            local data =
            {
                prefab = inst.prefab,
                equipslot = equippable.equipslot,
            }
            turnoff_yellow(inst)
            owner:PushEvent("torchranout", data)
            return
        end
    end
    turnoff_yellow(inst)
end

local function yishang_onunequip_yellow(inst, owner)
    if owner.components.bloomer ~= nil then
        owner.components.bloomer:PopBloom(inst)
    else
        owner.AnimState:ClearBloomEffectHandle()
    end

    owner.AnimState:ClearOverrideSymbol("swap_body")

    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("unequipskinneditem", inst:GetSkinName())
    end

    if inst.components.fueled ~= nil then
        inst.components.fueled:StopConsuming()
    end

    turnoff_yellow(inst)
end

local function OnEquipped(inst, data)
    print("【【【【shoudaojianting ")
    if data.slot == EQUIPSLOTS.HANDS then
        inst.components.lastuseditem:SetLastItem(data.item)
    end
end

local function OnUnequipped(inst, data)
    print("【【【【shoudaojianting 1123")
    if data.slot == EQUIPSLOTS.HANDS then
        -- 这里可以做任何需要的操作，例如清空或保留最后的物品
    end
end

-- 在main.lua或其他合适的地方
local function OnKeyDown(inst, data)
    if data.key == 308 then -- 替换为你的快捷键
        SendRPCToServer("RPCSwitchToLastItem")
    end
end

if IsModEnable("Last Use Item") then
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
        -- 获取是客服端还是服务端
        if TheNet:GetIsClient() then
            print("启动-客户端")
        elseif TheNet:GetIsServer() then
            print("启动-服务端")
        end
        PrintInventoryItems()
        if down then
            local Player = GLOBAL.ThePlayer
            if key == useHotkey then
                print("Sending RPCSwitchToLastItem for player:", Player.GUID) -- 调试信息
                --SendModRPCToServer(MOD_RPC["Last Use Item"]["RPCSetLastItem"])
                --SwapToLastEquippedItem()
                SwapToLastEquippedItem_new()
            elseif key == GLOBAL.KEY_RIGHTBRACKET then
                -- 其他逻辑
            end
        end
    end)

    -- 定义一个函数来绑定快捷键
    function BindSwitchWeaponKey()
        print("【【【【加入日志...................................")
        print(GLOBAL.debug.getmetatable(Player))
        print(Player)
        -- 确保监听器只添加一次
        if not Player.onequip_swap_listener_added then
            Player:ListenForEvent("equip", OnEquip)
            Player.onequip_swap_listener_added = true
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
        local currentEquipped = Player.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        inst._lastEquippedItem = currentEquipped
    end

    --GLOBAL.TheSim:PushEvent("payerloaded", { fn = BindSwitchWeaponKey })
    --GLOBAL.AddEventCallback("ms_playerjoined", BindSwitchWeaponKey)
    -- 在main.lua或其他合适的地方

    AddPlayerPostInit(function(inst)
        print("【【【【启动-服务端-用户"..tostring(GLOBAL.TheWorld.ismastersim))
        print(inst)
        if GLOBAL.TheWorld.ismastersim then
            if not inst.components.lastuseditem then
                inst:AddComponent("lastuseditem")
            end
            -- 添加事件监听
            inst:ListenForEvent("equipped", OnEquipped)
            inst:ListenForEvent("unequipped", OnUnequipped)
        end
    end)

    AddPrefabPostInit("yellowamulet", function(inst)
        print("【【【【启动-服务端-重新初始化")
        if not GLOBAL.TheWorld.ismastersim then
            return
        end
        if inst.components.fueled then
            inst.components.fueled:SetDepletedFn(yishang_onunequip_yellow)
        end
    end)

    AddComponentPostInit("lastuseditem", function(component)
        local inst = component.inst
        if TheWorld.ismastersim then
            print("监听装备变化111111")
            -- 定义网络变量
            inst._last_used_item = net_entity(inst.GUID, "inst._last_used_item")

            -- 监听装备变化
            inst:ListenForEvent("equip", function(inst, data)
                print("监听装备变化2222222")
                if data.slot == EQUIPSLOTS.HANDS then
                    component:SetLastItem(data.item)
                    print("监听装备变化2222222"..tostring(data.item).."__"..tostring(data.item.GUID))
                    inst._last_used_item:set(data.item.GUID) -- 传递GUID
                end
            end)

            -- 保存和加载状态
            function component:OnSave()
                local data = {}
                if component.last_item then
                    data.last_item = component.last_item.GUID
                end
                return data
            end

            function component:OnLoad(data)
                if data and data.last_item then
                    local last_item = EntityRegistry[data.last_item]
                    if last_item and last_item:IsValid() then
                        component:SetLastItem(last_item)
                        inst._last_used_item:set(last_item.GUID) -- 传递GUID
                    end
                end
            end
        else
            -- 客户端获取最后使用的物品
            function component:GetLastItem()
                local guid = inst._last_used_item:value()
                if guid ~= 0 then
                    return EntityRegistry[guid]
                end
                return nil
            end
        end
    end)

    -- common.lua
    local function RPCSetLastItem(player)
        print("收到客户端的请求。。。。。。")
        local ThePlayer = GLOBAL.ThePlayer
        print(tostring(ThePlayer))
        if ThePlayer then
            print(tostring(ThePlayer.components))
            print(tostring(ThePlayer.components.inventory))
        end
        for i,v in ipairs(GLOBAL.AllPlayers) do
            print(i, v)
            print("111=========")
            for k, g in pairs(v) do
                print(k, g)
            end
            print("222=========")
        end
        if ThePlayer and ThePlayer.components.inventory then
            -- ThePlayer.replica.inventory
            print("1===============================")
            -- 获取当前手持物品
            local currentEquipped = ThePlayer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            print("2==============================="..tostring(currentEquipped))
            -- 如果有上一次使用的物品
            if ThePlayer._lastEquippedItem and ThePlayer._lastEquippedItem ~= currentEquipped then
                -- 判断上一个物品是否还在物品栏或背包内
                local lastEquippedItem = ThePlayer._lastEquippedItem
                local foundItem = player.components.inventory:FindItem(function(item)
                    return item == lastEquippedItem
                end)
                -- 如果上一个物品仍在物品栏或背包内，则进行切换
                if foundItem then
                    print("3==============================="..tostring(ThePlayer._lastEquippedItem))
                    ThePlayer._secondLastEquippedItem = currentEquipped
                    ThePlayer.components.inventory:Equip(foundItem)
                    ThePlayer._lastEquippedItem = player._secondLastEquippedItem
                else
                    print("Last equipped item is no longer in inventory.")
                end
            else
                print("4==============================="..tostring(ThePlayer._lastEquippedItem))
                ThePlayer._lastEquippedItem = currentEquipped
            end
        end
        if player and player.components.inventory then
            -- ThePlayer.replica.inventory
            print("1=1==============================")
            -- 获取当前手持物品
            local currentEquipped = player.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            print("2=1=============================="..tostring(currentEquipped))
            -- 如果有上一次使用的物品
            if player._lastEquippedItem and player._lastEquippedItem ~= currentEquipped then
                -- 判断上一个物品是否还在物品栏或背包内
                local lastEquippedItem = player._lastEquippedItem
                local foundItem = player.components.inventory:FindItem(function(item)
                    return item == lastEquippedItem
                end)
                -- 如果上一个物品仍在物品栏或背包内，则进行切换
                if foundItem then
                    print("3=1=============================="..tostring(player._lastEquippedItem))
                    player._secondLastEquippedItem = currentEquipped
                    player.components.inventory:Equip(foundItem)
                    player._lastEquippedItem = player._secondLastEquippedItem
                else
                    print("Last equipped item is no longer in inventory.")
                end
            else
                print("4=1=============================="..tostring(player._lastEquippedItem))
                player._lastEquippedItem = currentEquipped
            end
        end
    end


    AddModRPCHandler("Last Use Item", "RPCSetLastItem", RPCSetLastItem)

    -- 注册输入监听
    --TheInput:AddKeyHandler("ToggleLastItem")
    --TheInput:AddKeyHandler("ToggleLastItem", OnKeyDown)

    -- AddComponentPostInit("inventoryitem", function(item)
    --     if item.prefab == "yellowamulet" then
    --         item:ListenForEvent("onbreak", OnAmuletBreak)
    --     end
    -- end)
end

-- 深度打印函数
local function deepPrint(tbl, indent)
    local indent = indent or ""
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            print(indent .. tostring(k) .. ":")
            deepPrint(v, indent .. "  ")
        elseif type(v) == "function" then
            print(indent .. tostring(k) .. ": <function>")
        else
            print(indent .. tostring(k) .. ": " .. tostring(v))
        end
    end
end


function PrintInventoryItems()
    local Player = GLOBAL.ThePlayer
    print(GLOBAL.debug.getmetatable(Player))
    print(tostring(Player))
    print("----------------------------------------------------------")
    --local metatable = GLOBAL.debug.getmetatable(Player)
    --if metatable then
    --    print("Metatable of Player:")
    --    deepPrint(metatable, "  ")
    --else
    --    print("No metatable found for Player")
    --end
    local inventory = Player and Player.replica.inventory
    if inventory then
        print("Player Inventory1 Items:")
        for i, v in pairs(inventory) do
            if v then
                print(i, v)
            end
        end
    else
        print("Player does not have an inventory component.")
    end
    if Player then
        print('.......'..tostring(Player.components.inventory))
        if Player.components.inventory then
            print("Player Inventory2 Items:")
            for i, v in pairs(inventory.itemslots) do
                if v then
                    print(i, v.prefab)
                end
            end
        else
            print("Player does not have an inventory component.")
        end
    end
end

function SwapToLastEquippedItem()
    local Player = GLOBAL.ThePlayer
    print(GLOBAL.debug.getmetatable(Player))
    if Player and Player.replica.inventory and Player.replica.inventory.equipslots then
        -- ThePlayer.replica.inventory
        print("===============================")
        -- 获取当前手持物品
        local currentEquipped = Player.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        print("==============================="..tostring(currentEquipped))
        -- 如果有上一次使用的物品
        if Player._lastEquippedItem and Player._lastEquippedItem ~= currentEquipped then
            -- 判断上一个物品是否还在物品栏或背包内
            local lastEquippedItem = Player._lastEquippedItem
            local foundItem = Player.replica.inventory:FindItem(function(item)
                return item == lastEquippedItem
            end)
            -- 如果上一个物品仍在物品栏或背包内，则进行切换
            if foundItem then
                Player._secondLastEquippedItem = currentEquipped
                Player.components.inventory:Equip(foundItem)
                Player._lastEquippedItem = Player._secondLastEquippedItem
            else
                print("Last equipped item is no longer in inventory.")
            end
        end
    end
end


function SwapToLastEquippedItem_new()
    local Player = GLOBAL.ThePlayer
    local  debug_str = Player:GetDebugString()
    print(debug_str)
    print(GLOBAL.debug.getmetatable(Player))
    local inventory = Player.replica.inventory
    if inventory ~= nil and inventory:IsVisible() then
        local hot_key_num = 1
        local item = inventory:GetItemInSlot(hot_key_num)
        if item ~= nil then
            Player.replica.inventory:UseItemFromInvTile(item)
        end
        Player.components.inventory:SwapEquipment(item, EQUIPSLOTS.HANDS)
    end
end
