package options;

import objects.Character;

class GraphicsSettingsSubState extends BaseOptionsMenu
{
	var antialiasingOption:Int;
	var boyfriend:Character = null;
	public function new()
	{
		title = 'Performance';
		rpcTitle = 'Performance Settings Menu'; //for Discord Rich Presence

		boyfriend = new Character(840, 170, 'bf', true);
		boyfriend.setGraphicSize(Std.int(boyfriend.width * 0.75));
		boyfriend.updateHitbox();
		boyfriend.dance();
		boyfriend.animation.finishCallback = function (name:String) boyfriend.dance();
		boyfriend.visible = false;

		//I'd suggest using "Low Quality" as an example for making your own option since it is the simplest here
		var option:Option = new Option('Low Quality', //Name
			'如果勾选，会禁用部分背景细节，减少加载时间并提升性能。', //Description
			'lowQuality', //Save data variable name
			'bool'); //Variable type
		addOption(option);

		var option:Option = new Option('Anti-Aliasing',
			'如果取消勾选，会关闭抗锯齿，提升性能但画面会更锐利。',
			'antialiasing',
			'bool');
		option.onChange = onChangeAntiAliasing; //Changing onChange is only needed if you want to make a special interaction after it changes the value
		addOption(option);
		antialiasingOption = optionsArray.length-1;

		var option:Option = new Option('Shaders', //Name
			"如果取消勾选，会关闭着色器。用于部分视觉效果，低配设备会占用大量性能。", //Description
			'shaders',
			'bool');
		addOption(option);

		// var option:Option = new Option('GPU Caching', //Name
		// 	"If checked, allows the GPU to be used for caching textures, decreasing RAM usage.\nDon't turn this on if any of your mods modify pixels of sprites.", //Description
		// 	'cacheOnGPU',
		// 	'bool');
		// addOption(option);

		#if !html5 //Apparently other framerates isn't correctly supported on Browser? Probably it has some V-Sync shit enabled by default, idk

		var option:Option = new Option('Framerate',
			"很容易理解，不是吗？",
			'framerate',
			'int');
		addOption(option);

		option.minValue = 60;
		option.maxValue = 240;
		option.displayFormat = '%v FPS';
		option.onChange = onChangeFramerate;

		var option:Option = new Option('Max FPS', //Name
			"如果勾选，帧率限制会设为1000。此设置会让输入 timing 更精准，但可能出现轻微画面问题。", //Description
			'unlockFramerate',
			'bool');
		option.onChange = onChangeFramerate;
		addOption(option);
		#end

		var option:Option = new Option('Disable Text Item Icons', //Name
			"如果勾选，菜单文本图标将不会加载，大幅减少加载时间。", //Description
			'disableFreeplayIcons',
			'bool');
		addOption(option);

		var option:Option = new Option('Disable Text Item Alphabet', //Name
			"如果勾选，各类菜单元素将使用像素字体渲染。", //Description
			'disableFreeplayAlphabet',
			'bool');
		addOption(option);

		var option:Option = new Option('Combo Stacking',
			"如果取消勾选，判定与连击不会叠加显示，节省少量内存并更易阅读。",
			'comboStacking',
			'bool');
		addOption(option);

		super();
		insert(1, boyfriend);
	}

	function onChangeAntiAliasing()
	{
		FlxSprite.defaultAntialiasing = ClientPrefs.data.antialiasing;
		
		for (sprite in members)
		{
			var sprite:FlxSprite = cast sprite;
			if(sprite != null && (sprite is FlxSprite) && !(sprite is FlxText)) {
				sprite.antialiasing = ClientPrefs.data.antialiasing;
			}
		}
	}

	function onChangeFramerate()
	{
		if (ClientPrefs.data.unlockFramerate) {
			FlxG.updateFramerate = 1000;
			FlxG.drawFramerate = 1000;
			return;
		}


		if(ClientPrefs.data.framerate > FlxG.drawFramerate)
		{
			FlxG.updateFramerate = ClientPrefs.data.framerate;
			FlxG.drawFramerate = ClientPrefs.data.framerate;
		}
		else
		{
			FlxG.drawFramerate = ClientPrefs.data.framerate;
			FlxG.updateFramerate = ClientPrefs.data.framerate;
		}
	}

	override function changeSelection(change:Int = 0)
	{
		super.changeSelection(change);
		boyfriend.visible = (antialiasingOption == curSelected);
	}
}
