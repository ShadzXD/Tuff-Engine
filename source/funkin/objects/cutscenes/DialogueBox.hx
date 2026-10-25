package funkin.objects.cutscenes;

import funkin.objects.cutscenes.components.DialogueBoxSprite;
import funkin.objects.cutscenes.components.DialogueCharacter;
import flixel.addons.text.FlxTypeText;
import flixel.util.FlxColor;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxTimer;
#if USING_TEXTBOX
import textbox.Settings;
import textbox.Textbox;
#end

typedef DialogueFile = {
	var dialogue:Array<DialogueLine>;
	var box_style:String;
}

typedef DialogueLine = {
	var text:String;
	var character:String;
	var character_anim:String;
	var text_speed:Int;
	var text_size:Int; // custom font size
	var line_sound:Array<String>;
	var box_animation:String;
}

class DialogueBox extends FlxTypedGroup<FlxBasic> {
	/**
	 * How long it should take until the dialogue first starts
	 * Set to 0 for instant start time.
	 */
	public var introDelay:Float = 2;

	/** Whether the player is able to progress the dialogue. **/
	public var canProgressDialogue:Bool = false;

	/** Variable that allows you to keep all characters on screen if needed. **/
	public var keepAllCharactersOnScreen:Bool = false;

	/** Array that will be filled with all the dialogue characters. **/
	var characters:Array<DialogueCharacter> = [];

	public var curLine:Int = 0;

	public var dialogueFile:DialogueFile;

	var dialogueText:Dynamic;
	var box:DialogueBoxSprite;
	var curCharacter:DialogueCharacter;

	var finishedLine:Bool = false;

	public function new(dialoguePath:String) {
		super();
		try {
			dialogueFile = Paths.json(dialoguePath);
			loadCutscene();
		}
	}

	public function loadCutscene() {
		loadCharacters();

		box = new DialogueBoxSprite(dialogueFile.box_style);
		box.visible = false;
		add(box);

		box.script?.call("onCreatePost");
		#if USING_TEXTBOX
		var settings:Settings = {
			font: Paths.font(box.font),
			fontSize: getTextSize(-1),
			textFieldWidth: box.textWidth,
			color: FlxColor.fromString(box.textColor),
			numLines: 3,
			charactersPerSecond: getTextSpeed()
		};
		dialogueText = new Textbox(box.textOffsets[0], box.textOffsets[1], settings);
		// dialogueText.setText();
		#else
		dialogueText = new FlxTypeText(box.textOffsets[0], box.textOffsets[1], box.textWidth, '', getTextSize(-1));

		dialogueText.setFormat(Paths.font(box.font), getTextSize(-1), FlxColor.fromString(box.textColor));

		dialogueText.borderSize = box.shadowWidth;
		dialogueText.completeCallback = finishLine;
		#end
		dialogueText.antialiasing = box.antialiasing;

		add(dialogueText);

		new FlxTimer().start(introDelay, function(tmr:FlxTimer) {
			canProgressDialogue = true;
			box.visible = true;
			createNewLine();
		});

		this.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	public function finishLine() {
		finishedLine = true;
		box.script?.call("onFinishLineDialogue");
	}

	function loadCharacters() {
		var characterMap:Map<String, Bool> = new Map<String, Bool>();
		// Does a loop through the entire dialogue file and checks for characters
		for (i in 0...dialogueFile.dialogue.length) {
			if (dialogueFile.dialogue[i] != null && dialogueFile.dialogue[i].character != null) {
				var newCharacter:String = dialogueFile.dialogue[i].character;
				if (!characterMap.exists(newCharacter) || !characterMap.get(newCharacter))
					characterMap.set(newCharacter, true); // adds to the map only if the character doesnt already exist
			}
		}

		for (curCharacter in characterMap.keys()) {
			var char:DialogueCharacter = new DialogueCharacter(curCharacter);
			char.updateHitbox();
			char.scrollFactor.set();
			char.alpha = 0;
			add(char);
			characters.push(char);
		}
	}

	override function update(elapsed:Float) {
		// controls.accept wasnt working so i jst gave up ngl
		// i got u homie
		// thnk u

		// todo: maybe have a proper log book for dialogue.
		super.update(elapsed);
	}

	public function progress() {
		trace('trying to progress');
		if (!canProgressDialogue)
			return;
		#if USING_TEXTBOX
		if (finishedLine) {
			curLine++;
			createNewLine();
		}
		#else
		if (finishedLine) {
			curLine++;
			createNewLine();
		} else {
			skipCurLine();
		}
		#end
	}

	/**
	 * Function thats called when a line of dialogue is skipped mid sentence.
	 */
	function skipCurLine() {
		box?.script?.call("onSkipLine");
		#if !USING_TEXTBOX
		dialogueText.skip();
		#end
	}

	/**
	 * Creates a new line of dialogue.
	 */
	public function createNewLine() {
		FlxG.sound.play(Paths.sound(box.dialoguePressedSound), 0.7);
		box?.script?.call("onNewLine");

		if (curLine >= dialogueFile.dialogue.length) {
			endDialogue(false);
			return;
		}
		finishedLine = false;
		var curDialogueLine:DialogueLine = dialogueFile.dialogue[curLine];

		playBoxAnimation(curDialogueLine.box_animation);

		var curCharcter:Int = 0;
		for (i in 0...characters.length) {
			if (characters[i].curChar == curDialogueLine.character) {
				curCharcter = i;
				break;
			}
		}
		if (!keepAllCharactersOnScreen)
			for (i in 0...characters.length) {
				characters[i].alpha = 0;
				if (characters[i] == characters[curCharcter]) {
					characters[curCharcter].alpha = 1;
				}
			}
		curCharacter = characters[curCharcter];
		curCharacter.animation.play(curDialogueLine.character_anim);
		// getTextSound();
		// dialogueText.size = getTextSize(curDialogueLine.text_size);
		#if USING_TEXTBOX
		dialogueText.setText(curDialogueLine.text);
		dialogueText.bring();
		#else
		// dialogueText.size = getTextSize(curDialogueLine.text_size);

		dialogueText.resetText(curDialogueLine.text);
		dialogueText.start(curDialogueLine.text_speed);
		#end
	}

	/**
	 * Function that's only called when dialogue is ending.
	 * @param wasSkipped
	 */
	public function endDialogue(wasSkipped:Bool) {
		box?.script?.call("onDialogueEnded");

		// new FlxTimer().start(1, function(tmr:FlxTimer) {
		//		destroy();
		//	});
	}

	/**
	 * Returns Text Size for the current line.
	 * This is done so we can use custom text sizes for each line.
	 * @param _lineTextSize
	 * @return Int
	 */
	inline function getTextSize(_lineTextSize:Int):Int
		return _lineTextSize > 0 ? _lineTextSize : box.textSize;

	public function restart() {
		curLine = 0;
		createNewLine();
	}

	/**
	 * Function thats called to retrieve text sound.
	 * Leaving all fields empty, will not play a sound.
	 */
	private function getTextSound() {
		var dialogueTalkSound:Array<String> = null;
		if (dialogueFile.dialogue[curLine].line_sound != null)
			dialogueTalkSound = dialogueFile.dialogue[curLine].line_sound;
		else if (curCharacter.talkSound != null)
			dialogueTalkSound = curCharacter.talkSound;
		else if (box.dialogueTalkSound != null)
			dialogueTalkSound = box.dialogueTalkSound;
		/*
			if (dialogueTalkSound != null)
				dialogueText?.sounds = [
					for (dialogueSound in dialogueTalkSound)
						FlxG.sound.load(Paths.sound(dialogueSound), 0.6)
				];
		 */
	}

	public inline function getTextSpeed():Int // return dialogueFile.dialogue[curLine].text_speed;
		return 12;

	/**
	 * Play dialogue box animation
	 * @param _anim
	 */
	function playBoxAnimation(_anim:String) {
		if (_anim == null)
			return;
		box?.animation.play(_anim);
	}
}
