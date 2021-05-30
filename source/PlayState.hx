package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;

// By default sections come in steps of 16.
class PlayState extends FlxState
{
	static var _song:Song.SwagSong;

	var chart:FlxSpriteGroup;
	var staffLines:FlxSprite;
	var strumLine:FlxSpriteGroup;
	var curRenderedNotes:FlxSpriteGroup;
	var curRenderedSus:FlxSpriteGroup;
	var snaptext:FlxText;
	var curSnap:Float = 0;
	var curSelectedNote:Array<Dynamic>;
	var GRID_SIZE = 40;
	var openButton:FlxButton;
	var LINE_SPACING = 40;
	var camFollow:FlxObject;
	var lastLineY:Int = 0;
	var sectionMarkers:Array<Float> = [];
	var songLengthInSteps:Int = 0;

	override public function create()
	{
		super.create();
		strumLine = new FlxSpriteGroup(0, 0);
		curRenderedNotes = new FlxSpriteGroup();
		curRenderedSus = new FlxSpriteGroup();
		if (_song == null)
			_song = {
				song: 'Test',
				notes: [],
				bpm: 150,
				needsVoices: true,
				player1: 'bf',
				player2: 'dad',
				stage: 'stage',
				gf: 'gf',
				isHey: false,
				speed: 1,
				isSpooky: false,
				isMoody: false,
				cutsceneType: "none",
				uiType: 'normal',
				isCheer: false
			};
		// make it ridulously big
		staffLines = new FlxSprite().makeGraphic(FlxG.width, FlxG.height * _song.notes.length, FlxColor.BLACK);
		generateStrumLine();
		strumLine.screenCenter(X);
		trace(strumLine);
		staffLines.screenCenter(X);
		chart = new FlxSpriteGroup();
		chart.add(staffLines);
		chart.add(strumLine);
		chart.add(curRenderedNotes);
		chart.add(curRenderedSus);

		openButton = new FlxButton(10, 10, "Open Chart", loadFromFile);
		LINE_SPACING = Std.int(strumLine.height);
		curSnap = LINE_SPACING * 4;
		drawChartLines();
		updateNotes();
		camFollow = new FlxObject(strumLine.getGraphicMidpoint().x, strumLine.getGraphicMidpoint().y);
		FlxG.camera.follow(camFollow);
		staffLines.y += strumLine.height / 2;
		snaptext = new FlxText(0, FlxG.height, 0, '4ths', 24);
		snaptext.y -= snaptext.height;
		snaptext.scrollFactor.set();
		add(staffLines);
		add(strumLine);
		add(curRenderedNotes);
		add(curRenderedSus);
		add(chart);
		add(snaptext);
		add(openButton);
	}

	private function loadFromFile():Void
	{
		var future = FNFAssets.askToBrowse();
		future.onComplete(function(s:String)
		{
			_song = Song.loadFromJson(s);
			FlxG.resetState();
		});
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		camFollow.setPosition(strumLine.x + Note.swagWidth * 2, strumLine.y);
		if (FlxG.keys.justPressed.UP)
		{
			moveStrumLine(-1);
		}
		else if (FlxG.keys.justPressed.DOWN)
		{
			moveStrumLine(1);
		}
		if (FlxG.keys.justPressed.RIGHT)
		{
			switch (snaptext.text)
			{
				case '4ths':
					snaptext.text = "8ths";
					curSnap = (LINE_SPACING * 16) / 8;
				case '8ths':
					snaptext.text = "16ths";
					curSnap = LINE_SPACING;
				case '16ths':
					snaptext.text = '4ths';
					curSnap = (LINE_SPACING * 16) / 4;
			}
		}
		else if (FlxG.keys.justPressed.LEFT)
		{
			switch (snaptext.text)
			{
				case '4ths':
					snaptext.text = "16ths";
					curSnap = (LINE_SPACING * 16) / 16;
				case '8ths':
					snaptext.text = "4ths";
					curSnap = (LINE_SPACING * 16) / 4;
				case '16ths':
					snaptext.text = '8ths';
					curSnap = (LINE_SPACING * 16) / 8;
			}
		}
	}

	private function moveStrumLine(change:Int = 0)
	{
		strumLine.y += change * curSnap;
		strumLine.y = Math.floor(strumLine.y / curSnap) * curSnap;
	}

	private function generateStrumLine()
	{
		for (i in -4...4)
		{
			var babyArrow = new FlxSprite(strumLine.x, strumLine.y);
			babyArrow.frames = FlxAtlasFrames.fromSparrow('assets/images/NOTE_assets.png', 'assets/images/NOTE_assets.xml');

			babyArrow.animation.addByPrefix('green', 'arrowUP');
			babyArrow.animation.addByPrefix('blue', 'arrowDOWN');
			babyArrow.animation.addByPrefix('purple', 'arrowLEFT');
			babyArrow.animation.addByPrefix('red', 'arrowRIGHT');
			switch (i)
			{
				case -4 | 0:
					babyArrow.animation.play("purple");
				case 1 | -3:
					babyArrow.animation.play("blue");
				case 2 | -2:
					babyArrow.animation.play("green");
				case 3 | -1:
					babyArrow.animation.play("red");
			}
			babyArrow.antialiasing = true;
			babyArrow.setGraphicSize(Std.int(40));
			babyArrow.x += 160 * babyArrow.scale.x * i + 50;
			babyArrow.updateHitbox();
			babyArrow.scrollFactor.set();
			babyArrow.ID = i;
			strumLine.add(babyArrow);
		}
	}

	private function drawChartLines()
	{
		staffLines.makeGraphic(FlxG.width, FlxG.height * _song.notes.length * 16, FlxColor.BLACK);
		for (i in 0..._song.notes.length)
		{
			for (o in 0..._song.notes[i].lengthInSteps)
			{
				var lineColor:FlxColor = FlxColor.GRAY;
				if (o == 0)
				{
					lineColor = FlxColor.WHITE;
				}
				FlxSpriteUtil.drawLine(staffLines, FlxG.width * -0.5, LINE_SPACING * ((i * 16) + o), FlxG.width * 1.5, LINE_SPACING * ((i * 16) + o),
					{color: lineColor, thickness: 10});
				lastLineY = LINE_SPACING * ((i * 16) + o);
			}
		}
	}

	private function updateNotes()
	{
		while (curRenderedNotes.members.length > 0)
		{
			curRenderedNotes.remove(curRenderedNotes.members[0], true);
		}
		while (curRenderedSus.members.length > 0)
		{
			curRenderedSus.remove(curRenderedSus.members[0], true);
		}
		for (j in 0..._song.notes.length)
		{
			var sectionInfo:Array<Dynamic> = _song.notes[j].sectionNotes;
			// todo,  bpm support
			/*
				if (_song.notes[i].changeBPM && _song.notes[i].bpm > 0)
				{
					Conductor.changeBPM(_song.notes[i].bpm);
			}*/
			Conductor.changeBPM(_song.bpm);
			songLengthInSteps += _song.notes[j].lengthInSteps;
			for (i in sectionInfo)
			{
				var daNoteInfo = i[1];
				var daStrumTime = i[0];
				var daSus = i[2];
				var daLift = i[4];
				var note = new Note(daStrumTime, daNoteInfo % 4, null, false, daLift);
				note.sustainLength = daSus;
				note.setGraphicSize(Std.int(strumLine.members[0].width));
				note.updateHitbox();
				note.x = strumLine.members[daNoteInfo].x;
				if (_song.notes[j].mustHitSection)
				{
					var sussyInfo = 0;
					if (daNoteInfo > 3)
					{
						sussyInfo = daNoteInfo % 4;
					}
					else
					{
						sussyInfo = daNoteInfo + 4;
					}
					note.x = strumLine.members[sussyInfo].x;
				}
				note.y = Math.floor(getYfromStrum(daStrumTime));
				curRenderedNotes.add(note);
				if (daSus > 0)
				{
					var sustainVis:FlxSprite = new FlxSprite(note.x + note.width / 2,
						note.y + LINE_SPACING).makeGraphic(8, Math.floor(FlxMath.remapToRange(daSus, 0, Conductor.stepCrochet * 16, 0, LINE_SPACING * 16)));
					curRenderedSus.add(sustainVis);
				}
			}
		}
	}

	private function getYfromStrum(strumTime:Float):Float
	{
		return FlxMath.remapToRange(strumTime, 0, 16 * Conductor.stepCrochet, 0, lastLineY);
	}
}
