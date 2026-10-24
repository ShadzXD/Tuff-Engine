package funkin.objects.cutscenes;

import funkin.input.Controls.firstActive as controls;

/**Code for the dialogue cutscene instance**/
class DialogueCutscene extends Cutscene {
	public var box:DialogueBox;
	public var dialogue:String;

	public function new(_path:String) {
		super();
		this.dialogue = _path;
	}

	public override function createCutscene() {
		box = new DialogueBox(dialogue);
		add(box);
		onEnd.addOnce(box.endDialogue);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		if (controls.ACCEPT)
			box.progress();
	}

	override public function restart() {
		box.restart();
	}
}
