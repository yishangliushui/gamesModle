-- 名称
name = "Last Use Item"
-- 描述
description = "使用上一个使用的物品"
-- 作者
author = "yishang"
-- 版本
version = "0.1"
-- klei官方论坛地址，为空则默认是工坊的地址
forumthread = ""
-- modicon 下一篇再介绍怎么创建的
-- icon_atlas = "images/modicon.xml"
-- icon = "modicon.tex"
-- dst兼容
dst_compatible = true
dont_starve_compatible = true
-- 是否是客户端mod
client_only_mod = true
-- 是否是所有客户端都需要安装
all_clients_require_mod = false
-- 饥荒api版本，固定填10
api_version = 10

local default = 99999

-- 获取鼠标键位和常用键盘按键
local function getAllKeys()
    return {
        { description = "MOUSE_X1", data = 1005, hover = "侧键1" },
        { description = "MOUSE_X2", data = 1006, hover = "侧键2" },
        { description = "LEFT_CTRL", data = 306, hover = "左Ctrl" },
        { description = "LEFT_SHIFT", data = 304, hover = "左Shift" },
        { description = "关闭", data = default, hover = "关闭" }
    }
end

-- 调用函数以打印所有按键的键值
local keys = getAllKeys()

local function AddButton(name, label, df)
    configuration_options[#configuration_options + 1] = {
        name = name,
        label = label,
        options = keys,
        default = df,
    }
end

-- mod的配置项
configuration_options = {
    {
        name = "useHotkeyEable", -- 配置项名换，在modmain.lua里获取配置值时要用到
        hover = "是否开启", -- 鼠标移到配置项上时所显示的信息
        options = { {                    -- 配置项目可选项
                        description = "关闭", -- 可选项上显示的内容
                        hover = "关闭", -- 鼠标移动到可选项上显示的信息
                        data = 0
                    }, {
                        description = "开启", -- 可选项上显示的内容
                        hover = "开启", -- 鼠标移动到可选项上显示的信息
                        data = 1
                    } },
        default = 0                   -- 默认值，与可选项里的值匹配作为默认值
    }
}

AddButton("useLastHotkey", "手持使用上一个物品快捷键", default)
AddButton("axeHotkey_1", "斧子组合键1", default)
AddButton("axeHotkey_2", "斧子组合键2", default)
AddButton("mattockHotkey_1", "镐子组合键1", default)
AddButton("mattockHotkey_2", "镐子组合键2", default)
AddButton("shovelHotkey_1", "铲子组合键1", default)
AddButton("shovelHotkey_2", "铲子组合键2", default)
AddButton("hammerHotkey_1", "锤子组合键1", default)
AddButton("hammerHotkey_2", "锤子组合键2", default)
AddButton("amuletHotkey_1", "护符组合键2", default)
AddButton("amuletHotkey_2", "护符组合键2", default)

