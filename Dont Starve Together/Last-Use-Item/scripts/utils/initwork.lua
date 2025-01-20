--@author: 绯世行
--欢迎其他开发者直接使用，但是强烈谴责搬用代码后对搬用代码加密的行为！
--使用案例及最新版：https://n77a3mjegs.feishu.cn/docx/K9bUdpb5Qo85j2xo8XkcOsU1nuh?from=from_copylink

--初始化一些数据结构

local FN = {}
local _source = debug.getinfo(1, 'S').source
local KEY = "_" .. _source:match(".*scripts[/\\](.*)%.lua"):gsub("[/\\]", "_") .. "_"
local Utils = require(_source:match(".*scripts[/\\](.*[/\\])") .. "utils")

---虽然写了，但是感觉挺麻烦的，不如结合childspawner和entitytracker自定义个组件
---强化EntityTracker记录多对象的功能，后面追加索引的方式添加同类型对象，当前索引位置不存在对象时，从某位查找对象替代该位置
function FN.EnhanceEntitytrackerTrackEntity()
    local self = require("components/entitytracker")

    self[KEY .. "entList"] = {}

    self[KEY .. "TrackEntity"] = function(self, name, ent)
        local count = self[KEY .. "entList"][name]

        count = (count or 0) + 1
        self[KEY .. "entList"][name] = count

        self:TrackEntity(name .. tostring(count), ent)
    end

    self[KEY .. "ForeachEntity"] = function(self, name, fn)
        local count = self[KEY .. "entList"][name]
        if not count then return end
        local endIndex = count
        for i = 1, count do
            local ent = self:GetEntity(name .. tostring(count))
            if not ent then
                --交换位置
                while endIndex > i do
                    ent = self:GetEntity(name .. tostring(endIndex))
                    endIndex = endIndex - 1

                    if ent then
                        self:TrackEntity(name .. tostring(i), ent)
                        self:ForgetEntity(name .. tostring(endIndex + 1))
                        break
                    end
                end
            end

            if ent then
                fn(ent)
            else
                break
            end
        end

        self[KEY .. "entList"][name] = endIndex
    end
end

--- 修复Inventory的GetItemsWithTag方法bug，无法正确获取手上物品
function FN.RepairInventoryGetItemsWithTag()
    local Inventory = require("components/inventory")
    function Inventory:GetItemsWithTag(tag)
        local items = {}
        for k, v in pairs(self.itemslots) do
            if v and v:HasTag(tag) then
                table.insert(items, v)
            end
        end

        if self.activeitem and self.activeitem:HasTag(tag) then
            table.insert(items, self.activeitem) --修复这里
        end

        local overflow = self:GetOverflowContainer()
        if overflow ~= nil then
            local overflow_items = overflow:GetItemsWithTag(tag)
            for _, item in ipairs(overflow_items) do
                table.insert(items, item)
            end
        end

        return items
    end
end

---添加方法AddToHistoryCanRepeat(sender_name, message, colour, icondata, ...)，使其支持图标的同时还能显示重复内容
function FN.ChatHistoryAddToHistoryCanRepeat()
    function ChatHistory:AddToHistoryCanRepeat(sender_name, message, colour, icondata, ...)
        local old = self.NPC_CHATTER_MAX_CHAT_NO_DUPES
        self.NPC_CHATTER_MAX_CHAT_NO_DUPES = 0 --移除对重复内容的判断

        self:AddToHistory(ChatTypes.ChatterMessage, nil, nil, sender_name, message, colour, icondata, ...)

        self.NPC_CHATTER_MAX_CHAT_NO_DUPES = old
    end
end

local tempTagKey = "_tempTags"

---监听标签的添加和移除，并添加AddTempTag和RemoveTempTag两个方法支持临时标签
function FN.AddTempTagMethod()
    -- Utils.FnDecorator(EntityScript, "AddTag", function(self, tag) end)

    Utils.FnDecorator(EntityScript, "RemoveTag", function(self, tag)
        local tags = self[tempTagKey]
        if not tags or not tags[tag] then return end

        if tags[tag].isForbidRemove then return nil, true end

        tags[tag] = nil
        if GetTableSize(tags) <= 0 then
            self[tempTagKey] = nil
        end
    end)

    ---添加临时标签
    ---@param isForbidRemove boolean|nil 是否禁止使用RemoveTag移除该标签，默认为false，为true时只能使用RemoveTempTag来移除标签
    function EntityScript:AddTempTag(tag, isForbidRemove)
        self[tempTagKey] = self[tempTagKey] or {}
        self[tempTagKey][tag] = { isForbidRemove = isForbidRemove }
        self:AddTag(tag)
    end

    function EntityScript:RemoveTempTag(tag)
        local d = self[tempTagKey] and self[tempTagKey][tag]
        if d then
            d.isForbidRemove = nil
            self:RemoveTag(tag)
        end
    end
end

----------------------------------------------------------------------------------------------------

local TAG_VAR = "inst." .. KEY .. "_tags"

local function AddTagBefore(inst, tag)
    local key = string.lower(tag)
    if inst[TAG_VAR][key] then
        inst[TAG_VAR][key]:set(true)
        return nil, true
    end
end

local function RemoveTagBefore(inst, tag)
    local key = string.lower(tag)
    if inst[TAG_VAR][key] then
        inst[TAG_VAR][key]:set(false)
        -- return nil, true --有可能本身就有，继续执行
    end
end

local function HasTagBefore(inst, tag)
    local key = string.lower(tag)
    if inst[TAG_VAR][key] and inst[TAG_VAR][key]:value() then
        return { true }, true
    end
end

local function HasTagsBefore(inst, ...)
    local data = inst[TAG_VAR]

    local tags = select(1, ...)
    if type(tags) ~= "table" then
        tags = { ... }
    end

    local res = {}
    for _, t in ipairs(tags) do
        local key = string.lower(t)
        if not data[key] or not data[key]:value() then
            table.insert(res, t)
        end
    end

    if #res <= 0 then
        return { true }, true
    end
    return nil, false, { inst, unpack(res) }
end

local function HasOneOfTagsBefore(inst, ...)
    local data = inst[TAG_VAR]

    local tags = select(1, ...)
    if type(tags) ~= "table" then
        tags = { ... }
    end

    for _, t in ipairs(tags) do
        local key = string.lower(t)
        if data[key] and data[key]:value() then
            return { true }, true
        end
    end
end

--- 扩展标签上限
function FN.ExtendTag(inst, tags)
    inst[TAG_VAR] = {}
    for _, v in ipairs(tags) do
        v = string.lower(v)
        inst[TAG_VAR][v] = net_bool(inst.GUID, inst.prefab .. ".tag_" .. v)
    end

    Utils.FnDecorator(inst, "AddTag", AddTagBefore)
    Utils.FnDecorator(inst, "RemoveTag", RemoveTagBefore)
    Utils.FnDecorator(inst, "HasTag", HasTagBefore)
    Utils.FnDecorator(inst, "HasTags", HasTagsBefore)
    inst.HasAllTags = inst.HasTags
    Utils.FnDecorator(inst, "HasOneOfTags", HasOneOfTagsBefore)
    inst.HasAnyTag = inst.HasOneOfTags
end

--- 使含有drawable组件的物品（比如小木牌、画框）支持显示mod物品，要求是inventoryimages目录下的
function FN.RegisterDrawable()
    local MOD_ITEM_PRE = "images/inventoryimages/"
    local Drawable = require("components/drawable")
    Utils.FnDecorator(Drawable, "OnDrawn", nil,
        function(retTab, self, imagename, imagesource, atlasname)
            if atlasname and string.match(atlasname, "^" .. MOD_ITEM_PRE) then --非mod物品一般atlasname为空，而且也不可能有inventoryimages目录
                self.inst.AnimState:OverrideSymbol("SWAP_SIGN",
                    resolvefilepath(MOD_ITEM_PRE .. imagename .. ".xml"), imagename .. ".tex")
            end
        end)
end

return FN
