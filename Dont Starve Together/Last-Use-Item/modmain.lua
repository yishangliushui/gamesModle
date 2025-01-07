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
            if key == useHotkey then
                SwapToLastEquippedItem()
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
    print("【【【【启动-服务端-重新初始化")
    AddPrefabPostInit("yellowamulet", function(inst)
        if not GLOBAL.TheWorld.ismastersim then
            return
        end
        if inst.components.fueled then
            inst.components.fueled:SetDepletedFn(yishang_onunequip_yellow)
        end
    end)
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

    local inventory = Player and Player.components.inventory
    print(GLOBAL.debug.getmetatable(Player.components))

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
    local Player = GLOBAL.ThePlayer
    print(GLOBAL.debug.getmetatable(Player))
    print(Player)
    print(Player.components)
    print(Player.components.inventory)
    print("?????????")
    for i,v in ipairs(GLOBAL.AllPlayers) do
        print(i, v)
        print("=========")
        for k, g in pairs(v) do
            print(k, g)
        end
        print("=========")
    end
    print("?????????")
    if Player and Player.components then
        print("Available components:")
        for k, v in pairs(Player.components) do
            print(k)
        end
    else
        print("Player or Player.components is nil")
    end
    if Player and Player.components.inventory and Player.components.inventory.equipslots then
        -- ThePlayer.replica.inventory
        print("===============================")
        -- 获取当前手持物品
        local currentEquipped = Player.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        print("==============================="..tostring(currentEquipped))
        -- 如果有上一次使用的物品
        if Player._lastEquippedItem and Player._lastEquippedItem ~= currentEquipped then
            -- 判断上一个物品是否还在物品栏或背包内
            local lastEquippedItem = Player._lastEquippedItem
            local foundItem = Player.components.inventory:FindItem(function(item)
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
