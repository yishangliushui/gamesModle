GLOBAL.setmetatable(env, { __index = function(t, k)
    return GLOBAL.rawget(GLOBAL, k)
end })

-- ���ȣ����ļ���ͷ��д����Ҫ���ص�Widget��
local Widget = require "widgets/widget" --Widget������widget��������
--local Text = require "widgets/text" --Text�࣬�ı�����
local TextButton = require("widgets/textbutton")
local Category = Class(Widget, function(self) -- ���ﶨ����һ��Class����һ�������Ǹ��࣬�ڶ��������ǹ��캯���������Ĳ�����һ���̶�Ϊself������Ĳ������Բ�д��Ҳ�����Զ��塣
    Widget._ctor(self, "Category") --��һ�����д�ڹ��캯���ĵ�һ�У�����ᱨ��
    self.text = self:AddChild(TextButton(BODYTEXTFONT, 30, "��ť")) --���һ���ı�����������Textʵ����
end)
return Category
