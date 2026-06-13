package online.objects;

import online.gui.sidebar.SideUI;
import flixel.addons.ui.FlxInputText;

class InputText extends FlxInputText {
    public function new(x:Float, y:Float, width:Float, onEnter:(text:String)->Void) {
        super(x, y, Std.int(width));

        backgroundColor = FlxColor.TRANSPARENT;
        fieldBorderColor = FlxColor.TRANSPARENT;
        caretColor = FlxColor.WHITE;

        // 旧版兼容：确保文本框可选择、能接收焦点
        textField.selectable = true;
        textField.autoSize = false;
        textField.wordWrap = false;

        var prevText:String = '';
        callback = (text, action) -> {
            if (SideUI.instance != null && SideUI.instance.active) {
                this.text = prevText;
                return;
            }

            prevText = text;

            if (action == FlxInputText.ENTER_ACTION) {
                hasFocus = false;
                onEnter(text);
            }
        };
    }

    override function update(elapsed) {
        super.update(elapsed);

        // 旧版兼容：手动设置焦点，让系统输入法能捕获到
        if (hasFocus) {
            FlxG.stage.focus = textField;
        } else {
            // 失去焦点时清空，避免残留
            if (FlxG.stage.focus == textField) {
                FlxG.stage.focus = null;
            }
        }

        // 失去焦点的逻辑
        if (hasFocus && (FlxG.keys.justPressed.ESCAPE || (FlxG.mouse.justPressed && !FlxG.mouse.overlaps(this)))) {
            hasFocus = false;
            FlxG.stage.focus = null;
        }
    }
}
