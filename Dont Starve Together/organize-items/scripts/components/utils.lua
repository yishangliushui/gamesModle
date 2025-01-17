GLOBAL.setmetatable(env, { __index = function(t, k)
    return GLOBAL.rawget(GLOBAL, k)
end })

local os = GLOBAL.os

utils = utils or {}

--寻找数组中某个值的下标，仅在table中每个值都不一样时有效
utils.findIdxByValue = function(arr, value)
    local tempArr = arr
    local tempValue = value
    for i, v in ipairs(tempArr) do
        if v == tempValue then
            return i
        end
    end
end

-- 一维数组
utils.isContainValue = function(arr, value)
    for _, item in pairs(arr) do
        if item == value then
            return true
        end
    end
    return false
end

--将string转为table1
function utils.stringToTable(str, isTableList)
    if str == "" or str == nil then
        return {}
    end
    local ret, msg
    if isTableList then
        ret, msg = loadstring(string.format("return {%s}", str))
    else
        ret, msg = loadstring(string.format("return %s", str))
    end
    if not ret then
        LogManager:debugLog("原文内容 ", str)
        LogManager:debugLog("loadstring error", msg)
        return nil
    end
    return ret()
end

--根据分隔符分割字符串，返回分割后的table
utils.split = function(s, delim)
    if not s then
        return {}
    end
    assert(type(delim) == "string" and string.len(delim) > 0, "bad delimiter")
    local start = 1
    local t = {}
    while true do
        local pos = string.find(s, delim, start, true)
        if not pos then
            break
        end
        table.insert(t, string.sub(s, start, pos - 1))
        start = pos + string.len(delim)
    end
    table.insert(t, string.sub(s, start))
    return t
end


--获取两点之间的距离
utils.getDistance = function(pOne, pTwo)
    if not pOne then
        return 0
    end

    if not pTwo then
        return 0
    end

    local dx = pTwo.x - pOne.x
    local dy = pTwo.y - pOne.y

    return math.sqrt(dx * dx + dy * dy)
end

--四舍五入
utils.roundOff = function(num)
    local integer, decimal = math.modf(num)
    if decimal >= 0.5 then
        return integer + 1
    else
        return integer
    end
end

--保留两位小数
utils.reserveTwo = function(num)
    return tonumber(string.format("%.2f", num))
end

-- 是否中文字
utils.isCn = function(c)
    return c:byte() > 128
end

local uuidMap={'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f'}
local separator = {8,4,4,4,12}
--math.randomseed(tostring(os.clock()):sub(3,8):reverse() .. os.time())

utils.genUUID = function()
    local id = "_"
    for i,sepNum in ipairs(separator) do
        for j =1, sepNum do
            id = id .. (uuidMap[math.random(1, 16)])
        end
        if i < #separator then
            id = id .."-"
        end
    end
    return id
end

local timeFormat = "%Y-%m-%d %H:%M:%S"

utils.printStringDebug = function(data, str, uuid, debug, count)
    if debug == nil or not debug then
        return
    end
    if data == nil then
        return string.format("[%s][%s][%s]...data=%s", os.date(timeFormat), str, uuid, "")
    end
    -- 初始化默认值
    if count == nil then
        count = 5
    end
    if str == nil then
        str = ""
    end

    if uuid == nil then
        uuid = ""
    end
    uuid = tostring(uuid)
    -- 构建字符串的辅助函数
    local function buildString(data, count, indent)
        indent = indent or ""
        if type(data) == "table" and count < 6 then
            local temp = {}
            for i, k in pairs(data) do
                if type(i) == "number" then
                    table.insert(temp, string.format("%s%s=%s", indent .. "  ", tostring(i), buildString(k, count + 1, indent .. "  ")))
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
    local output = string.format("[%s][%s][%s]...data=%s", os.date(timeFormat), str, uuid, buildString(data, count, ""))

    -- 打印输出
    print(output)
end

return utils

