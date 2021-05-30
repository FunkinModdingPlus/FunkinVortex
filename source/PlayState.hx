package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxGridOverlay;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.mouse.FlxMouseEventManager;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import haxe.Json;
import openfl.media.Sound;

enum abstract Snaps(Int) from Int to Int
{
	var Four;
	var Eight;
	var Twelve;
	var Sixteen;
	var Twenty;
	var TwentyFour;
	var ThirtyTwo;
	var FourtyEight;
	var SixtyFour;
	var NinetySix;
	var OneNineTwo;

	@:op(A == B) static function _(_, _):Bool;
}

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

	var openButton:FlxButton;
	var saveButton:FlxButton;
	var loadVocalsButton:FlxButton;

	var curSelectedNote:Array<Dynamic>;
	var GRID_SIZE = 40;

	var LINE_SPACING = 40;
	var camFollow:FlxObject;
	var lastLineY:Int = 0;
	var sectionMarkers:Array<Float> = [];
	var songLengthInSteps:Int = 0;
	var songSectionTimes:Array<Float> = [];
	var useLiftNote:Bool = false;
	var noteControls:Array<Bool> = [false, false, false, false, false, false, false, false];
	var noteRelease:Array<Bool> = [false, false, false, false, false, false, false, false];
	var noteHold:Array<Bool> = [false, false, false, false, false, false, false, false];
	var curSectionTxt:FlxText;
	var sectionInfo:SectionInfo;

	var toolInfo:FlxText;
	var musicSound:Sound;
	var vocals:Sound;
	var snapInfo:Snaps = Four;

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
		FlxG.mouse.useSystemCursor = true;
		openButton = new FlxButton(10, 10, "Open Chart", loadFromFile);
		saveButton = new FlxButton(10, 40, "Save Chart", function()
		{
			var json = {
				"song": _song
			};
			var data = Json.stringify(json);
			if ((data != null) && (data.length > 0))
				FNFAssets.askToSave("song", Json.stringify(_song));
		});
		loadVocalsButton = new FlxButton(10, 70, "Load vocals", function()
		{
			var future = FNFAssets.askToBrowseForPath("ogg");
			future.onComplete(function(s:String)
			{
				vocals = Sound.fromFile(s);
				FlxG.sound.playMusic(vocals);
				FlxG.sound.music.pause();
			});
		});
		LINE_SPACING = Std.int(strumLine.height);
		curSnap = LINE_SPACING * 4;
		drawChartLines();
		updateNotes();
		camFollow = new FlxObject(strumLine.getGraphicMidpoint().x, strumLine.getGraphicMidpoint().y);
		FlxG.camera.follow(camFollow, LOCKON);
		staffLines.y += strumLine.height / 2;
		snaptext = new FlxText(0, FlxG.height, 0, '4ths', 24);
		snaptext.y -= snaptext.height;
		snaptext.scrollFactor.set();
		curSectionTxt = new FlxText(200, FlxG.height, 0, 'Section: 0', 16);
		curSectionTxt.y -= curSectionTxt.height;
		curSectionTxt.scrollFactor.set();
		sectionInfo = new SectionInfo(FlxG.width - 500, 0, _song, 0);
		sectionInfo.scrollFactor.set();
		toolInfo = new FlxText(FlxG.width / 2, FlxG.height, 0, "a", 16);
		// don't immediately set text to '' because height??
		toolInfo.y -= toolInfo.height;
		toolInfo.text = 'hover over things to see what they do';
		// NOT PIXEL PERFECT
		FlxMouseEventManager.add(sectionInfo.mustHitTxt, null, null, function(s:FlxText)
		{
			toolInfo.text = "If true, camera focuses on bf. Otherwise, camera focuses on enemy. Toggle with E";
			toolInfo.x = FlxG.width - toolInfo.width;
		}, function(s:FlxText)
		{
			toolInfo.text = "hover over things to see what they do";
			toolInfo.x = FlxG.width - toolInfo.width;
		}, false, true, false);
		toolInfo.scrollFactor.set();
		add(staffLines);
		add(strumLine);
		add(curRenderedNotes);
		add(curRenderedSus);
		add(chart);
		add(snaptext);
		add(curSectionTxt);
		add(openButton);
		add(saveButton);
		add(loadVocalsButton);
		add(sectionInfo);
		add(toolInfo);
	}

	private function loadFromFile():Void
	{
		var future = FNFAssets.askToBrowse("json");
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
		noteControls = [
			FlxG.keys.justPressed.ONE,
			FlxG.keys.justPressed.TWO,
			FlxG.keys.justPressed.THREE,
			FlxG.keys.justPressed.FOUR,
			FlxG.keys.justPressed.FIVE,
			FlxG.keys.justPressed.SIX,
			FlxG.keys.justPressed.SEVEN,
			FlxG.keys.justPressed.EIGHT
		];
		noteRelease = [
			FlxG.keys.justReleased.ONE,
			FlxG.keys.justReleased.TWO,
			FlxG.keys.justReleased.THREE,
			FlxG.keys.justReleased.FOUR,
			FlxG.keys.justReleased.FIVE,
			FlxG.keys.justReleased.SIX,
			FlxG.keys.justReleased.SEVEN,
			FlxG.keys.justReleased.EIGHT
		];
		noteHold = [
			FlxG.keys.pressed.ONE,
			FlxG.keys.pressed.TWO,
			FlxG.keys.pressed.THREE,
			FlxG.keys.pressed.FOUR,
			FlxG.keys.pressed.FIVE,
			FlxG.keys.pressed.SIX,
			FlxG.keys.pressed.SEVEN,
			FlxG.keys.pressed.EIGHT
		];
		if (FlxG.keys.justPressed.UP)
		{
			moveStrumLine(-1);
		}
		else if (FlxG.keys.justPressed.DOWN)
		{
			moveStrumLine(1);
		}
		if (FlxG.keys.justPressed.E)
		{
			_song.notes[getSussySectionFromY(strumLine.y)].mustHitSection = !_song.notes[getSussySectionFromY(strumLine.y)].mustHitSection;
			sectionInfo.changeSection(getSussySectionFromY(strumLine.y));
			updateNotes();
		}
		if (FlxG.keys.justPressed.Q)
		{
			useLiftNote = !useLiftNote;
		}
		if (FlxG.keys.justPressed.RIGHT)
		{
			changeSnap(true);
		}
		else if (FlxG.keys.justPressed.LEFT)
		{
			changeSnap(false);
		}
		if (FlxG.keys.justPressed.ESCAPE && curSelectedNote != null)
		{
			curSelectedNote = null;
		}
		if (FlxG.keys.justPressed.SPACE)
		{
			if (FlxG.sound.music != null && FlxG.sound.music.playing)
			{
				FlxG.sound.music.pause();
			}
			else
			{
				FlxG.sound.music.time = getSussyStrumTime(strumLine.y);
				FlxG.sound.music.play();
			}
		}
		if (FlxG.sound.music != null && FlxG.sound.music.playing)
		{
			strumLine.y = getSussyYPos(FlxG.sound.music.time);
			sectionInfo.changeSection(getSussySectionFromY(strumLine.y));
		}
		for (i in 0...noteControls.length)
		{
			if (!noteControls[i])
				continue;
			if (FlxG.keys.pressed.CONTROL)
			{
				selectNote(i);
			}
			else if (FlxG.keys.pressed.A)
			{
				convertToRoll(i);
			}
			else
			{
				addNote(i);
			}
		}
		for (i in 0...noteRelease.length)
		{
			if (!noteRelease[i])
				continue;
			/*
				if (curSelectedNote != null && i % 4 == curSelectedNote[1] % 4)
				{
					curSelectedNote = null;
			}*/
		}
	}

	private function moveStrumLine(change:Int = 0)
	{
		strumLine.y += change * curSnap;
		strumLine.y = Math.floor(strumLine.y / curSnap) * curSnap;
		curSectionTxt.text = 'Section: ' + getSussySectionFromY(strumLine.y);
		sectionInfo.changeSection(getSussySectionFromY(strumLine.y));
		if (curSelectedNote != null)
		{
			curSelectedNote[2] = getSussyStrumTime(strumLine.y) - curSelectedNote[0];
			curSelectedNote[2] = FlxMath.bound(curSelectedNote[2], 0);
			updateNotes();
		}
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
		staffLines.makeGraphic(FlxG.width, FlxG.height * _song.notes.length, FlxColor.BLACK);
		for (i in 0..._song.notes.length)
		{
			for (o in 0..._song.notes[i].lengthInSteps)
			{
				var lineColor:FlxColor = FlxColor.GRAY;
				if (o == 0)
				{
					lineColor = FlxColor.WHITE;
					sectionMarkers.push(LINE_SPACING * ((i * 16) + o));
				}
				FlxSpriteUtil.drawLine(staffLines, FlxG.width * -0.5, LINE_SPACING * ((i * 16) + o), FlxG.width * 1.5, LINE_SPACING * ((i * 16) + o),
					{color: FlxColor.WHITE, thickness: 10});
				lastLineY = LINE_SPACING * ((i * 16) + o);
			}
		}
	}

	function convertToRoll(id:Int)
	{
		selectNote(id);
		// nothing fancy, just generate rolls
		if (curSelectedNote != null)
		{
			if (curSelectedNote[2] > 0)
			{
				for (sussy in 0...Math.floor(curSelectedNote[2] / Conductor.stepCrochet))
				{
					var goodSection = getSussySectionFromY(getSussyYPos(curSelectedNote[0] + sussy * Conductor.stepCrochet));
					var noteData = id;
					if (_song.notes[goodSection].mustHitSection)
					{
						var sussyInfo = 0;
						if (noteData > 3)
						{
							sussyInfo = noteData % 4;
						}
						else
						{
							sussyInfo = noteData + 4;
						}
						noteData = sussyInfo;
					}
					_song.notes[goodSection].sectionNotes.push([
						curSelectedNote[0] + sussy * Conductor.stepCrochet,
						noteData,
						0,
						curSelectedNote[3],
						curSelectedNote[4]
					]);
				}
			}
			curSelectedNote[2] = 0;
		}
		curSelectedNote = null;
		updateNotes();
	}

	private function addNote(id:Int):Void
	{
		var noteStrum = getSussyStrumTime(strumLine.members[id].y);
		var noteData = id;
		var noteSus = 0;
		var curSection = getSussySectionFromY(strumLine.members[id].y);
		if (_song.notes[curSection].mustHitSection)
		{
			var sussyInfo = 0;
			if (noteData > 3)
			{
				sussyInfo = noteData % 4;
			}
			else
			{
				sussyInfo = noteData + 4;
			}
			noteData = sussyInfo;
		}
		var goodArray:Array<Dynamic> = [noteStrum, noteData, noteSus, false, useLiftNote];
		for (note in _song.notes[curSection].sectionNotes)
		{
			if (CoolUtil.truncateFloat(note[0], 1) == CoolUtil.truncateFloat(goodArray[0], 1) && note[1] == noteData)
			{
				_song.notes[curSection].sectionNotes.remove(note);
				updateNotes();
				return;
			}
		}
		_song.notes[curSection].sectionNotes.push([noteStrum, noteData, noteSus, false, useLiftNote]);

		updateNotes();
	}

	private function changeSnap(increase:Bool)
	{
		// i have no idea why it isn't throwing a hissy fit. Let's keep it that way.
		if (increase)
		{
			snapInfo += 1;
		}
		else
		{
			snapInfo -= 1;
		}
		snapInfo = cast FlxMath.wrap(cast snapInfo, 0, cast(OneNineTwo));
		switch (snapInfo)
		{
			case Four:
				snaptext.text = '4ths';
				curSnap = (LINE_SPACING * 16) / 4;
			case Eight:
				snaptext.text = '8ths';
				curSnap = (LINE_SPACING * 16) / 8;
			case Twelve:
				snaptext.text = '12ths';
				curSnap = (LINE_SPACING * 16) / 12;
			case Sixteen:
				snaptext.text = '16ths';
				curSnap = (LINE_SPACING * 16) / 16;
			case Twenty:
				snaptext.text = '20ths';
				curSnap = (LINE_SPACING * 16) / 20;
			case TwentyFour:
				snaptext.text = '24ths';
				curSnap = (LINE_SPACING * 16) / 24;
			case ThirtyTwo:
				snaptext.text = '32nds';
				curSnap = (LINE_SPACING * 16) / 32;
			case FourtyEight:
				snaptext.text = '48ths';
				curSnap = (LINE_SPACING * 16) / 48;
			case SixtyFour:
				snaptext.text = '64ths';
				curSnap = (LINE_SPACING * 16) / 64;
			case NinetySix:
				snaptext.text = '96ths';
				curSnap = (LINE_SPACING * 16) / 96;
			case OneNineTwo:
				snaptext.text = '192nds';
				curSnap = (LINE_SPACING * 16) / 192;
		}
	}

	private function selectNote(id:Int):Void
	{
		var noteStrum = getSussyStrumTime(strumLine.members[id].y);
		var noteData = id;
		var noteSus = 0;
		var curSection = getSussySectionFromY(strumLine.members[id].y);
		if (_song.notes[curSection].mustHitSection)
		{
			var sussyInfo = 0;
			if (noteData > 3)
			{
				sussyInfo = noteData % 4;
			}
			else
			{
				sussyInfo = noteData + 4;
			}
			noteData = sussyInfo;
		}
		var goodArray:Array<Dynamic> = [noteStrum, noteData, noteSus, false, useLiftNote];
		for (note in _song.notes[curSection].sectionNotes)
		{
			if (CoolUtil.truncateFloat(note[0], 1) == CoolUtil.truncateFloat(goodArray[0], 1) && note[1] == noteData)
			{
				curSelectedNote = note;
				updateNotes();
				return;
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
			songSectionTimes.push(songLengthInSteps);
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
				note.y = Math.floor(getYfromStrum(daStrumTime, j));
				curRenderedNotes.add(note);
				if (daSus > 0)
				{
					var sustainVis:FlxSprite = new FlxSprite(note.x + note.width / 2,
						note.y + LINE_SPACING).makeGraphic(8, Math.floor(FlxMath.remapToRange(daSus, 0, Conductor.stepCrochet * 16, 0, LINE_SPACING * 16)),
						FlxColor.BLUE);
					curRenderedSus.add(sustainVis);
				}
			}
		}
	}

	private function getYfromStrum(strumTime:Float, section:Int):Float
	{
		return FlxMath.remapToRange(strumTime, sectionStartTime(section), sectionStartTime(section + 1), sectionMarkers[section], sectionMarkers[section + 1]);
	}

	private function getStrumTime(yPos:Float, section:Int):Float
	{
		return FlxMath.remapToRange(yPos, sectionMarkers[section], sectionMarkers[section + 1], sectionStartTime(section), sectionStartTime(section + 1));
	}

	// Should be called "getAmbiguousStrumTime", too lazy to name it that
	private function getSussyStrumTime(yPos:Float):Float
	{
		for (i in 0..._song.notes.length)
		{
			if (yPos >= sectionMarkers[i] && yPos < sectionMarkers[i + 1])
			{
				return getStrumTime(yPos, i);
			}
		}
		return 0;
	}

	private function getSussyYPos(strumTime:Float):Float
	{
		for (i in 0..._song.notes.length)
		{
			if (strumTime >= sectionStartTime(i) && strumTime < sectionStartTime(i + 1))
			{
				return getYfromStrum(strumTime, i);
			}
		}
		return 0;
	}

	function getSussySectionFromY(yPos:Float):Int
	{
		for (i in 0..._song.notes.length)
		{
			if (yPos >= sectionMarkers[i] && yPos < sectionMarkers[i + 1])
			{
				return i;
			}
		}
		return 0;
	}

	function sectionStartTime(section:Int):Float
	{
		var daBPM:Int = _song.bpm;
		var daPos:Float = 0;
		for (i in 0...section)
		{
			if (_song.notes[i].changeBPM)
			{
				daBPM = _song.notes[i].bpm;
			}
			daPos += 4 * (1000 * 60 / daBPM);
		}
		return daPos;
	}
}
