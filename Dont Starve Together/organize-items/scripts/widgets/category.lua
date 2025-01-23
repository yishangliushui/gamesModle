GLOBAL.setmetatable(env, { __index = function(t, k)
    return GLOBAL.rawget(GLOBAL, k)
end })

-- 首先，在文件的头部写上需要加载的Widget类
local Widget = require "widgets/widget" --Widget，所有widget的祖先类
--local Text = require "widgets/text" --Text类，文本处理
local TextButton = require("widgets/textbutton")
local Category = Class(Widget, function(self) -- 这里定义了一个Class，第一个参数是父类，第二个参数是构造函数，函数的参数第一个固定为self，后面的参数可以不写，也可以自定义。
    Widget._ctor(self, "Category") --这一句必须写在构造函数的第一行，否则会报错。
    self.text = self:AddChild(TextButton(BODYTEXTFONT, 30, "按钮")) --添加一个文本变量，接收Text实例。
end)
return Category
