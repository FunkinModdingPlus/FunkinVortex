package;

import Song.SwagSong;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class SectionInfo extends FlxTypedSpriteGroup<FlxSprite>
{
	public var song:SwagSong;

	public var mustHitTxt:FlxText;

	var backdrop:FlxSprite;
	var curSection:Int;

	public function new(X:Float, Y:Float, Song:SwagSong, Section:Int)
	{
		super(X, Y);
		song = Song;
		curSection = Section;
		backdrop = new FlxSprite().makeGraphic(300, 500, FlxColor.GRAY);
		mustHitTxt = new FlxText(20, 20, 0, "Must Hit Section: false", 12);
		if (Song.notes.length != 0)
			mustHitTxt.text = "Must Hit Section: " + Song.notes[Section].mustHitSection;
		add(backdrop);
		add(mustHitTxt);
	}

	public function changeSection(Section:Int)
	{
		curSection = Section;
		if (song.notes.length != 0)
			mustHitTxt.text = "Must Hit Section: " + song.notes[curSection].mustHitSection;
	}
}
