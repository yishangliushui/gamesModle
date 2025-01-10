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

local modname = "Amulet-Doesn't-Disappear"

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
    printString("已启用的Mod: " .. name .. k, "mod_")
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

local function onunequip_yellow(inst, owner)
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

if IsModEnable(modname) then
    local useHotkeyEable = GetModConfigData("useHotkeyEable", modname)
    local useDays = GetModConfigData("useDays", modname)

    if useHotkeyEable == 0 then
        return
    end

    TUNING.YELLOWAMULET_FUEL = useDays * TUNING.YELLOWAMULET_FUEL

    --AddPrefabPostInit("yellowamulet", function(inst)
    --    printString("初始化yellowamulet")
    --    if not IsServer then
    --        return
    --    end
    --    if inst.components.fueled ~= nil then
    --        inst.components.fueled:SetDepletedFn(onunequip_yellow)
    --    end
    --end)

end

