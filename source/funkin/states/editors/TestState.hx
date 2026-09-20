package funkin.states.editors;

import flixel.addons.ui.interfaces.IFlxUIWidget;
import flixel.text.FlxText;
import funkin.objects.ui.CustomFlxUI.CustomFlxUIDropDownMenu;
import funkin.data.StageData;
import flixel.util.FlxColor;
import funkin.objects.Alphabet;
import funkin.input.Controls;
import funkin.states.TitleState;
import funkin.states.editors.MasterEditorMenu;
import flixel.addons.ui.*;
import flixel.math.*;
import flixel.group.FlxGroup;
import flixel.ui.FlxButton;

// cringe

class TestState extends funkin.states.base.CustomFlxUIState {
	var UI_box:FlxUITabMenu;
	var alphGroup:FlxTypedGroup<FlxBasic>;
	var titlGroup:FlxTypedGroup<FlxBasic>;
	var coolbgGroup:FlxTypedGroup<FlxBasic>;

	////
	var stage:Stage = null;
	var logoBl:TitleLogo = null;

	////
	public var camGame:FlxCamera = new FlxCamera();
	public var camHUD:FlxCamera = new FlxCamera();

	var camFollow = new FlxPoint(640, 360);
	var camFollowPos = new FlxObject(640, 360, 1, 1);

	override function create()
	{
		FlxG.mouse.visible = true;

		// Set up cameras
		camGame.bgColor = 0xFF999999;
		camHUD.bgColor = 0x00000000;
		camGame.follow(camFollowPos);

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);

		FlxG.cameras.setDefaultDrawTarget(camGame, true);

		////
		var tabs = [
			{name: 'Alphabet', label: 'Alphabet'},
			{name: 'Title Screen', label: 'Title Screen'},
			{name: 'Cool BG', label: 'Cool BG'},
		];
		UI_box = new FlxUITabMenu(null, tabs, true);
		UI_box.resize(270, 200);
		UI_box.scrollFactor.set();
		UI_box.cameras = [camHUD];

		alphGroup = createAlphabetUI();
		titlGroup = createTitleUI();
		coolbgGroup = createCoolBGUI();

		UI_box.selected_tab_id = 'Alphabet';
		curGroup = alphGroup;

		super.create();
	}

	var updateFunction:Void->Void;
	var lastGroup:FlxTypedGroup<FlxBasic>;
	var curGroup:FlxTypedGroup<FlxBasic>;
	
	override function update(elapsed:Float)
	{
		if (updateFunction != null)
			updateFunction();

		if (FlxG.keys.justPressed.ESCAPE)
		{
			MusicBeatState.switchState(new MasterEditorMenu());
			MusicBeatState.playMenuMusic(true);
		}

		if (curGroup != lastGroup){
			remove(lastGroup);
			add(curGroup);
			lastGroup = curGroup;
		}

		var lerpVal:Float = Math.exp(-elapsed * 2.4);
		camFollowPos.setPosition(
			FlxMath.lerp(camFollow.x, camFollowPos.x, lerpVal),
			FlxMath.lerp(camFollow.y, camFollowPos.y, lerpVal)
		);
		
		super.update(elapsed);
	}
	
	override function getEvent(name:String, sender:IFlxUIWidget, data:Dynamic, ?params:Array<Dynamic>) {
		if (name == FlxUITabMenu.CLICK_EVENT) {
			switch (data) {
				case "Alphabet":
					curGroup = alphGroup;
					camGame.bgColor = 0xFF999999;

				case "Title Screen":
					curGroup = titlGroup;
					updateStageCamera();

				case "Cool BG":
					curGroup = coolbgGroup;

					camGame.zoom = 1;
					camGame.bgColor = 0;
					camFollow.set(FlxG.width / 2, FlxG.height / 2);
					camFollowPos.setPosition(FlxG.width / 2, FlxG.height / 2);
			}
		}
	}

	function createAlphabetUI()
	{
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Alphabet";
		UI_box.addGroup(tab_group);

		var group = new FlxTypedGroup<FlxBasic>();
		group.add(UI_box);

		var alphabetBG = new FlxSprite().makeGraphic(1, 1);
		alphabetBG.color = 0xFFFF0000;
		alphabetBG.alpha = 0.6;
		alphabetBG.cameras = [camHUD];
		group.add(alphabetBG);

		var alphabetInstance = new Alphabet(0, 0, "sowy", true);
		alphabetInstance.screenCenter();
		alphabetInstance.cameras = [camHUD];
		group.add(alphabetInstance);

		////
		var inputText = new FlxUIInputText(10, 40, 230, 'abcdefghijklmnopqrstuvwxyz', 8);
		var boldCheckbox:FlxUICheckBox = new FlxUICheckBox(10, 70, null, null, "Bold", 100);

		function updateText(){
			alphabetInstance.bold = boldCheckbox.checked;
			alphabetInstance.text = inputText.text;
			alphabetInstance.screenCenter();

			alphabetBG.scale.set(alphabetInstance.width, alphabetInstance.height);
			alphabetBG.updateHitbox();
			//alphabetBG.screenCenter();
			
			alphabetBG.x = alphabetInstance.x;
			alphabetBG.y = alphabetInstance.y;
			
		}
		updateText();
		
		////
		inputText.focusGained = function(){
			FNFGame.specialKeysEnabled = false;
			updateFunction = function(){ if (FlxG.keys.justPressed.ENTER) inputText.focusLost();}
		};
		inputText.focusLost = function(){
			FNFGame.specialKeysEnabled = true;

			inputText.hasFocus = false;
			updateFunction = null;
			updateText();
		};
		tab_group.add(inputText);
		
		boldCheckbox.callback = updateText;
		tab_group.add(boldCheckbox);

		var woo:Bool = false;
		var changeButton = new FlxButton(10, 100, "toUpperCase");
		changeButton.onUp.callback = function()
		{
			inputText.text = woo ? inputText.text.toLowerCase() : inputText.text.toUpperCase();
			changeButton.text = woo ? "toUpperCase" : "toLowerCase";
			woo = !woo;
			
			updateText();
		}
		tab_group.add(changeButton);

		////
		return group;
	}

	function updateStageCamera() {
		if (stage == null) return;
		
		var bg_color:Null<String> = stage.stageData.bg_color;
		camGame.bgColor = (bg_color==null ? 0xFF999999 : FlxColor.fromString(bg_color)) ?? 0xFF999999;
		camGame.zoom = stage.stageData.defaultZoom;

		var camPos = stage.stageData.camera_stage;
		if (camPos == null) camPos = [640, 360];

		camFollow.set(camPos[0], camPos[1]);
		camFollowPos.setPosition(camPos[0], camPos[1]);
	}

	function createTitleUI()
	{
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Title Screen";
		UI_box.addGroup(tab_group);

		var group = new FlxTypedGroup<FlxBasic>();
		var bgGroup = new FlxTypedGroup<Stage>(1);

		////
		var titleNames = TitleState.TitleLogo.getTitlesList();
		var titleLabels = FlxUIDropDownMenu.makeStrIdLabelArray(titleNames);
		var titleDropdown = new CustomFlxUIDropDownMenu(140, 70, titleLabels);
		
		var stageNames = StageData.getAllStages();
		var stageLabels = FlxUIDropDownMenu.makeStrIdLabelArray(stageNames);
		var stageDropdown = new CustomFlxUIDropDownMenu(10, 70, stageLabels);

		function updateShit(){
			// Logo Update 
			var newLogoName = titleDropdown.selectedId;
			if (logoBl != null && logoBl.logoName != newLogoName){
				group.remove(logoBl).destroy();
				logoBl = null;
			}
			if (logoBl == null){		
				logoBl = new TitleState.TitleLogo(newLogoName);
				logoBl.cameras = [camHUD];
				logoBl.scrollFactor.set();
				logoBl.screenCenter(XY);
				group.add(logoBl);
			}else
				logoBl.time = 0;

			// Stage Update 
			var newStageName = stageDropdown.selectedId;

			if (stage != null && stage.stageId != newStageName){
				bgGroup.remove(stage).destroy();
				stage = null;
			}else if (stage != null)
				return;

			stage = new Stage(newStageName).buildStage();
			updateStageCamera();

			bgGroup.add(stage);
		}

		var changeButton = new FlxButton(90, 20, "Reload assets", updateShit);

		group.add(bgGroup);
		group.add(UI_box);

		tab_group.add(new FlxText(titleDropdown.x, titleDropdown.y - 20, 0, "Logo"));
		tab_group.add(titleDropdown);

		tab_group.add(new FlxText(stageDropdown.x, stageDropdown.y - 20, 0, "Stage"));
		tab_group.add(stageDropdown);

		tab_group.add(changeButton);

		return group;
	}

	function createCoolBGUI()
	{
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Cool BG";
		UI_box.addGroup(tab_group);

		var group = new FlxTypedGroup<FlxBasic>();
		group.add(UI_box);

		final defaultColor = 0xff7F94FF;
		
		var bg = new funkin.objects.CoolMenuBG(Paths.image('menuDesat'), defaultColor);
		bg.cameras = [camGame];

		var colorpicker = new funkin.objects.ui.ColorPicker(10, 10, "Color", (newColor) -> bg.color = newColor, defaultColor);

		var resetColorButton = new FlxButton(10, 40, "Reset Color", function() {
			bg.color = defaultColor;
			colorpicker.color = defaultColor;
		});

		var hideUIButton = new FlxButton(10, 70, "Hide UI", function() {
			UI_box.exists = false;

			updateFunction = function() {
				if (FlxG.mouse.justMoved || FlxG.mouse.justPressed) {
					UI_box.exists = true;
					updateFunction = null;
				}
			};
		});

		group.add(bg);
		tab_group.add(colorpicker);
		tab_group.add(resetColorButton);
		tab_group.add(hideUIButton);

		return group;
	}
}