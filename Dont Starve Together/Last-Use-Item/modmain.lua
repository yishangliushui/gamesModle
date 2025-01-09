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
    if count ~= nil then
        count = 1
    end
    if type(data) == "table" then
        for i, k in pairs(data) do
            print(modname .. "_" .. str .. "|count=" .. count .. "_...i=" .. tostring(i) .. "|k=" .. tostring(k))
            if count < 5 then
                printString(k, str .. "_k", count + 1)
            end
        end
    elseif type(data) == "function" then
        print(modname .. "_" .. str .. "count=" .. count .. "_...function" .. tostring(data))
    else
        print(modname .. "_" .. str .. "count=" .. count "_...data=" .. tostring(data))
    end
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
end

-- MOD是否开启
function IsModEnable(name)
    return modIndex[name] ~= nil or enablemods[name] ~= nil
end


if IsModEnable(modname) then
    local useHotkeyEable = GetModConfigData("useHotkeyEable")
    local useHotkey = GetModConfigData("useHotkey")

    if useHotkeyEable == 0 then
        return
    end

    -- 添加监听事件
    function AddInputHandler(handler)
        GLOBAL.TheInput:AddKeyHandler(function(key, down)
            handler(key, down, "keyUp")
        end)
        --GLOBAL.TheInput:AddMouseButtonHandler(function(key, down)
        --    handler(key, down, "mouse")
        --end)
    end

    AddInputHandler(function(key, down, inputType)
        printString(inputType.." key: "..key.." down: "..tostring(down), "handler_")
        if down then
            if key == useHotkey then
                --SendModRPCToServer(MOD_RPC["Last Use Item"]["RPCSetLastItem"])
                --SwapToLastEquippedItem()
                SwapToLastEquippedItem_new()
            elseif key == GLOBAL.KEY_RIGHTBRACKET then
                -- 其他逻辑
            end
        end
    end)

    function OnEquip(inst, equipInst)
        printString(inst, "OnEquip_inst_")
        printString(equipInst, "OnEquip_equipInst_")
        if equipInst and equipInst.prefab then
            inst._lastEquippedItem = equipInst
            return
        end
        local currentEquipped = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        inst._lastEquippedItem = currentEquipped
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
    local inventory = Player.replica.inventory
    if inventory ~= nil and inventory:IsVisible() then
        -- 获取物品栏中的所有物品
        local items = inventory:GetItems()

        -- 初始化变量存储最佳食物物品
        local bestFoodItem = nil
        local maxHealthGain = 0

        -- 遍历所有物品，寻找加血最多的食物，排除曼德拉相关物品、眼球和犀牛角
        for _, item in pairs(items) do
            if item ~= nil then
                -- 跳过当前循环
                goto continue
            end
            if item.components.edible ~= nil and item.components.edible.healthvalue > 0 then
                local itemName = item.prefab
                if itemName ~= "mandra" and itemName ~= "mandra_meat" and itemName ~= "eyeball" and itemName ~= "rhino_horn" then
                    if item.components.edible.healthvalue > maxHealthGain then
                        bestFoodItem = item
                        maxHealthGain = item.components.edible.healthvalue
                    end
                end
            end
        end

        -- 如果找到最佳食物物品，则食用它
        if bestFoodItem ~= nil then
            Player:PushAction(GLOBAL.InvAction(bestFoodItem, "EAT"))
        end
    end
end


function SwapToLastEquippedItem_new()
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
            local foundItems = inventory:GetItems()
            for index, item in pairs(foundItems) do
                -- 检查每个物品是否与 lastEquippedItem 匹配
                -- 这里假设可以用 item.name
                print("index="..index.."|item.name"..item.name.."|lastEquippedItem.name"..lastEquippedItem.name.."lastEquippedItem==item="..tostring(lastEquippedItem==item))
                if item.name == lastEquippedItem.name then
                    -- 使用找到的物品
                    Player.replica.inventory:UseItemFromInvTile(lastEquippedItem)
                    Player._lastEquippedItem = currentEquipped
                    break
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
