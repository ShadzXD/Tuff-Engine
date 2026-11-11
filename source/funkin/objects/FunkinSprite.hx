package funkin.objects;

import flixel.graphics.frames.FlxAtlasFrames;
import animate.FlxAnimate;
import flixel.FlxSprite;

#if USING_FLXANIMATE
class FunkinSprite extends FlxAnimate
#else
class FunkinSprite extends FlxSprite
#end
{
	public var isAnimateAtlas:Bool = false;
	public function addSubAtlas(key:String) {
		if (!(frames is FlxAtlasFrames))
			return;

		var frames:FlxAtlasFrames = cast this.frames;
		var subAtlas:FlxAtlasFrames = Paths.atlasFrames(key);
		if (subAtlas != null && @:privateAccess !frames.usedGraphics.contains(subAtlas.parent))
			frames.addAtlas(subAtlas, true);
	}
	public function loadAtlas(key:String) {
		var imageKeys:Array<String> = key.split(',');

		if (Paths.getImageFileType(imageKeys[0]) == ANIMATE) {
			frames = Paths.animateAtlas(imageKeys[0]);
		} else {
			frames = Paths.atlasFrames(imageKeys[0]);
			for (i in 1...imageKeys.length)
				addSubAtlas(imageKeys[i]);
		}
	}
	public function loadFrames(type:String, image:String, images:Array<String> = null) {
		var atlases:Array<String> = [image];

		switch (type) {
			#if USING_FLXANIMATE
			case "texture":
				frames = Paths.animateAtlas(image);
				isAnimateAtlas = true;
			#end
			case "packer":
				frames = Paths.packerAtlas(image);
			case "sparrow":
				var frames:FlxAtlasFrames = Paths.sparrowAtlas(image);
				if (images != null && images.length > 0) {
					for (i in images) {
						if (!atlases.contains(i)) {
							atlases.push(i);
							var subAtlas:FlxAtlasFrames = Paths.sparrowAtlas(i);
							if (subAtlas == null)
								continue;
							@:privateAccess
							if (!frames.usedGraphics.contains(subAtlas.parent))
								frames.addAtlas(subAtlas, true);
						}
					}
				}
				this.frames = frames;
		}
	}
	#if !USING_FLXANIMATE
	@:noCompletion public var isAnimate(get, never):Bool;
	@:noCompletion inline function get_anim()
		return false;
	#end
}
