package;

import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxMath;
import flixel.text.FlxText;

abstract Union<T1, T2>(Dynamic) from T1 to T1 from T2 to T2 {}

class VtxNote extends FlxSprite
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

		loadGraphic('assets/images/arrows-pixels.png', true, 17, 17);

		if (noteType == "custom")
		{
			var sussyInfo = Math.floor(noteData / (NOTE_AMOUNT * 2)) - 5;
			if (coolCustomGraphics[sussyInfo] == null)
				coolCustomGraphics[sussyInfo] = FlxGraphic.fromAssetKey('assets/images/arrows-pixels.png', true);
			loadGraphic(coolCustomGraphics[sussyInfo], true, 17, 17);
		}
		switch (noteType)
		{
			case "normal" | "drain" | "custom":
				switch (noteData % 4)
				{
					case 0: animation.add('note', [4]);
					case 1: animation.add('note', [5]);
					case 2: animation.add('note', [6]);
					case 3: animation.add('note', [7]);
				}
			case "lift":
				switch (noteData % 4)
				{
					case 0: animation.add('note', [8]);
					case 1: animation.add('note', [9]);
					case 2: animation.add('note', [10]);
					case 3: animation.add('note', [11]);
				}
			case "mine":
				animation.add('note', [1]);
				switch (noteData % 4)
				{
					case 0: angle = 270;
					case 1: angle = 180;
					case 2: angle = 0;
					case 3: angle = 90;
				}
			case "nuke":
				animation.add('note', [0]);
				switch (noteData % 4)
				{
					case 0: angle = 270;
					case 1: angle = 180;
					case 2: angle = 0;
					case 3: angle = 90;
				}
		}
		animation.play('note');
		setGraphicSize(40);
		if (noteType == "custom")
		{
			var sussyInfo = Math.floor(noteData / (NOTE_AMOUNT * 2));
			sussyInfo -= 4;
			var text = new FlxText(0, 0, 0, cast sussyInfo, 32);
			stamp(text, 0, 0);
		}
	}
}
