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

local utils = require("utils")

local modname = "organize-items"

local debugBoolean = true

local locked_items = {}

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
function IsModEnable(name)
    return modIndex[name] ~= nil or enablemods[name] ~= nil
end

if IsModEnable(modname) then
    local useHotkeyEable = GetModConfigData("useHotkeyEable", modname)

    if useHotkeyEable == 0 then
        return
    end

    local function MoveItemToContainer(player, item, chest)
        local inventory = player.components.inventory
        local startPos = Vector3(player.Transform:GetWorldPosition())
        local endPos = Vector3(chest.Transform:GetWorldPosition())

        -- 计算方向
        local direction = (endPos - startPos):GetNormalized()
        local distance = (endPos - startPos):Length()

        -- 设置速度
        local speed = 5  -- 每秒移动的距离
        local duration = distance / speed
        local timeElapsed = 0

        -- 创建一个新的实体来表示移动的物品
        --local movingItem = item:Clone()
        --movingItem.Transform:SetPosition(startPos:Get())
        --movingItem:AddTag("moving_item")

        local movingItem = item
        movingItem:AddTag("moving_item")

        --inventory:DropItem(item)

        -- 将物品从物品栏移除
        --inventory:RemoveItem(item)

        -- 更新函数
        local function Update(dt)
            timeElapsed = timeElapsed + dt
            if timeElapsed >= duration then
                -- 到达目的地
                if chest.components.container:GiveItem(movingItem, nil, player:GetPosition()) then
                    -- 打开容器
                    if chest.components.containeropener then
                        chest.components.containeropener:Open()
                    end
                else
                    -- 如果放置失败，将物品放回玩家物品栏
                    inventory:GiveItem(movingItem, nil, player:GetPosition())
                end
                --movingItem:Remove()
                return
            end

            -- 更新位置
            local t = timeElapsed / duration
            local newPos = startPos * (1 - t) + endPos * t
            movingItem.Transform:SetPosition(newPos:Get())

            -- 更新朝向
            movingItem.Transform:SetRotation(direction:GetAngle() + 90)
        end

        -- 注册更新函数
        movingItem:DoPeriodicTask(0.1, Update, nil, true)
    end

    local function SortInventoryToNearbyChests(player, uuid)
        local inventory = player.components.inventory
        local pos = player:GetPosition()
        --local nearby_entities = TheSim:FindEntities(pos.x, pos.y, pos.z, 5, { "chest" })

        local nearby_entities = TheSim:FindEntities(pos.x, pos.y, pos.z, 10, nil, {'NOBLOCK', 'player', 'FX' }) or {}
        if not nearby_entities or #nearby_entities == 0 then
            printString("没有找到附近的箱子", "", uuid)
            return
        end
        for i = inventory:NumItems(), 1, -1 do
            local item = inventory:GetItemInSlot(i)
            printString(item.prefab, "", uuid)
            if item and not locked_items[i] then
                for i, chest in pairs(nearby_entities) do
                    if chest and chest:IsValid() and chest.entity:IsVisible() and chest.components.container and not chest.components.container:IsBusy() then
                        local can_accept = chest.components.container:CanAcceptCount(item)
                        printString("[" .. tostring(i) .. "] Can accept count: " .. tostring(can_accept), "", uuid)
                        if can_accept > 0 then
                            if MoveItemToContainer(player, item, chest) then
                                break
                            end
                            --if chest.components.container:GiveItem(item, nil, player:GetPosition()) then
                            --    printString("[" .. tostring(i) .. "] Item placed in container at position:" .. chest:GetPosition(), "", uuid)
                            --    break
                            --end
                        end
                    end
                end
                printString("没有合适的箱子存放物品: " .. item.prefab, "", uuid)
            end
        end
    end

    --local function AddSortButton(screen)
    --    local button = screen:AddChild(ImageButton("path_to_button_texture", "path_to_button_hover_texture"))
    --    button:SetOnClick(SendModRPCToServer(GLOBAL.MOD_RPC[modname]["ItemCategory"]))
    --    button:SetPosition(0, -50) -- 调整按钮位置
    --end

    --AddClassPostConstruct("screens/playerhud", function(self)
    --    AddSortButton(self)
    --end)

    local category = GLOBAL.require("widgets/category") --加载hello类

    local function addCategoryWidget(self)
        self.category = self:AddChild(category())-- 为controls添加hello widget。
        self.category:SetHAnchor(0) -- 设置原点x坐标位置，0、1、2分别对应屏幕中、左、右
        self.category:SetVAnchor(1) -- 设置原点y坐标位置，0、1、2分别对应屏幕中、上、下
        self.category:SetPosition(70, -50, 0) -- 设置hello widget相对原点的偏移量，70，-50表明向右70，向下50，第三个参数无意义。
        self.category:SetOnClick(function()
            local uuid = utils.genUUID()
            printString("点击了分类按钮", "", uuid)
            SendModRPCToServer(GLOBAL.MOD_RPC[modname]["itemCategory"], uuid)
        end)
    end

    local function itemCategory(inst, uuid)
        if TheNet:GetIsServer() then
            if inst and inst.components and inst.components.inventory then
                SortInventoryToNearbyChests(inst, uuid)
            end
        end
    end

    AddModRPCHandler(modname, "itemCategory", itemCategory)

    AddClassPostConstruct("widgets/controls", addCategoryWidget) -- 这个函数是官方的MOD API，用于修改游戏中的类的构造函数。第一个参数是类的文件路径，根目录为scripts。第二个自定义的修改函数，第一个参数固定为self，指代要修改的类。

    local function ToggleLockItem(inventory, slot)
        locked_items[slot] = not locked_items[slot]
        -- 刷新物品栏显示
        inventory:Refresh()
    end

    local Widget = require("widgets/widget")
    local Button = require("widgets/button")
    local TextButton = require("widgets/textbutton")

    local function AddLockButton(inventory, slot)
        --local lockButton = Button("lock_button", "images/ui.xml", "lock.tex", "lock_down.tex")
        local lockButton = TextButton(BODYTEXTFONT, 30, "按钮")
        lockButton:SetPosition(10, 10, 0)  -- 设置按钮位置在右上角
        lockButton:SetText("锁定")
        lockButton:SetTextColour(1, 1, 1, 1)
        lockButton:SetOnClick(function()
            ToggleLockItem(inventory, slot)
        end)
        inventory.slots[slot]:AddChild(lockButton)
    end

    AddPlayerPostInit(function(player)
        local inventory = player.components.inventory
        for i = 1, inventory.numslots do
            AddLockButton(inventory, i)
        end
    end)
end

