package;

import flixel.FlxSprite;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

// does not support sus length because "dumbass you can already do that"
class NoteInfo extends FlxTypedSpriteGroup<FlxSprite>
{
	public var altNoteTxt:FlxText;
	public var altNoteNum:FlxText;
	public var stepperAltNote:FlxUINumericStepper;

	var backdrop:FlxSprite;

	public function new(X:Float, Y:Float)
	{
		super(X, Y);
		backdrop = new FlxSprite().makeGraphic(300, 500, FlxColor.GRAY);
		altNoteNum = new FlxText(20, 20, 0, "Alt Num: ", 12);
		altNoteTxt = new FlxText(20, 50, 0, "Alt Anim Note: false", 12);
		stepperAltNote = new FlxUINumericStepper(20 + altNoteNum.width, 20, 1, 0, 0, 99);
		add(backdrop);
		add(altNoteNum);
		add(altNoteTxt);
		add(stepperAltNote);
	}

	public function updateNote(niceNote:Array<Dynamic>)
	{
		if (niceNote[3] == null)
			return;
		altNoteTxt.text = "Alt Anim Note: " + cast(niceNote[3] : Bool);
		// if nice note is expicility true?
		if (niceNote[3] == true)
		{
			stepperAltNote.value = 1;
		}
		else if (niceNote[3] == false)
		{
			stepperAltNote.value = 0;
		}
		else
		{
			stepperAltNote.value = cast niceNote[3];
		}
	}
}
