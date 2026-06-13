package online.objects;

import online.gui.sidebar.SideUI;
import flixel.addons.ui.FlxInputText;
import openfl.text.IME;
import openfl.text.IMEMode;

class InputText extends FlxInputText {
    public function new(x:Float, y:Float, width:Float, onEnter:(text:String)->Void) {
        super(x, y, Std.int(width));

		backgroundColor = FlxColor.TRANSPARENT;
		fieldBorderColor = FlxColor.TRANSPARENT;
		caretColor = FlxColor.WHITE;

        #if desktop
        textField.imeEnabled = true;
        textField.imeMode = IMEMode.DEFAULT;
        #end

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

        #if desktop
        if (hasFocus) {
            IME.setCompositionEnabled(true);
        } else {
            IME.setCompositionEnabled(false);
        }
        #end

		if (hasFocus && (FlxG.keys.justPressed.ESCAPE || (FlxG.mouse.justPressed && !FlxG.mouse.overlaps(this)))) {
            hasFocus = false;
        }
    }
}
