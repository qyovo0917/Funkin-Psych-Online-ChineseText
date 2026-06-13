package online.objects;

import lime.app.Application;
import lime.ui.KeyCode;
import lime.ui.KeyModifier;
import online.gui.sidebar.SideUI;
import flixel.text.FlxText;

#if (!flash && cpp)
@:cppFileCode("
#include <windows.h>
#include <imm.h>
#pragma comment(lib, \"imm32\")

static WNDPROC g_origWndProc = NULL;
static bool g_imeJustEnded = false;

static LRESULT CALLBACK ImeWndProc(HWND h, UINT m, WPARAM w, LPARAM l) {
    if (m == WM_IME_CHAR) {
        return 0;
    }
    if (m == WM_IME_ENDCOMPOSITION) {
        g_imeJustEnded = true;
    }
    return CallWindowProcW(g_origWndProc, h, m, w, l);
}

static bool ConsumeImeJustEnded() {
    if (g_imeJustEnded) {
        g_imeJustEnded = false;
        return true;
    }
    return false;
}

static void InstallImeWndSubclass() {
    static bool s_done = false;
    if (s_done) return;
    HWND hw = FindWindowA(\"SDL_app\", NULL);
    if (!hw) {
        struct { DWORD pid; HWND hw; } ctx = { GetCurrentProcessId(), NULL };
        EnumWindows([](HWND hw, LPARAM lp) -> BOOL {
            auto c = (decltype(ctx)*)lp;
            DWORD pid; GetWindowThreadProcessId(hw, &pid);
            if (pid == c->pid && GetWindowTextLengthW(hw) > 0) { c->hw = hw; return FALSE; }
            return TRUE;
        }, (LPARAM)&ctx);
        hw = ctx.hw;
    }
    if (hw) {
        g_origWndProc = (WNDPROC)SetWindowLongPtrW(hw, GWLP_WNDPROC, (LONG_PTR)ImeWndProc);
        s_done = true;
    }
}

static bool IsImeComposing() {
    HWND hw = FindWindowA(\"SDL_app\", NULL);
    if (!hw) {
        struct { DWORD pid; HWND hw; } ctx = { GetCurrentProcessId(), NULL };
        EnumWindows([](HWND hw, LPARAM lp) -> BOOL {
            auto c = (decltype(ctx)*)lp;
            DWORD pid; GetWindowThreadProcessId(hw, &pid);
            if (pid == c->pid && GetWindowTextLengthW(hw) > 0) { c->hw = hw; return FALSE; }
            return TRUE;
        }, (LPARAM)&ctx);
        hw = ctx.hw;
    }
    if (!hw) return false;
    HIMC himc = ImmGetContext(hw);
    if (!himc) return false;
    bool composing = (ImmGetCompositionStringW(himc, GCS_COMPSTR, NULL, 0) > 0);
    ImmReleaseContext(hw, himc);
    return composing;
}
")
#end

class InputText extends FlxText {

var inputBuffer:String = '';
var inputCursor:Int = 0;

public var inputText(get, never):String;
function get_inputText() return inputBuffer;

public var hasFocus(default, set):Bool = false;
function set_hasFocus(v:Bool) {
if (hasFocus == v)
return v;
hasFocus = v;

if (v) {
sdlStartTextInput();
updateTextInputRect();
}
else {
sdlStopTextInput();
}

caretVisible = v;
caretTimer = 0;
caret.visible = v;
renderText();
return hasFocus;
}

public function clear() {
inputBuffer = '';
inputCursor = 0;
_lastRendered = '\x00';
renderText();
}

public var backgroundColor:FlxColor = FlxColor.TRANSPARENT;
public var fieldBorderColor:FlxColor = FlxColor.TRANSPARENT;
public var caretColor:FlxColor = FlxColor.WHITE;

var caret:FlxSprite;
var caretTimer:Float = 0;
var caretVisible:Bool = false;
static inline final CARET_INTERVAL:Float = 0.5;

var _lastRendered:String = '\x00';

var onEnter:(text:String)->Void;

var _onTextInput:String->Void;
var _onLimeKeyDown:KeyCode->KeyModifier->Void;

public function new(x:Float, y:Float, width:Float, onEnter:(text:String)->Void) {
super(x, y, Std.int(width));

this.onEnter = onEnter;

setFormat("CN.ttf", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);

caret = new FlxSprite();
caret.makeGraphic(2, Std.int(size), FlxColor.WHITE);
caret.visible = false;

_onTextInput = onLimeTextInput;
_onLimeKeyDown = onLimeKeyDown;
Application.current.window.onTextInput.add(_onTextInput);
Application.current.window.onKeyDown.add(_onLimeKeyDown);

renderText();

#if (!flash && cpp)

untyped __cpp__("InstallImeWndSubclass();");
#end
}

static function sdlStartTextInput():Void {
Application.current.window.textInputEnabled = true;
}

static function sdlStopTextInput():Void {
Application.current.window.textInputEnabled = false;
}

static function sdlSetTextInputRect(x:Int, y:Int, w:Int, h:Int):Void {
Application.current.window.setTextInputRect(new lime.math.Rectangle(x, y, w, h));
}

function updateTextInputRect() {
var screenPos = getScreenPosition();
var caretScreenX:Float = getCaretX();

sdlSetTextInputRect(
Std.int(screenPos.x + caretScreenX),
Std.int(screenPos.y),
Std.int(Math.max(10, width * 0.5)),
Std.int(Math.max(20, size + 4))
);
screenPos.put();
}

function getCaretX():Float {
@:privateAccess {
if (inputCursor <= 0) return 0;
if (inputCursor >= inputBuffer.length) return textField.textWidth;
var bounds = textField.getCharBoundaries(inputCursor - 1);
if (bounds != null) return bounds.right;
return textField.textWidth;
}
}

override function draw() {
super.draw();

if (hasFocus && caretVisible) {
var caretX:Float = getCaretX();
caret.x = x + caretX;
caret.y = y;
caret.cameras = cameras;
caret.draw();
}
}

override function destroy() {
super.destroy();
caret.destroy();

if (Application.current != null && Application.current.window != null) {
Application.current.window.onTextInput.remove(_onTextInput);
Application.current.window.onKeyDown.remove(_onLimeKeyDown);
}
}

function onLimeTextInput(text:String) {
if (!hasFocus)
return;
if (SideUI.instance != null && SideUI.instance.active)
return;

inputBuffer = inputBuffer.substr(0, inputCursor) + text + inputBuffer.substr(inputCursor);
inputCursor += text.length;
renderText();
}

function onLimeKeyDown(key:KeyCode, mod:KeyModifier) {
if (!hasFocus)
return;
if (SideUI.instance != null && SideUI.instance.active)
return;

#if (!flash && cpp)
if (untyped __cpp__("ConsumeImeJustEnded()")) return;
#end

#if (!flash && cpp)
if (untyped __cpp__("IsImeComposing()")) return;
#end

switch (key) {
case RETURN | NUMPAD_ENTER:
var t:String = inputBuffer;
inputBuffer = '';
inputCursor = 0;
hasFocus = false;
renderText();
onEnter(t);

case BACKSPACE:
if (inputCursor > 0) {
inputBuffer = inputBuffer.substr(0, inputCursor - 1) + inputBuffer.substr(inputCursor);
inputCursor--;
renderText();
}

case DELETE:
if (inputCursor < inputBuffer.length) {
inputBuffer = inputBuffer.substr(0, inputCursor) + inputBuffer.substr(inputCursor + 1);
renderText();
}

case LEFT:
if (inputCursor > 0) { inputCursor--; renderText(); }

case RIGHT:
if (inputCursor < inputBuffer.length) { inputCursor++; renderText(); }

case HOME:
inputCursor = 0; renderText();

case END:
inputCursor = inputBuffer.length; renderText();

case V if (mod.ctrlKey):
var clip:String = lime.system.Clipboard.text;
if (clip != null && clip.length > 0) {
inputBuffer = inputBuffer.substr(0, inputCursor) + clip + inputBuffer.substr(inputCursor);
inputCursor += clip.length;
renderText();
}

default:
}
}

function renderText() {
if (inputBuffer == _lastRendered)
return;
_lastRendered = inputBuffer;
text = inputBuffer;
}

override function update(elapsed:Float) {
super.update(elapsed);

if (hasFocus) {
if (FlxG.keys.justPressed.ESCAPE
|| (FlxG.mouse.justPressed && !FlxG.mouse.overlaps(this))) {
hasFocus = false;
}

caretTimer += elapsed;
if (caretTimer >= CARET_INTERVAL) {
caretTimer = 0;
caretVisible = !caretVisible;
caret.visible = caretVisible;
}
}
}
}
