package funkin.objects.cutscenes;

import flixel.graphics.frames.FlxAtlasFrames;
import funkin.data.CharacterData;
#if USING_FLXANIMATE
import animate.FlxAnimate;
import animate.FlxAnimateController;
import animate.FlxAnimateFrames;
#end
#if USING_FLXANIMATE
import animate.FlxAnimate;
#end

typedef DialogueCharacterFile = {
	var image:String;
	var offsets:Array<Int>;
	var antialiasing:Bool;
	var scale:Float;
	var talk_sound:Array<String>;

	var animations:Array<DialogueAnimArray>;
	@:optional var images:Array<String>;
}

typedef DialogueAnimArray = {
	var name:String;
	var fps:Int;
	var prefix:String;
	var looped:Bool;
}

class DialogueCharacter extends FlxSpriteExt {
	/**
	 * JSON file to be used.
	 */
	var jsonFile:DialogueCharacterFile;

	/**
	 *  Current character thats loaded.
	 *  Defaults to bf-pixel
	 */
	public var curChar:String = 'bf-pixel';

	public var talkSound:Array<String> = null;

	public function new(_character:String) {
		super();

		jsonFile = Paths.json('boxes/characters/$_character.json');

		if (jsonFile != null) // fuck me pls
		{
			curChar = _character;
			loadJSON();
		} else
			trace('Couldnt load $_character');
	}

	private function loadJSON() {
		var fileType:String = CharacterData.getImageFileType(jsonFile.image);

		loadFrames(fileType, jsonFile.image);

		x = jsonFile.offsets[0];
		y = jsonFile.offsets[1];

		antialiasing = jsonFile.antialiasing;
		scale.set(jsonFile.scale, jsonFile.scale);
		talkSound = jsonFile.talk_sound;
		for (curAnim in jsonFile.animations) {
			#if USING_FLXANIMATE if (isAnimateAtlas)
				anim.addBySymbol(curAnim.name, curAnim.prefix, curAnim.fps, curAnim.looped);
			else #end anim.addByPrefix(curAnim.name, curAnim.prefix, curAnim.fps, curAnim.looped);
		}
	}
}
