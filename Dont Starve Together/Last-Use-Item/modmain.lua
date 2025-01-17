GLOBAL.setmetatable(env, { __index = function(t, k)
    return GLOBAL.rawget(GLOBAL, k)
end })
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
local MOD_RPC = GLOBAL.MOD_RPC
local MESSAGE_STRING = require "lastUseItem"
local utils = require "utils"

local modname = "Last Use Item"
local serverModname = "Amulet-Doesn't-Disappear"

local defaultValue = 99999

local amuletNeck = { "amulet", "blueamulet", "purpleamulet", "orangeamulet", "greenamulet", "yellowamulet" }
local lightTable = {"torch", "lantern", "minerhat", "morningstar", "yellowamulet"}

local debugBoolean = true

local function printString(data, str, uuid, count)
    return utils.printStringDebug(data, str, uuid, debugBoolean, count)
end

-- 获取是客服端还是服务端
if TheNet:GetIsClient() then
    printString("启动-客户端")
elseif TheNet:GetIsServer() then
    printString("启动-服务端")
end

local moddir = KnownModIndex:GetModsToLoad(true)
local enablemods = {}
local modIndex = {}

for k, dir in pairs(moddir) do
    local info = KnownModIndex:GetModInfo(dir)
    local name = info and info.name or "unknow"
    enablemods[dir] = name
    modIndex[name] = dir
    printString("已启用的Mod: " .. name .. k, "mod_")
end

-- MOD是否开启
local function IsModEnable(name)
    return modIndex[name] ~= nil or enablemods[name] ~= nil
end

if IsModEnable(modname) then
    local useHotkeyEable = GetModConfigData("useHotkeyEable")
    if useHotkeyEable == 0 then
        return
    end
    local useLastHotkey = GetModConfigData("useLastHotkey")
    local moreEable = GetModConfigData("moreEable")

    local axeHotkey_1 = GetModConfigData("axeHotkey_1")
    local axeHotkey_2 = GetModConfigData("axeHotkey_2")

    local mattockHotkey_1 = GetModConfigData("mattockHotkey_1")
    local mattockHotkey_2 = GetModConfigData("mattockHotkey_2")

    local shovelHotkey_1 = GetModConfigData("shovelHotkey_1")
    local shovelHotkey_2 = GetModConfigData("shovelHotkey_2")

    local hammerHotkey_1 = GetModConfigData("hammerHotkey_1")
    local hammerHotkey_2 = GetModConfigData("hammerHotkey_2")
    --  [[斧子 (Axe) 稿子  铲子 (Shovel) 锤子--]]

    local amuletHotkey_1 = GetModConfigData("amuletHotkey_1")
    local amuletHotkey_2 = GetModConfigData("amuletHotkey_2")

    local lightHotkey_1 = GetModConfigData("lightHotkey_1")
    local lightHotkey_2 = GetModConfigData("lightHotkey_2")

    local function addValue(includeArray, value)
        if value ~= nil and value ~= defaultValue then
            includeArray[value] = value
        end
    end

    local includeArray = {}
    addValue(includeArray, axeHotkey_1)
    addValue(includeArray, axeHotkey_2)
    addValue(includeArray, mattockHotkey_1)
    addValue(includeArray, mattockHotkey_2)
    addValue(includeArray, shovelHotkey_1)
    addValue(includeArray, shovelHotkey_2)
    addValue(includeArray, hammerHotkey_1)
    addValue(includeArray, hammerHotkey_2)
    addValue(includeArray, amuletHotkey_1)
    addValue(includeArray, amuletHotkey_2)

    local keyStates = {}
    --keyStates[defaultValue] = true

    -- 添加监听事件
    local function AddInputHandler(handler)
        GLOBAL.TheInput:AddKeyHandler(function(key, down)
            handler(key, down, "keyboard")
        end)

        GLOBAL.TheInput:AddMouseButtonHandler(function(key, down)
            handler(key, down, "mouse")
        end)
    end

    AddInputHandler(function(key, down, inputType)
        local uuid = utils.genUUID()
        local function OneClickHeal()
            local Player = GLOBAL.ThePlayer
            if Player == nil or Player.replica == nil or Player.replica.inventory == nil then
                return
            end
            local inventory = Player.replica.inventory
            if inventory:IsVisible() then
                -- 获取物品栏中的所有物品
                local items = inventory:GetItems()
                if items ~= nil then
                    for _, item in pairs(items) do
                        if item ~= nil then
                            local itemName = item.prefab
                            if itemName ~= "mandra" and itemName ~= "mandra_meat" and itemName ~= "eyeball" and itemName ~= "rhino_horn" then
                                --Player:PushAction(GLOBAL.InvAction(item, "EAT"))
                            end
                        end
                    end
                end
            end
        end

        local function SwapToolEquippedItem(player, equippedItem, currentEquipped, toolName)
            if equippedItem ~= nil then
                local Items = equippedItem:GetItems()
                if Items == nil then
                    return false
                end
                for index, item in pairs(Items) do
                    if item ~= nil then
                        printString("index=" .. index .. "|item.name" .. item.name, "SwapToolEquippedItem" .. toolName, uuid, 1)
                        if item:HasTag(toolName) then
                            player.replica.inventory:UseItemFromInvTile(item)
                            --player._lastEquippedItem = currentEquipped
                            return true
                        end
                    end
                end
            end
            return false
        end

        local function SwapWeaponEquippedItem(player, equippedItem, currentEquipped, lastEquippedItem, equipType)
            if equippedItem == nil then
                return nil, false
            end
            local items = equippedItem:GetItems()
            local notSourceItem
            if items ~= nil then
                for index, item in pairs(items) do
                    -- 检查每个物品是否与 lastEquippedItem 匹配
                    -- 这里假设可以用 item.name
                    if item ~= nil then
                        printString("index=" .. index .. "|item.name" .. item.name .. "|lastEquippedItem.name" .. lastEquippedItem.name .. "lastEquippedItem==item=" .. tostring(lastEquippedItem == item) .. "|equipType=" .. equipType, "SwapWeaponEquippedItem", uuid, 1)
                        if item == lastEquippedItem then
                            -- 使用找到的物品
                            player.replica.inventory:UseItemFromInvTile(lastEquippedItem)
                            if equipType == EQUIPSLOTS.HANDS then
                                player._lastEquippedItemCount = 1
                                player._lastEquippedItem = currentEquipped
                            else
                                player._lastAmuletEquippedItemCount = 1
                                player._lastAmuletEquippedItem = currentEquipped
                            end
                            return nil, true
                        end
                    end
                end
            end
            return notSourceItem, false
        end

        local function SwapToolsEquippedItem(toolName)
            local Player = GLOBAL.ThePlayer
            if Player == nil or Player.replica == nil or Player.replica.inventory == nil then
                return
            end
            local overflowContainer = Player.replica.inventory:GetOverflowContainer()
            local currentEquipped = Player.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            -- 遍历库存和背包（如果存在），寻找指定的物品，记录上一次使用的物品
            for _, item in pairs(Player.replica.inventory and {overflowContainer, Player.replica.inventory} or {overflowContainer}) do
                local swapSuccess = SwapToolEquippedItem(Player, item, currentEquipped, toolName)
                if swapSuccess then
                    return
                end
            end
        end

        local function SwapHandsOrNeckEquippedItem(equipType)
            local Player = GLOBAL.ThePlayer
            if Player == nil or Player.replica == nil or Player.replica.inventory == nil then
                return
            end
            local inventory = Player.replica.inventory
            if inventory ~= nil and inventory:IsVisible() then
                local currentEquipped
                local lastEquippedItem
                if EQUIPSLOTS.HANDS == equipType then
                    currentEquipped = inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
                    lastEquippedItem = Player._lastEquippedItem
                else
                    currentEquipped = inventory:GetEquippedItem(equipType)
                    printString("lastEquippedItem.prefab=" .. tostring(lastEquippedItem.prefab), "SwapHandsOrNeckEquippedItem", uuid, 1)
                    if currentEquipped == nil or currentEquipped.prefab ~= "amulet" then
                        currentEquipped = nil
                    end
                    lastEquippedItem = Player._lastAmuletEquippedItem
                end
                if lastEquippedItem ~= nil then
                    local notSourceItem
                    local overflowContainer = inventory:GetOverflowContainer()
                    for _, item in pairs(Player.replica.inventory and {overflowContainer, Player.replica.inventory} or {overflowContainer}) do
                        local notSourceItemContainer, swapSuccess = SwapWeaponEquippedItem(Player, item, currentEquipped, lastEquippedItem, equipType, uuid)
                        if swapSuccess then
                            return
                        end
                        if notSourceItem == nil then
                            notSourceItem = notSourceItemContainer
                        end
                    end

                    if notSourceItem ~= nil then
                        inventory:UseItemFromInvTile(notSourceItem)
                        if equipType == EQUIPSLOTS.HANDS then
                            Player._lastEquippedItemCount = 1
                            Player._lastEquippedItem = currentEquipped
                        else
                            Player._lastAmuletEquippedItemCount = 1
                            Player._lastAmuletEquippedItem = currentEquipped
                        end
                        --SendModRPCToServer(MOD_RPC[serverModname]["talkerSayString"], MESSAGE_STRING.notSourceItem, 3)
                        return
                    end
                    if Player._lastEquippedItemCount == nil then
                        Player._lastEquippedItemCount = 1
                    end
                    if Player._lastAmuletEquippedItemCount == nil then
                        Player._lastAmuletEquippedItemCount = 1
                    end

                    if moreEable then
                        local count = 0
                        if equipType == EQUIPSLOTS.HANDS then
                            Player._lastEquippedItemCount = Player._lastEquippedItemCount + 1
                            count = Player._lastEquippedItemCount
                        else
                            Player._lastAmuletEquippedItem = Player._lastAmuletEquippedItem + 1
                            count = Player._lastAmuletEquippedItemCount
                        end

                        if count < 5 then
                            SendModRPCToServer(GLOBAL.MOD_RPC[serverModname]["talkerSayString"], MESSAGE_STRING.notLastItem, 3)
                        elseif count == 5 then
                            SendModRPCToServer(MOD_RPC[serverModname]["talkerSayString"], MESSAGE_STRING.notAngryItem, 3)
                        elseif count > 5 then
                            -- 定时任务 持续5秒 每秒掉血和san值5点
                            -- 启动定时任务，持续5秒，每秒减少生命值和理智值
                            SendModRPCToServer(MOD_RPC[serverModname]["talkerSayString"], MESSAGE_STRING.notAngryIng, 5)
                            if equipType == EQUIPSLOTS.HANDS then
                                Player._lastEquippedItemCount = 0
                            else
                                Player._lastAmuletEquippedItemCount = 0
                            end
                            if Player.angryIngBool == nil or not Player.angryIngBool then
                                local damagePerSecond = 5
                                local sanityDamagePerSecond = 5
                                local duration = 5 -- 持续5秒
                                Player.angryIngBool = true
                                for i = 1, duration do
                                    Player:DoTaskInTime(i, function()
                                        if Player and Player.replica.health and Player.components.sanity then
                                            Player.replica.health:DoDelta(-damagePerSecond)
                                            Player.replica.sanity:DoDelta(-sanityDamagePerSecond)
                                        end
                                        if i == duration then
                                            Player.angryIngBool = false
                                        end
                                    end)
                                end
                            end
                        end
                    end

                    --local hot_key_num = 1
                    --local item = inventory:GetItemInSlot(hot_key_num)
                    --if item ~= nil then
                    --    Player.replica.inventory:UseItemFromInvTile(item)
                    --end
                else
                    Player._lastEquippedItem = currentEquipped
                end
            end
        end

        local function SwapAmuletsEquippedItem()
            if EQUIPSLOTS.NECK ~= nil then
                SwapHandsOrNeckEquippedItem(EQUIPSLOTS.NECK)
            else
                SwapHandsOrNeckEquippedItem(EQUIPSLOTS.BODY)
            end
        end

        local function SwapToLastEquippedItem()
            SwapHandsOrNeckEquippedItem(EQUIPSLOTS.HANDS)
        end

        local function SwapLightEquippedItem(toolName)
            local Player = GLOBAL.ThePlayer
            if Player == nil or Player.replica == nil or Player.replica.inventory == nil then
                return
            end
            local overflowContainer = Player.replica.inventory:GetOverflowContainer()
            local currentEquipped = Player.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            -- 遍历库存和背包（如果存在），寻找指定的物品预设
            for _, equippedItem in pairs(Player.replica.inventory and {overflowContainer, Player.replica.inventory} or {overflowContainer}) do
                if equippedItem ~= nil then
                    local Items = equippedItem:GetItems()
                    if Items == nil then
                        return false
                    end
                    for index, item in pairs(Items) do
                        if item ~= nil then
                            printString("index=" .. index .. "|item.name=" .. item.name .. "|item.prefab=" .. item.prefab, "SwapToolEquippedItem_" .. toolName, uuid)
                            if utils.isContainValue(lightTable, item.prefab) then
                                player.replica.inventory:UseItemFromInvTile(item)
                                --player._lastEquippedItem = currentEquipped
                                return true
                            end
                        end
                    end
                end
            end
        end

        local function isOtherValid(hotKey)
            for _, item in pairs(includeArray) do
                if item ~= nill and hotKey ~= nill and hotKey ~= defaultValue and item ~= hotKey and keyStates[item] then
                    return true
                end
            end
            return false
        end

        printString("inputType=" .. inputType .. " |key: " .. key .. " |down: " .. tostring(down), "AddInputHandler", uuid)

        if includeArray[key] == nil then
            return
        end

        if keyStates[key] and down then
            printString("当前按键还未释放，不执行。", "AddInputHandler", uuid)
            return
        end
        -- 记录组合键
        keyStates[key] = down
        printString(keyStates, "keyStates_" .. inputType, uuid,1)
        --printString(includeArray, "includeArray_" .. inputType, uuid, 1)
        if down then
            printString(tostring(isOtherValid(useLastHotkey)).. "__"..tostring(keyStates[useLastHotkey]).."|useLastHotkey|"..useLastHotkey, "", uuid)
            if not isOtherValid(useLastHotkey) and keyStates[useLastHotkey] then
                SwapToLastEquippedItem(moreEable)
                --elseif isOtherValid(useLastHotkey) and keyStates[axeHotkey_1] then
                --    OneClickHeal()
            elseif keyStates[axeHotkey_1] and keyStates[axeHotkey_2] then
                SwapToolsEquippedItem(ACTIONS.CHOP.id .. "_tool")
            elseif keyStates[mattockHotkey_1] and keyStates[mattockHotkey_2] then
                SwapToolsEquippedItem(ACTIONS.MINE.id .. "_tool")
            elseif keyStates[shovelHotkey_1] and keyStates[shovelHotkey_2] then
                SwapToolsEquippedItem(ACTIONS.DIG.id .. "_tool")
            elseif keyStates[hammerHotkey_1] and keyStates[hammerHotkey_2] then
                SwapToolsEquippedItem(ACTIONS.HAMMER.id .. "_tool")
            elseif keyStates[amuletHotkey_1] and keyStates[amuletHotkey_2] then
                SwapAmuletsEquippedItem()
            elseif keyStates[lightHotkey_1] and keyStates[lightHotkey_2] then
                SwapLightEquippedItem()
            end
        end
    end)

    local function OnEquip(inst, equipInst)
        local uuid = utils.genUUID()
        if equipInst and equipInst.prefab then
            printString(equipInst, "OnEquip", uuid,3)
            printString(equipInst.prefab, "equipInst.prefab", uuid,3)
            if equipInst.prefab == "amulet" then
                inst._lastAmuletEquippedItem = equipInst
            elseif equipInst:HasTag("weapon") then
                inst._lastEquippedItem = equipInst
            elseif equipInst.equipslot == EQUIPSLOTS.HANDS then
                inst._lastEquippedItem = equipInst
            end
        end
    end

    AddPlayerPostInit(function(inst)
        printString(tostring(GLOBAL.TheWorld.ismastersim), "添加事件")
        -- 确保监听器只添加一次
        if not inst.onequip_swap_listener_added then
            inst:ListenForEvent("equip", OnEquip)
            inst.onequip_swap_listener_added = true
        end
    end)

    --SendModRPCToServer(MOD_RPC["Last Use Item"]["RPCSetLastItem"])
    local function RPCSetLastItem(player)
        printString(player, "收到客户端的请求。。。。。。")
    end

    AddModRPCHandler(modname, "RPCSetLastItem", RPCSetLastItem)

    local function talkerSayString(player, text, continueTime)
        printString(player, "1收到客户端的请求。。。。。。" .. text .. "_" .. continueTime)
        if continueTime ~= nil then
            continueTime = 3
        end
        if player.components ~= nil and player.components.talker ~= nil then
            player.components.talker:Say(text, continueTime)
        end
    end

    AddModRPCHandler(serverModname, "talkerSayString", talkerSayString)
end