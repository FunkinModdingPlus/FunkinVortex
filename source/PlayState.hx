package;

import Song.SwagSong;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUIState;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.weapon.FlxBullet;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.mouse.FlxMouseEventManager;
import flixel.math.FlxMath;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import haxe.Json;
import haxe.ui.Toolkit;
import haxe.ui.components.Button;
import haxe.ui.components.CheckBox;
import haxe.ui.components.NumberStepper;
import haxe.ui.components.Stepper;
import haxe.ui.components.TextField;
import haxe.ui.containers.TabView;
import haxe.ui.containers.VBox;
import haxe.ui.containers.menus.Menu;
import haxe.ui.containers.menus.MenuBar;
import haxe.ui.containers.menus.MenuItem;
import haxe.ui.core.Component;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;
import haxe.ui.macros.ComponentMacros;
import haxe.ui.styles.Style;
import openfl.media.Sound;

// import bulbytools.Assets;

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
// i should be using tab menu... oh well
// we don't have to worry about backspaces ^-^
class PlayState extends FlxUIState
{
	static var _song:Song.SwagSong;

	var chart:FlxSpriteGroup;
	var staffLines:FlxSprite;
	var strumLine:FlxSpriteGroup;
	var curRenderedNotes:FlxSpriteGroup;
	var curRenderedSus:FlxSpriteGroup;
	var snaptext:FlxText;
	var curSnap:Float = 0;

	// var ui_box:FlxUITabMenu;
	// var haxeUIOpen:Button;
	// var openButton:FlxButton;
	// var saveButton:FlxButton;
	// var exportButton:FlxButton;
	// var loadVocalsButton:FlxButton;
	// var loadInstButton:FlxButton;
	// var sectionTabBtn:FlxButton;
	// var noteTabBtn:FlxButton;
	var menuBar:MenuBar;
	var curSelectedNote:Array<Dynamic>;
	var GRID_SIZE = 40;
	var tabviewThingy:Component;
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

	// var player1TextField:FlxUIInputText;
	// var enemyTextField:FlxUIInputText;
	// var gfTextField:FlxUIInputText;
	// var stageTextField:FlxUIInputText;
	// var cutsceneTextField:FlxUIInputText;
	// var uiTextField:FlxUIInputText;
	var toolInfo:FlxText;
	var musicSound:Sound;
	var vocals:Sound;

	static var vocalSound:FlxSound;

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
		// i think UIs in code get out of hand fast and i know others prefer it so.. - creator of the ui thing
		menuBar = new MenuBar();
		menuBar.customStyle.width = FlxG.width;
		var fileMenu = new Menu();
		fileMenu.text = "File";
		var saveChartMenu = new MenuItem();
		saveChartMenu.text = "Save Chart";
		saveChartMenu.onClick = function(e:MouseEvent)
		{
			updateTextParams();
			var json = {
				"song": _song,
				"generatedBy": "ModdingPlus",
				"programUsed": "FunkinVortex"
			};
			var data = Json.stringify(json);
			if ((data != null) && (data.length > 0))
				FNFAssets.askToSave("song", data);
		};
		var openChartMenu = new MenuItem();
		openChartMenu.text = "Open Chart";
		openChartMenu.onClick = function(e:MouseEvent)
		{
			var future = FNFAssets.askToBrowse("json");
			future.onComplete(function(s:String)
			{
				_song = Song.loadFromJson(s);
				FlxG.resetState();
			});
		};
		var loadInstMenu = new MenuItem();
		loadInstMenu.text = "Load Instrument";
		loadInstMenu.onClick = function(e:MouseEvent)
		{
			var future = FNFAssets.askToBrowseForPath("ogg");
			future.onComplete(function(s:String)
			{
				musicSound = Sound.fromFile(s);
				FlxG.sound.playMusic(musicSound);
				FlxG.sound.music.pause();
			});
		};
		var loadVoiceMenu = new MenuItem();
		loadVoiceMenu.text = "Load Vocals";
		loadVoiceMenu.onClick = function(e:MouseEvent)
		{
			var future = FNFAssets.askToBrowseForPath("ogg");
			future.onComplete(function(s:String)
			{
				vocals = Sound.fromFile(s);
				vocalSound = FlxG.sound.load(vocals);
			});
		};
		var exportMenu = new MenuItem();
		exportMenu.text = "Export to base game";
		exportMenu.onClick = function(e:MouseEvent)
		{
			updateTextParams();
			var cloneThingie = new Cloner();

			var sussySong:SwagSong = cloneThingie.clone(_song);
			// WE HAVE TO STRIP OUT ALL THE GOOD STUFF :grief:
			Reflect.deleteField(sussySong, "gf");
			Reflect.deleteField(sussySong, "stage");
			Reflect.deleteField(sussySong, "isMoody");
			Reflect.deleteField(sussySong, "isSpooky");
			Reflect.deleteField(sussySong, "uiType");
			Reflect.deleteField(sussySong, "cutsceneType");
			Reflect.deleteField(sussySong, "isHey");
			Reflect.deleteField(sussySong, "isCheer");
			for (i in 0...sussySong.notes.length)
			{
				for (j in 0...sussySong.notes[i].sectionNotes.length)
				{
					var noteThingie:Array<Dynamic> = sussySong.notes[i].sectionNotes[j];
					// remove lift info
					noteThingie[4] = null;
					if ((noteThingie[3] is Int))
					{
						if (noteThingie[3] > 0)
							noteThingie[3] = true;
						else
							noteThingie[3] = false;
					}
				}
				Reflect.deleteField(sussySong.notes[i], "altAnimNum");
			}
			var json = {
				"song": sussySong,
				"generatedBy": "SNIFF ver.6",
				"programUsed": "FunkinVortex"
			};
			var data = Json.stringify(json);
			if ((data != null) && (data.length > 0))
				FNFAssets.askToSave("song", data);
		};
		fileMenu.addComponent(saveChartMenu);
		fileMenu.addComponent(openChartMenu);
		fileMenu.addComponent(exportMenu);
		fileMenu.addComponent(loadInstMenu);
		fileMenu.addComponent(loadVoiceMenu);
		menuBar.addComponent(fileMenu);
		tabviewThingy = ComponentMacros.buildComponent('assets/data/tabmenu.xml');
		tabviewThingy.findComponent("bfText", TextField).text = _song.player1;
		tabviewThingy.findComponent("enemyText", TextField).text = _song.player2;
		tabviewThingy.findComponent("gfText", TextField).text = _song.gf;
		tabviewThingy.findComponent("stageText", TextField).text = _song.stage;
		tabviewThingy.findComponent("cutsceneText", TextField).text = _song.cutsceneType;
		tabviewThingy.findComponent("uiText", TextField).text = _song.uiType;
		tabviewThingy.findComponent("songTitle", TextField).text = _song.song;
		tabviewThingy.findComponent("needsVoices", CheckBox).onChange = function(e:UIEvent)
		{
			_song.needsVoices = tabviewThingy.findComponent("needsVoices", CheckBox).selected;
		};
		tabviewThingy.findComponent("needsVoices", CheckBox).selected = _song.needsVoices;
		tabviewThingy.findComponent("muteInst", CheckBox).onChange = function(_)
		{
			var vol:Float = 1;
			if (tabviewThingy.findComponent("muteInst", CheckBox).selected)
				vol = 0;
			if (FlxG.sound.music != null)
				FlxG.sound.music.volume = vol;
		};
		tabviewThingy.findComponent("isspooky", CheckBox).onChange = function(e:UIEvent)
		{
			_song.isSpooky = tabviewThingy.findComponent("isspooky", CheckBox).selected;
		};
		tabviewThingy.findComponent("isspooky", CheckBox).selected = _song.isSpooky;
		tabviewThingy.findComponent("ismoody", CheckBox).onChange = function(e:UIEvent)
		{
			_song.isMoody = tabviewThingy.findComponent("ismoody", CheckBox).selected;
		};
		tabviewThingy.findComponent("ismoody", CheckBox).selected = _song.isMoody;
		tabviewThingy.findComponent("ishey", CheckBox).onChange = function(e:UIEvent)
		{
			_song.isHey = tabviewThingy.findComponent("ishey", CheckBox).selected;
		};
		tabviewThingy.findComponent("ishey", CheckBox).selected = _song.isHey;
		tabviewThingy.findComponent("ischeer", CheckBox).onChange = function(e:UIEvent)
		{
			_song.isCheer = tabviewThingy.findComponent("ischeer", CheckBox).selected;
		};
		tabviewThingy.findComponent("ischeer", CheckBox).selected = _song.isCheer;
		tabviewThingy.findComponent("swapsection", Button).onClick = function(_)
		{
			var curSection = getSussySectionFromY(strumLine.y);
			if (_song.notes[curSection] == null)
				return;
			for (i in 0..._song.notes[curSection].sectionNotes.length)
			{
				var note = _song.notes[curSection].sectionNotes[i];
				note[1] = (note[1] + 4) % 8;
				_song.notes[curSection].sectionNotes[i] = note;
			}
			updateNotes();
		};
		tabviewThingy.findComponent("addsection", Button).onClick = function(_)
		{
			addSection();
		};
		tabviewThingy.findComponent("clearsection", Button).onClick = function(_)
		{
			var curSection = getSussySectionFromY(strumLine.y);
			if (_song.notes[curSection] == null)
				return;
			_song.notes[curSection].sectionNotes = [];
			updateNotes();
		};
		tabviewThingy.findComponent("musthitsection", CheckBox).onChange = function(e:UIEvent)
		{
			var curSection = getSussySectionFromY(strumLine.y);
			if (_song.notes[curSection] != null)
				_song.notes[curSection].mustHitSection = tabviewThingy.findComponent("musthitsection", CheckBox).selected;
			updateNotes();
		};
		tabviewThingy.findComponent("musthitsection", CheckBox).selected = false;
		tabviewThingy.findComponent("changebpmsection", CheckBox).onChange = function(e:UIEvent)
		{
			var curSection = getSussySectionFromY(strumLine.y);
			if (_song.notes[curSection] != null)
				_song.notes[curSection].changeBPM = tabviewThingy.findComponent("changebpmsection", CheckBox).selected;
		};
		tabviewThingy.findComponent("changebpmsection", CheckBox).selected = false;
		tabviewThingy.findComponent("altnotecheck", CheckBox).onChange = function(e:UIEvent)
		{
			if (curSelectedNote != null)
			{
				curSelectedNote[3] = tabviewThingy.findComponent("altnotecheck", CheckBox).selected ? 1 : 0;
			}
			updateNoteUI();
		};
		tabviewThingy.findComponent("altnotecheck", CheckBox).selected = false;
		tabviewThingy.findComponent("sectionlength", NumberStepper).onChange = function(_)
		{
			var curSection = getSussySectionFromY(strumLine.y);
			if (_song.notes[curSection] != null)
				_song.notes[curSection].lengthInSteps = Std.int(tabviewThingy.findComponent("sectionlength", NumberStepper).pos);
			updateNotes();
		};
		tabviewThingy.findComponent("songspeed", NumberStepper).onChange = function(_)
		{
			_song.speed = tabviewThingy.findComponent("songspeed", NumberStepper).pos;
		};
		tabviewThingy.findComponent("songspeed", NumberStepper).pos = _song.speed;
		tabviewThingy.findComponent("songbpm", NumberStepper).onChange = function(_)
		{
			tempBpm = Std.int(tabviewThingy.findComponent("songbpm", NumberStepper).pos);
			Conductor.mapBPMChanges(_song);
			Conductor.changeBPM(tempBpm);
		};
		tabviewThingy.findComponent("songbpm", NumberStepper).pos = _song.bpm;
		tabviewThingy.findComponent("sectionbpm", NumberStepper).onChange = function(_)
		{
			var curSection = getSussySectionFromY(strumLine.y);
			if (_song.notes[curSection] != null)
				_song.notes[curSection].bpm = Std.int(tabviewThingy.findComponent("sectionbpm", NumberStepper).pos);
			updateNotes();
		};
		tabviewThingy.findComponent("altsection", NumberStepper).onChange = function(_)
		{
			var curSection = getSussySectionFromY(strumLine.y);
			if (_song.notes[curSection] != null)
				_song.notes[curSection].altAnimNum = Std.int(tabviewThingy.findComponent("altsection", NumberStepper).pos);

			updateNotes();
		};
		tabviewThingy.findComponent("altnotestep", NumberStepper).onChange = function(_)
		{
			if (curSelectedNote != null)
				curSelectedNote[3] = tabviewThingy.findComponent("altnotestep", NumberStepper).pos;
			updateNoteUI();
		};
		tabviewThingy.x = FlxG.width / 2;
		tabviewThingy.y = 100;
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
		toolInfo = new FlxText(FlxG.width / 2, FlxG.height, 0, "a", 16);
		// don't immediately set text to '' because height??
		toolInfo.y -= toolInfo.height;
		toolInfo.text = 'hover over things to see what they do';
		// NOT PIXEL PERFECT
		toolInfo.scrollFactor.set();
		tempBpm = _song.bpm;
		Conductor.changeBPM(_song.bpm);
		Conductor.mapBPMChanges(_song);
		// addUI();
		add(staffLines);
		add(strumLine);
		add(curRenderedNotes);
		add(curRenderedSus);
		add(chart);
		add(snaptext);
		add(curSectionTxt);
		// add(openButton);

		add(menuBar);
		// add(saveButton);
		// add(loadVocalsButton);
		// add(loadInstButton);
		add(toolInfo);
		// add(ui_box);
		add(tabviewThingy);
		// add(haxeUIOpen);
	}

	function addSection(lengthInSteps:Int = 16)
	{
		var sec:Section.SwagSection = {
			lengthInSteps: lengthInSteps,
			bpm: _song.bpm,
			changeBPM: false,
			mustHitSection: true,
			sectionNotes: [],
			typeOfSection: 0,
			altAnim: false,
			altAnimNum: 0
		};

		_song.notes.push(sec);
	}

	// can't think of a good name for this; all this do is just set all the songs params to things from the tabmenu
	function updateTextParams()
	{
		_song.player1 = tabviewThingy.findComponent("bfText", TextField).text;
		_song.player2 = tabviewThingy.findComponent("enemyText", TextField).text;
		_song.gf = tabviewThingy.findComponent("gfText", TextField).text;
		_song.stage = tabviewThingy.findComponent("stageText", TextField).text;
		_song.cutsceneType = tabviewThingy.findComponent("cutsceneText", TextField).text;
		_song.uiType = tabviewThingy.findComponent("uiText", TextField).text;
		_song.song = tabviewThingy.findComponent("songTitle", TextField).text;
	}

	/*
		var stepperLength:FlxUINumericStepper;
		var stepperAltAnim:FlxUINumericStepper;
		var check_mustHitSection:FlxUICheckBox;
		var check_changeBPM:FlxUICheckBox;
		var stepperSectionBPM:FlxUINumericStepper;
		var stepperAltNote:FlxUINumericStepper;

		/*
			function addUI()
			{
				var songTitle = new FlxUIInputText(10, 10, 70, _song.song, 8);

				var check_voices = new FlxUICheckBox(10, 25, null, null, "Has Voices", 100);
				check_voices.checked = _song.needsVoices;
				check_voices.callback = function()
				{
					_song.needsVoices = check_voices.checked;
				};

				var check_mute_inst = new FlxUICheckBox(10, 200, null, null, "Mute Inst in Editor", 100);
				check_mute_inst.checked = false;
				check_mute_inst.callback = function()
				{
					var vol:Float = 1;
					if (check_mute_inst.checked)
						vol = 0;
					if (FlxG.sound.music != null)
						FlxG.sound.music.volume = vol;
				};

				var check_spooky = new FlxUICheckBox(10, 280, null, null, "Is Spooky", 100);
				check_spooky.checked = _song.isSpooky;
				check_spooky.callback = function()
				{
					_song.isSpooky = check_spooky.checked;
				};

				var stepperSpeed = new FlxUINumericStepper(10, 80, 0.1, 1, 0.1, 10, 1);
				stepperSpeed.value = _song.speed;
				stepperSpeed.name = 'song_speed';

				var stepperBPM = new FlxUINumericStepper(10, 65, 1, 1, 1, 339, 0);
				stepperBPM.value = Conductor.bpm;
				stepperBPM.name = 'song_bpm';

				player1TextField = new FlxUIInputText(10, 100, 70, _song.player1, 8);
				enemyTextField = new FlxUIInputText(80, 100, 70, _song.player2, 8);
				gfTextField = new FlxUIInputText(10, 120, 70, _song.gf, 8);
				stageTextField = new FlxUIInputText(80, 120, 70, _song.stage, 8);
				cutsceneTextField = new FlxUIInputText(80, 140, 70, _song.cutsceneType, 8);
				uiTextField = new FlxUIInputText(10, 140, 70, _song.uiType, 8);
				var isMoodyCheck = new FlxUICheckBox(10, 220, null, null, "Is Moody", 100);
				isMoodyCheck.checked = _song.isMoody;
				isMoodyCheck.callback = function()
				{
					_song.isMoody = isMoodyCheck.checked;
				};
				var isHeyCheck = new FlxUICheckBox(10, 250, null, null, "Is Hey", 100);
				isHeyCheck.checked = _song.isHey;
				isHeyCheck.callback = function()
				{
					_song.isHey = isHeyCheck.checked;
				};
				var isCheerCheck = new FlxUICheckBox(100, 250, null, null, "Is Cheer", 100);
				isCheerCheck.checked = _song.isCheer;
				isCheerCheck.callback = function()
				{
					_song.isCheer = isCheerCheck.checked;
				};
				var tab_group_song = new FlxUI(null, ui_box);
				tab_group_song.name = "Song";
				tab_group_song.add(songTitle);
				tab_group_song.add(check_voices);
				tab_group_song.add(check_mute_inst);
				tab_group_song.add(isMoodyCheck);
				tab_group_song.add(isHeyCheck);
				tab_group_song.add(isCheerCheck);
				tab_group_song.add(check_spooky);
				tab_group_song.add(stepperBPM);
				tab_group_song.add(stepperSpeed);

				ui_box.addGroup(tab_group_song);
				ui_box.scrollFactor.set();
				var tab_group_char = new FlxUI(null, ui_box);
				tab_group_char.name = "Char";

				tab_group_char.add(uiTextField);
				tab_group_char.add(cutsceneTextField);
				tab_group_char.add(stageTextField);
				tab_group_char.add(gfTextField);
				tab_group_char.add(player1TextField);
				tab_group_char.add(enemyTextField);
				ui_box.addGroup(tab_group_char);
				ui_box.scrollFactor.set();

				var tab_group_section = new FlxUI(null, ui_box);
				tab_group_section.name = 'Section';

				stepperLength = new FlxUINumericStepper(10, 10, 4, 0, 0, 999, 0);
				stepperLength.value = 0;
				stepperLength.name = 'section_length';

				stepperSectionBPM = new FlxUINumericStepper(10, 80, 1, Conductor.bpm, 0, 999, 0);
				stepperSectionBPM.name = 'section_bpm';

				stepperAltAnim = new FlxUINumericStepper(10, 200, 1, 0, 0, 999, 0);
				stepperAltAnim.name = 'alt_anim_number';

				// todo, copy thingies

				// todo, clear section

				var swapSection:FlxButton = new FlxButton(10, 170, "Swap Section", function()
				{
					var curSection = getSussySectionFromY(strumLine.y);
					for (i in 0..._song.notes[curSection].sectionNotes.length)
					{
						var note = _song.notes[curSection].sectionNotes[i];
						note[1] = (note[1] + 4) % 8;
						_song.notes[curSection].sectionNotes[i] = note;
					}
					updateNotes();
				});

				check_mustHitSection = new FlxUICheckBox(10, 30, null, null, "Must hit section", 100);
				check_mustHitSection.name = 'check_mustHit';
				check_mustHitSection.checked = true;

				check_changeBPM = new FlxUICheckBox(10, 60, null, null, 'Change BPM', 100);
				check_changeBPM.name = 'check_changeBPM';

				tab_group_section.add(stepperLength);
				tab_group_section.add(stepperSectionBPM);
				tab_group_section.add(check_mustHitSection);
				tab_group_section.add(stepperAltAnim);
				tab_group_section.add(check_changeBPM);
				tab_group_section.add(swapSection);

				ui_box.addGroup(tab_group_section);

				var tab_group_note = new FlxUI(null, ui_box);
				tab_group_note.name = 'Note';

				stepperAltNote = new FlxUINumericStepper(10, 200, 1, 0, 0, 999, 0);
				stepperAltNote.value = 0;
				stepperAltNote.name = 'alt_anim_note';

				isAltNoteCheck = new FlxUICheckBox(10, 100, null, null, "Alt Anim Note", 100);
				isAltNoteCheck.name = "isAltNote";
				tab_group_note.add(stepperAltNote);
				tab_group_note.add(isAltNoteCheck);
				ui_box.addGroup(tab_group_note);
			}
	 */
	// var isAltNoteCheck:FlxUICheckBox;

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
	{
		if (strumLine == null)
			return;
		var curSection = getSussySectionFromY(strumLine.y);
		if (id == FlxUICheckBox.CLICK_EVENT)
		{
			var check:FlxUICheckBox = cast sender;
			var label = check.getLabel().text;
			switch (label)
			{
				case 'Must hit section':
					_song.notes[curSection].mustHitSection = check.checked;
					updateNotes();

				case 'Change BPM':
					_song.notes[curSection].changeBPM = check.checked;
					FlxG.log.add('changed bpm shit');
				case "Alt Animation":
				// _song.notes[curSection].altAnim = check.checked;
				case "Is Moody":
					_song.isMoody = check.checked;
				case "Is Spooky":
					_song.isSpooky = check.checked;
				case "Is Hey":
					_song.isHey = check.checked;
				case 'Alt Anim Note':
					if (curSelectedNote != null)
					{
						curSelectedNote[3] = check.checked ? 1 : 0;
					}
					updateNoteUI();
				case 'Is Cheer':
					_song.isCheer = check.checked;
			}
		}
		else if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper))
		{
			var nums:FlxUINumericStepper = cast sender;
			var wname = nums.name;

			FlxG.log.add(wname);
			if (wname == 'section_length')
			{
				_song.notes[curSection].lengthInSteps = Std.int(nums.value);
				updateNotes();
			}
			else if (wname == 'song_speed')
			{
				_song.speed = nums.value;
			}
			else if (wname == 'song_bpm')
			{
				tempBpm = Std.int(nums.value);
				Conductor.mapBPMChanges(_song);
				Conductor.changeBPM(Std.int(nums.value));
			}
			else if (wname == 'note_susLength')
			{
				curSelectedNote[2] = nums.value;
				updateNotes();
			}
			else if (wname == 'section_bpm')
			{
				_song.notes[curSection].bpm = Std.int(nums.value);
				updateNotes();
			}
			else if (wname == 'alt_anim_number')
			{
				_song.notes[curSection].altAnimNum = Std.int(nums.value);
			}
			else if (wname == 'alt_anim_note')
			{
				if (curSelectedNote != null)
					curSelectedNote[3] = nums.value;
				updateNoteUI();
			}
		}

		// FlxG.log.add(id + " WEED " + sender + " WEED " + data + " WEED " + params);
	}

	var tempBpm:Int = 0;

	function updateNoteUI():Void
	{
		if (curSelectedNote != null)
		{
			// stepperSusLength.value = curSelectedNote[2];
			// null is falsy
			tabviewThingy.findComponent("altnotecheck", CheckBox).selected = cast curSelectedNote[3];
			tabviewThingy.findComponent("altnotestep", NumberStepper).pos = curSelectedNote[3] != null ? curSelectedNote[3] : 0;
		}
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
			// sectionInfo.changeSection(getSussySectionFromY(strumLine.y));
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
			deselectNote();
		}
		if (FlxG.keys.justPressed.HOME)
		{
			strumLine.y = 0;
			moveStrumLine(0);
		}
		/*
			if (curSelectedNote != null)
			{
				curSelectedNote[3] = Std.int(noteInfo.stepperAltNote.value);
		}*/
		if (FlxG.keys.justPressed.SPACE && FlxG.sound.music != null)
		{
			if (FlxG.sound.music.playing)
			{
				FlxG.sound.music.pause();
				if (_song.needsVoices && vocalSound != null)
				{
					vocalSound.pause();
				}
			}
			else
			{
				FlxG.sound.music.time = getSussyStrumTime(strumLine.y);
				FlxG.sound.music.play();
				if (_song.needsVoices && vocalSound != null)
				{
					vocalSound.play();
				}
			}
		}
		if (FlxG.sound.music != null && FlxG.sound.music.playing)
		{
			strumLine.y = getSussyYPos(FlxG.sound.music.time);
			curSectionTxt.text = 'Section: ' + getSussySectionFromY(strumLine.y);
			// sectionInfo.changeSection(getSussySectionFromY(strumLine.y));
			if (_song.needsVoices && vocalSound != null && !CoolUtil.nearlyEquals(vocalSound.time, FlxG.sound.music.time, 2))
			{
				vocalSound.time = FlxG.sound.music.time;
			}
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
		}
	}

	private function moveStrumLine(change:Int = 0)
	{
		strumLine.y += change * curSnap;
		if (change != 0)
			strumLine.y = Math.floor(strumLine.y / curSnap) * curSnap;
		curSectionTxt.text = 'Section: ' + getSussySectionFromY(strumLine.y);
		// sectionInfo.changeSection(getSussySectionFromY(strumLine.y));
		updateUI();
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

	private function updateUI()
	{
		updateNoteUI();
		var curSection = getSussySectionFromY(strumLine.y);
		if (_song.notes[curSection] != null)
		{
			tabviewThingy.findComponent("sectionbpm", NumberStepper).pos = _song.notes[curSection].bpm;
			tabviewThingy.findComponent("altsection", NumberStepper).pos = _song.notes[curSection].altAnimNum;
			tabviewThingy.findComponent("musthitsection", CheckBox).selected = _song.notes[curSection].mustHitSection;
			tabviewThingy.findComponent("changebpmsection", CheckBox).selected = _song.notes[curSection].changeBPM;
			tabviewThingy.findComponent("sectionlength", NumberStepper).pos = _song.notes[curSection].lengthInSteps;
		}
	}

	private function drawChartLines()
	{
		staffLines.makeGraphic(FlxG.width, FlxG.height * _song.notes.length, FlxColor.TRANSPARENT);
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
					{color: lineColor, thickness: 5});
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
		deselectNote();
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

	private function deselectNote():Void
	{
		curSelectedNote = null;
		// sectionInfo.visible = true;
		// noteInfo.visible = false;
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
				// sectionInfo.visible = false;
				// noteInfo.visible = true;
				// noteInfo.updateNote(curSelectedNote);
				updateNotes();
				updateNoteUI();
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
		drawChartLines();
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
