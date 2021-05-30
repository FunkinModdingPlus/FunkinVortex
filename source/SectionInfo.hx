package;

import Song.SwagSong;
import flixel.FlxSprite;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class SectionInfo extends FlxTypedSpriteGroup<FlxSprite>
{
	public var song:SwagSong;

	public var mustHitTxt:FlxText;
	public var altAnimTxt:FlxText;
	public var altNumTxt:FlxText;
	public var stepperAnim:FlxUINumericStepper;

	var backdrop:FlxSprite;
	var curSection:Int;

	public function new(X:Float, Y:Float, Song:SwagSong, Section:Int)
	{
		super(X, Y);
		song = Song;
		curSection = Section;
		backdrop = new FlxSprite().makeGraphic(300, 500, FlxColor.GRAY);
		mustHitTxt = new FlxText(20, 20, 0, "Must Hit Section: false", 12);
		altAnimTxt = new FlxText(20, 50, 0, "Alt Anim Section: false", 12);
		altNumTxt = new FlxText(20, 80, 0, "Alt Anim Num: ", 12);
		if (Song.notes.length != 0)
		{
			mustHitTxt.text = "Must Hit Section: " + Song.notes[Section].mustHitSection;
			altAnimTxt.text = "Alt Anim Section: " + Song.notes[Section].altAnim;
		}
		stepperAnim = new FlxUINumericStepper(20 + altNumTxt.width, 80, 1, 0, 0, 999);
		add(backdrop);
		add(mustHitTxt);
		add(altAnimTxt);
		add(altNumTxt);
		add(stepperAnim);
	}

	public function changeSection(Section:Int)
	{
		curSection = Section;
		if (song.notes.length != 0)
		{
			mustHitTxt.text = "Must Hit Section: " + song.notes[Section].mustHitSection;
			altAnimTxt.text = "Alt Anim Section: " + song.notes[Section].altAnim;
			// altNumTxt.text = "Alt Anim Section: " + song.notes[Section].altAnimNum;
		}
	}
}
