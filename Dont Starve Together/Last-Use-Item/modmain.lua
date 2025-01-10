GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})
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


local modname = "Last Use Item"

local function printString(data, str, count)
    -- 初始化默认值
    if count == nil then
        count = 5
    end
    if str == nil then
        str = ""
    end

    -- 构建字符串的辅助函数
    local function buildString(data, count, indent)
        indent = indent or ""
        if type(data) == "table" and count < 6 then
            local temp = {}
            for i, k in pairs(data) do
                if type(i) == "number" then
                    table.insert(temp, string.format("%s%s", indent .. "  ", buildString(k, count + 1, indent .. "  ")))
                else
                    table.insert(temp, string.format("%s%s=%s", indent .. "  ", tostring(i), buildString(k, count + 1, indent .. "  ")))
                end
            end
            return "{\n" .. table.concat(temp, ",\n") .. "\n" .. indent .. "}"
        elseif type(data) == "function" then
            return tostring(data)
        else
            return tostring(data)
        end
    end

    -- 构建最终的输出字符串
    local output = string.format("[%s][%s]...data=%s", "", str, buildString(data, count, ""))

    -- 打印输出
    print(output)
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
    printString("已启用的Mod: "..name..k, "mod_")
    GetConfig()
end

-- MOD是否开启
function IsModEnable(name)
    return modIndex[name] ~= nil or enablemods[name] ~= nil
end


if IsModEnable(modname) then
    local useHotkeyEable = GetModConfigData("useHotkeyEable")
    local useHotkey = GetModConfigData("useHotkey")
    local moreEable = GetModConfigData("moreEable")

    if useHotkeyEable == 0 then
        return
    end

    -- 添加监听事件
    function AddInputHandler(handler)
        GLOBAL.TheInput:AddKeyDownHandler(function(key, down)
            handler(key, down, "keyboard")
        end)

        GLOBAL.TheInput:AddMouseButtonHandler(function(key, down)
            handler(key, down, "mouse")
        end)
    end

    AddInputHandler(function(key, down, inputType)
        printString(inputType.." key: "..key.." down: "..tostring(down), "handler_")
        if down then
            if key == useHotkey then
                --SendModRPCToServer(MOD_RPC["Last Use Item"]["RPCSetLastItem"])
                --SwapToLastEquippedItem()
                SwapToLastEquippedItem(moreEable)
            elseif key == 1006 then
                -- 其他逻辑
                OneClickHeal()
            end
        end
    end)


    function OnEquip(inst, equipInst)
        printString(equipInst, "OnEquip_equipInst_")
        if equipInst and equipInst.prefab then
            inst._lastEquippedItem = equipInst
            return
        end
    end


    AddPlayerPostInit(function(inst)
        printString("添加事件"..tostring(GLOBAL.TheWorld.ismastersim))
        -- 确保监听器只添加一次
        if not inst.onequip_swap_listener_added then
            inst:ListenForEvent("equip", OnEquip)
            inst.onequip_swap_listener_added = true
        end
    end)


    local function RPCSetLastItem(player)
        printString(player, "收到客户端的请求。。。。。。")
    end

    AddModRPCHandler(modname, "RPCSetLastItem", RPCSetLastItem)

end

function OneClickHeal()
    local Player = GLOBAL.ThePlayer
    if Player or Player.replica or Player.replica.inventory then
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
                        Player:PushAction(GLOBAL.InvAction(item, "EAT"))
                    end
                end
            end
        end
    end
end


function SwapToLastEquippedItem(moreEable)
    local Player = GLOBAL.ThePlayer
    local debug_str = Player:GetDebugString()
    printString(debug_str, "Player_")
    local inventory = Player.replica.inventory
    printString(inventory, "inventory_")
    -- 获取当前手持物品
    if inventory ~= nil and inventory:IsVisible() then
        local currentEquipped = inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if currentEquipped ~= nil then
            print("_____"..currentEquipped:GetDebugString())
        end
        local lastEquippedItem = Player._lastEquippedItem
        if lastEquippedItem ~= nil then
            -- 假设 lastEquippedItem 是物品的唯一标识符（如物品名或ID）
            local notSourceItem
            local foundItems = inventory:GetItems()
            if foundItems ~= nil then
                for index, item in pairs(foundItems) do
                    -- 检查每个物品是否与 lastEquippedItem 匹配
                    -- 这里假设可以用 item.name
                    if item ~= nil then
                        print("index="..index.."|item.name"..item.name.."|lastEquippedItem.name"..lastEquippedItem.name.."lastEquippedItem==item="..tostring(lastEquippedItem==item))
                        if item == lastEquippedItem then
                            -- 使用找到的物品
                            Player._lastEquippedItemCount = 1
                            inventory:UseItemFromInvTile(lastEquippedItem)
                            Player._lastEquippedItem = currentEquipped
                            return
                        end
                        if item.name == lastEquippedItem.name then
                            notSourceItem = item
                        end
                    end
                end
            end

            -- 如果在主物品栏中没有找到，则检查body容器中的物品
            local overflowContainer = inventory:GetOverflowContainer()
            printString(overflowContainer:GetItems(), "__overflowContainer_______3", 1)

            if overflowContainer ~= nil then
                local overflowItems =overflowContainer:GetItems()
                if overflowItems ~= nil then
                    for index, item in pairs(overflowItems) do
                        if item ~= nil then
                            print("index="..index.."|item.name"..item.name.."|lastEquippedItem.name"..lastEquippedItem.name.."lastEquippedItem==item="..tostring(lastEquippedItem==item))
                            if item == lastEquippedItem then
                                -- 使用找到的物品
                                Player._lastEquippedItemCount = 1
                                inventory:UseItemFromInvTile(lastEquippedItem)
                                Player._lastEquippedItem = currentEquipped
                                return
                            end
                            if item.name == lastEquippedItem.name then
                                notSourceItem = item
                            end
                        end
                    end
                end
            end
            if notSourceItem ~= nil then
                inventory:UseItemFromInvTile(notSourceItem)
                Player._lastEquippedItem = currentEquipped
                Player._lastEquippedItemCount = 1
                Player.replica.talker:Say(MESSAGE_STRING.notSourceItem, 3)
                return
            end
            if Player._lastEquippedItemCount ~= nil then
                Player._lastEquippedItemCount = 1
            end
            Player._lastEquippedItem = currentEquipped

            if moreEable then
                Player._lastEquippedItemCount = Player._lastEquippedItemCount + 1
                if Player._lastEquippedItemCount < 5 then
                    Player.replica.talker:Say(MESSAGE_STRING.notLastItem, 3)
                elseif Player._lastEquippedItemCount == 5 then
                    Player.replica.talker:Say(MESSAGE_STRING.notAngryItem, 3)
                elseif Player._lastEquippedItemCount > 5 then
                    -- 定时任务 持续5秒 每秒掉血和san值5点
                    -- 启动定时任务，持续5秒，每秒减少生命值和理智值
                    Player.replica.talker:Say(MESSAGE_STRING.notAngryIng, duration)
                    Player._lastEquippedItemCount = 0
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
