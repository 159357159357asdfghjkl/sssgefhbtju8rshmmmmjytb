package;

import ChapterData;
import WeekData;
import flash.ui.Mouse;
import flash.ui.MouseCursor;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.display.shapes.FlxShapeBox;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.FlxUIButton;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.*;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import sowy.*;

using StringTools;
#if desktop
import Discord.DiscordClient;
#end

class StoryMenuState extends MusicBeatState
{
	public static var weekCompleted:Map<String, Bool> = new Map<String, Bool>();
	public static var instance:StoryMenuState;

	//public var camFollowPos:FlxObject;

	final chapterSelectPositions:Array<Array<Int>> = [ // Screen positions for the chapter options
		[51, 109], [305, 109], [542, 109], [788, 109], [1034, 109],
		[51, 417], [305, 417], [542, 417], [788, 417], [1034, 417]
	];

	var mainMenu = new FlxTypedGroup<FlxBasic>(); // group for the main menu where you select achapter!
	//var subMenu:ChapterMenuState; // custom group class for the menu where yu select a song!
	
	var funkyRectangle = new FlxShapeBox(0, 0, 206, 206, {thickness: 3, color: FlxColor.fromRGB(255, 242, 0)}, FlxColor.BLACK); // cool rectanlge used for transitions
	var lastButton:ChapterOption; // used the square transition
	var doingTransition = false; // to prevent unintended behaviour

	var cornerLeftText:SowyTextButton;

	var isOnSubMenu = false;

	public static function weekIsLocked(leWeek:WeekData):Bool {
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!weekCompleted.exists(leWeek.weekBefore) || !weekCompleted.get(leWeek.weekBefore)));
	}

	override function create()
	{
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		
		FlxG.mouse.visible = true;
		#end
		
		FlxG.camera.focusOn(new FlxPoint(FlxG.width / 2, FlxG.height / 2));
		FlxG.camera.bgColor = FlxColor.BLACK;

		var chapN:Int = -1;

		for (chapData in ChapterData.reloadChapterFiles())
		{
			var isLocked = false; // for now
			if (isLocked)
				continue;

			Paths.currentModDirectory = chapData.directory;
			chapN++;

			var previewImage = Paths.image("newmenuu/songselect/" + Paths.formatToSongPath(chapData.name) + (isLocked ? "lock" : ""));
			previewImage = previewImage != null ? previewImage : Paths.image("newmenuu/songselect/unknown");
			
			var pos = chapterSelectPositions[chapN];
			var xPos = pos[0];
			var yPos = pos[1];

			var newButton = new ChapterOption(xPos, yPos, chapData);
			newButton.loadGraphic(previewImage);

			var yellowBorder = new FlxShapeBox(xPos - 3, yPos - 3, 200, 200, {thickness: 6, color: FlxColor.fromRGB(255, 242, 0)}, FlxColor.TRANSPARENT);
			var textTitle = new FlxText(xPos - 3, yPos - 30, 206, chapData.name, 12);
			textTitle.setFormat(Paths.font("calibri.ttf"), 18, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.NONE);

			if (isLocked){
				newButton.onUp.callback = function(){
					if (doingTransition)
						return;
					FlxG.sound.play(Paths.sound('lockedMenu'));
					newButton.shake();
				}
			}else{
				newButton.onUp.callback = function()
				{
					if (doingTransition)
						return;
					FlxG.sound.play(Paths.sound('cancelMenu')); // swoosh
					openRectangleTransition(newButton.x, newButton.y, function(){
						lastButton = newButton;
						var subMenu = new ChapterMenuState(newButton.data);
						openSubState(subMenu);
					});
				}
			}

			mainMenu.add(textTitle);
			mainMenu.add(newButton);
			mainMenu.add(yellowBorder);			
		}
		
		cornerLeftText = new SowyTextButton(15, 720, 0, "← BACK", 32, goBack);
		cornerLeftText.label.setFormat(Paths.font("calibri.ttf"), 32, FlxColor.YELLOW, FlxTextAlign.RIGHT, FlxTextBorderStyle.NONE, FlxColor.YELLOW);
		cornerLeftText.y -= cornerLeftText.height + 15;
		mainMenu.add(cornerLeftText);
		
		add(mainMenu);
		funkyRectangle.visible = false;
		add(funkyRectangle);
		
		//destroySubStates = false;
		instance = this;
		super.create();
	}

	override function closeSubState()
	{
		super.closeSubState();

		if (isOnSubMenu)
			closeRectangleTransition();
	}

	public function goBack()
	{
		if (!doingTransition)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			
			if (!doingTransition){
				//subMenu.destroy();
				MusicBeatState.switchState(new MainMenuState());
			}
		}
	} 

	override function update(elapsed:Float)
	{
		if (controls.BACK)
			goBack();

		super.update(elapsed);
	}

	function openRectangleTransition(?x:Float, ?y:Float, ?onEnd:Void->Void){
		doingTransition = true;
		isOnSubMenu = true;

		funkyRectangle.setPosition(x != null ? x : funkyRectangle.x, y != null ? y : funkyRectangle.y);
		funkyRectangle.visible = true;

		cornerLeftText.visible = false;
		
		FlxTween.tween(funkyRectangle, {
			x: 10,
			y: 10,
			width: 1260,
			height: 700,
			shapeWidth: 1260,
			shapeHeight: 700,
		},
		0.6,
		{
			ease: FlxEase.quadOut,
			onComplete: function(twn){
				doingTransition = false;
				remove(mainMenu);

				if (onEnd != null)
					onEnd();
				else
					trace("xd no function");
			}
		}
		);
	}

	function closeRectangleTransition(){
		doingTransition = true;
		isOnSubMenu = false;
		
		add(mainMenu);
		
		FlxTween.tween(funkyRectangle, {
			x: lastButton.x - 3,
			y: lastButton.y - 3,
			width: 206,
			height: 206,
			shapeWidth: 206,
			shapeHeight: 206,
		}, 0.6, {
			ease: FlxEase.quadOut,
			onComplete: function(twn)
			{
				doingTransition = false;
				funkyRectangle.visible = false;
				cornerLeftText.visible = true;
			}
		});
	}
}
class ChapterOption extends TGTSquareButton{
	public var data:ChapterMetadata;

	public function new(?X:Float = 0, ?Y:Float = 0, Data:ChapterMetadata){
		data = Data;
		super(X, Y);
	}
	override function onover(){
		//if (!StoryMenuState.weekIsLocked(daWeek))
			super.onover();
	}
}