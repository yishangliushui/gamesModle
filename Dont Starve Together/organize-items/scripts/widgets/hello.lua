GLOBAL.setmetatable(env, { __index = function(t, k)
    return GLOBAL.rawget(GLOBAL, k)
end })

-- ���ȣ����ļ���ͷ��д����Ҫ���ص�Widget��
local Widget = require "widgets/widget" --Widget������widget��������
local Text = require "widgets/text" --Text�࣬�ı�����
local Hello = Class(Widget, function(self) -- ���ﶨ����һ��Class����һ�������Ǹ��࣬�ڶ��������ǹ��캯���������Ĳ�����һ���̶�Ϊself������Ĳ������Բ�д��Ҳ�����Զ��塣
    Widget._ctor(self, "Hello") --��һ�����д�ڹ��캯���ĵ�һ�У�����ᱨ��
    --��������ø���Ĺ��캯�����˴���Widget������̳�Text����Ӧ��дText._ctor������һ�������ǹ̶���self������Ĳ���ͬ�������Ĺ��캯���Ĳ������˴�д����Widget�����֡�
    --
    self.text = self:AddChild(Text(BODYTEXTFONT, 30,"Hello Klei")) --���һ���ı�����������Textʵ����
end)
return Hello
