-- 名称
name = "organize-items"
-- 描述
description = ""
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
client_only_mod = false
-- 是否是所有客户端都需要安装
all_clients_require_mod = true
-- 饥荒api版本，固定填10
api_version = 10

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
