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
-- 是否是客户端mod
client_only_mod = true
-- 是否是所有客户端都需要安装
all_clients_require_mod = false
-- 饥荒api版本，固定填10
api_version = 10

-- 获取鼠标键位和常用键盘按键
local function getAllKeys()
    local keys = {
        { description = "ESCAPE", data = KEY_ESCAPE },
        { description = "1", data = KEY_1 }, { description = "2", data = KEY_2 }, { description = "3", data = KEY_3 }, { description = "4", data = KEY_4 }, { description = "5", data = KEY_5 }, { description = "6", data = KEY_6 }, { description = "7", data = KEY_7 }, { description = "8", data = KEY_8 }, { description = "9", data = KEY_9 }, { description = "0", data = KEY_0 },
        { description = "A", data = KEY_A }, { description = "B", data = KEY_B }, { description = "C", data = KEY_C }, { description = "D", data = KEY_D }, { description = "E", data = KEY_E }, { description = "F", data = KEY_F }, { description = "G", data = KEY_G }, { description = "H", data = KEY_H }, { description = "I", data = KEY_I }, { description = "J", data = KEY_J }, { description = "K", data = KEY_K }, { description = "L", data = KEY_L }, { description = "M", data = KEY_M }, { description = "N", data = KEY_N }, { description = "O", data = KEY_O }, { description = "P", data = KEY_P }, { description = "Q", data = KEY_Q }, { description = "R", data = KEY_R }, { description = "S", data = KEY_S }, { description = "T", data = KEY_T }, { description = "U", data = KEY_U }, { description = "V", data = KEY_V }, { description = "W", data = KEY_W }, { description = "X", data = KEY_X }, { description = "Y", data = KEY_Y }, { description = "Z", data = KEY_Z },
        { description = "NUMPAD0", data = KEY_NUMPAD0 }, { description = "NUMPAD1", data = KEY_NUMPAD1 }, { description = "NUMPAD2", data = KEY_NUMPAD2 }, { description = "NUMPAD3", data = KEY_NUMPAD3 }, { description = "NUMPAD4", data = KEY_NUMPAD4 }, { description = "NUMPAD5", data = KEY_NUMPAD5 }, { description = "NUMPAD6", data = KEY_NUMPAD6 }, { description = "NUMPAD7", data = KEY_NUMPAD7 }, { description = "NUMPAD8", data = KEY_NUMPAD8 }, { description = "NUMPAD9", data = KEY_NUMPAD9 }, { description = "MULTIPLY", data = KEY_MULTIPLY }, { description = "ADD", data = KEY_ADD }, { description = "SUBTRACT", data = KEY_SUBTRACT }, { description = "DECIMAL", data = KEY_DECIMAL }, { description = "DIVIDE", data = KEY_DIVIDE },
        { description = "F1", data = KEY_F1 }, { description = "F2", data = KEY_F2 }, { description = "F3", data = KEY_F3 }, { description = "F4", data = KEY_F4 }, { description = "F5", data = KEY_F5 }, { description = "F6", data = KEY_F6 }, { description = "F7", data = KEY_F7 }, { description = "F8", data = KEY_F8 }, { description = "F9", data = KEY_F9 }, { description = "F10", data = KEY_F10 }, { description = "F11", data = KEY_F11 }, { description = "F12", data = KEY_F12 },
        { description = "LEFT_SHIFT", data = KEY_LEFT_SHIFT }, { description = "RIGHT_SHIFT", data = KEY_RIGHT_SHIFT },
        { description = "LEFT_CONTROL", data = KEY_LEFT_CONTROL }, { description = "RIGHT_CONTROL", data = KEY_RIGHT_CONTROL },
        { description = "LEFT_ALT", data = KEY_LEFT_ALT }, { description = "RIGHT_ALT", data = KEY_RIGHT_ALT },
        { description = "SPACE", data = KEY_SPACE }, { description = "TAB", data = KEY_TAB }, { description = "BACKSPACE", data = KEY_BACKSPACE }, { description = "ENTER", data = KEY_ENTER }, { description = "CAPSLOCK", data = KEY_CAPSLOCK },
        { description = "PAGE_UP", data = KEY_PAGE_UP }, { description = "PAGE_DOWN", data = KEY_PAGE_DOWN }, { description = "END", data = KEY_END }, { description = "HOME", data = KEY_HOME },
        { description = "INSERT", data = KEY_INSERT }, { description = "DELETE", data = KEY_DELETE },
        { description = "LEFT", data = KEY_LEFT }, { description = "RIGHT", data = KEY_RIGHT }, { description = "UP", data = KEY_UP }, { description = "DOWN", data = KEY_DOWN },

        -- 鼠标按键
        { description = "MOUSE_LEFT", data = MOUSEBUTTON_LEFT },
        { description = "MOUSE_RIGHT", data = MOUSEBUTTON_RIGHT },
        { description = "MOUSE_MIDDLE", data = MOUSEBUTTON_MIDDLE },
        { description = "MOUSE_X1", data = MOUSEBUTTON_X1 },
        { description = "MOUSE_X2", data = MOUSEBUTTON_X2 }
    }
    return keys
end

-- 调用函数以打印所有按键的键值
local keys = getAllKeys()
print(tostring(keys))

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
    }, {
        name = "useHotkey", -- 配置项名换，在modmain.lua里获取配置值时要用到
        hover = "触发快捷键设置", -- 鼠标移到配置项上时所显示的信息
        options = keys,
        default = ""                   -- 默认值，与可选项里的值匹配作为默认值
    }
}