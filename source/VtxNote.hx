package;

import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;

abstract Union<T1, T2>(Dynamic) from T1 to T1 from T2 to T2 {}

class VtxNote extends FlxTypedSpriteGroup<FlxSprite>
{
	public var noteData:Int = 0;
	public var strumTime:Float = 0;
	public var susLength:Float = 0;
	public var altNote:Union<Bool, Int>;

	static var NOTE_AMOUNT = 4;
	static var coolCustomGraphics:Array<FlxGraphic> = [];

	public function new(strumTime:Float, noteData:Int, susLength:Float, altNote:Union<Bool, Int>)
	{
		super();
		this.noteData = noteData;
		this.strumTime = strumTime;
		this.susLength = susLength;
		this.altNote = altNote;
		var noteType:String = "normal";
		if (noteData < NOTE_AMOUNT * 2)
		{
			// do nothing
		}
		else if (FlxMath.inBounds(noteData, NOTE_AMOUNT * 2, NOTE_AMOUNT * 4 - 1))
		{
			noteType = "mine";
		}
		else if (FlxMath.inBounds(noteData, NOTE_AMOUNT * 4, NOTE_AMOUNT * 6 - 1))
		{
			noteType = "lift";
		}
		else if (FlxMath.inBounds(noteData, NOTE_AMOUNT * 6, NOTE_AMOUNT * 8 - 1))
		{
			noteType = "nuke";
		}
		else if (FlxMath.inBounds(noteData, NOTE_AMOUNT * 8, NOTE_AMOUNT * 10 - 1))
		{
			noteType = "drain";
		}
		else
		{
			noteType = "custom";
		}
		var coolNote = new FlxSprite();
		coolNote.loadGraphic('assets/images/arrows-pixels.png', true, 17, 17);

		switch (noteType)
		{
			case "normal" | "drain" | "custom":
				switch (noteData % 4)
				{
					case 0: coolNote.animation.add('note', [4]);
					case 1: coolNote.animation.add('note', [5]);
					case 2: coolNote.animation.add('note', [6]);
					case 3: coolNote.animation.add('note', [7]);
				}
			case "lift":
				switch (noteData % 4)
				{
					case 0: coolNote.animation.add('note', [8]);
					case 1: coolNote.animation.add('note', [9]);
					case 2: coolNote.animation.add('note', [10]);
					case 3: coolNote.animation.add('note', [11]);
				}
			case "mine":
				coolNote.animation.add('note', [1]);
				switch (noteData % 4)
				{
					case 0: coolNote.angle = 270;
					case 1: coolNote.angle = 180;
					case 2: coolNote.angle = 0;
					case 3: coolNote.angle = 90;
				}
			case "nuke":
				coolNote.animation.add('note', [0]);
				switch (noteData % 4)
				{
					case 0: coolNote.angle = 270;
					case 1: coolNote.angle = 180;
					case 2: coolNote.angle = 0;
					case 3: coolNote.angle = 90;
				}
		}
		coolNote.animation.play('note');
		coolNote.antialiasing = false;
		coolNote.setGraphicSize(40);
		add(coolNote);
		if (noteType == "custom")
		{
			var sussyInfo = Math.floor(noteData / (NOTE_AMOUNT * 2));
			sussyInfo -= 4;
			var text = new FlxText(0, 0, 0, cast sussyInfo, 32);
			add(text);
		}
	}
}
