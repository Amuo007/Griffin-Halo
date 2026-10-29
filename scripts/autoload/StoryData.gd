extends Node
## Story tables: characters, voices, cutscene scripts.

const VOICES := {
	"griffin": "en-US-GuyNeural",
	"marcus": "en-US-ChristopherNeural",
	"elena": "en-US-JennyNeural",
	"vera": "en-US-AriaNeural",
	"narrator": "en-GB-RyanNeural",
}

const CUTSCENES := {
	"intro": {"scene": "res://scenes/cutscenes/CutsceneIntro.tscn", "lines": [
		{"speaker": "griffin", "text": "So this is the famous Hollow Cave. You said Elena would be here.", "seconds": 4.0},
		{"speaker": "marcus", "text": "It's me and Elena. It's been us for months.", "seconds": 4.0},
		{"speaker": "griffin", "text": "...What?", "seconds": 2.0},
		{"speaker": "marcus", "text": "She was never going to pick you, Griff. Nobody does. I just wanted one thing.", "seconds": 5.5},
		{"speaker": "marcus", "text": "Look down here. She's waiting at the bottom.", "seconds": 3.5},
		{"speaker": "griffin", "text": "Marcus— Marcus, no! MARCUS!", "seconds": 3.5},
		{"speaker": "marcus", "text": "I'm sorry. I'm sorry. I'm sorry.", "seconds": 4.0},
	]},
	"wake": {"lines": [
		{"speaker": "griffin", "text": "Name. Griffin. Air. Moving. Keep moving.", "seconds": 4.0},
		{"speaker": "griffin", "text": "Old mines have drainage tunnels. Drainage tunnels come out somewhere. Somewhere is better than here.", "seconds": 6.0},
		{"speaker": "griffin", "text": "Condemned, 1974. He picked this place on purpose. This wasn't a prank.", "seconds": 5.5},
		{"speaker": "griffin", "text": "...What was that?", "seconds": 2.5},
	]},
	"journal": {"lines": [
		{"speaker": "elena", "text": "Marcus keeps talking about the cave like it's a joke. I told him it's sealed for a reason.", "seconds": 5.5},
		{"speaker": "elena", "text": "If anything happens to Griffin, it'll be his fault.", "seconds": 4.0},
		{"speaker": "griffin", "text": "You knew. You tried to stop him.", "seconds": 3.5},
		{"speaker": "griffin", "text": "It wasn't about you. It was never about you. It was him. All of it, him.", "seconds": 5.5},
	]},
	"vera": {"lines": [
		{"speaker": "vera", "text": "Don't move. Don't... you're not one of them. Not yet.", "seconds": 4.5},
		{"speaker": "vera", "text": "I came in for my father. 1974. I'm the only one the mine gave back.", "seconds": 5.5},
		{"speaker": "vera", "text": "It doesn't hunt you. It learns you. Your sounds. Your smells. Your face.", "seconds": 5.5},
		{"speaker": "vera", "text": "The big one... it used to have a name. I'd swear it did.", "seconds": 4.5},
		{"speaker": "vera", "text": "Pump house. East corridor. The old pumps still run. Go. Go before I ask you to stay.", "seconds": 5.5},
		{"speaker": "vera", "text": "Don't let it finish learning me.", "seconds": 3.5},
	]},
	"alpha": {"lines": [
		{"speaker": "griffin", "text": "That's... that's my guitar. What is it doing with my guitar?", "seconds": 4.5},
		{"speaker": "griffin", "text": "It kept it. It catalogued it. It's telling me I'm next.", "seconds": 4.5},
		{"speaker": "griffin", "text": "Steam line. One shot at the valve. Don't breathe. Move.", "seconds": 4.0},
	]},
	"gate": {"lines": [
		{"speaker": "griffin", "text": "The gate he shut on me. I can see the sky through it.", "seconds": 4.0},
		{"speaker": "griffin", "text": "Of course you're here. Of course you are.", "seconds": 3.0},
		{"speaker": "griffin", "text": "STEAM! NOW!", "seconds": 2.0},
		{"speaker": "griffin", "text": "No no no no— GET OFF—", "seconds": 3.0},
	]},
	"dawn": {"lines": [
		{"speaker": "griffin", "text": "Elena. It's me. I know about you and Marcus. I'm not angry. I just wish you'd told me.", "seconds": 6.5},
		{"speaker": "griffin", "text": "And I need you to believe me about the mine. It wasn't empty. Nothing in there should be that smart.", "seconds": 6.0},
		{"speaker": "griffin", "text": "Someone has to close it. I'm going back.", "seconds": 3.5},
		{"speaker": "griffin", "text": "And I think... I'm starting to know its name.", "seconds": 4.0},
	]},
}

const LORE := {
	"miner1": {"title": "Torn miner's note", "text": "\"Day 41. The sounds in the deep tunnels again. Not echoes. Echoes don't answer back.\""},
	"miner2": {"title": "Foreman's log", "text": "\"Sealed the east shaft today. God forgive us, we sealed it with the Kowalski crew still inside. The sounds stopped. That's what they want us to think.\""},
	"condemned": {"title": "Condemned placard", "text": "\"CONDEMNED 1974 — DO NOT ENTER.\" Beneath it, scratched into the metal: \"THEY CAME OUT OF THE DRAIN.\""},
	"elena1": {"title": "Elena's journal", "text": "\"Marcus keeps talking about the cave like it's a joke. I told him it's sealed for a reason.\""},
	"elena2": {"title": "Elena's journal, last page", "text": "\"If anything happens to Griffin, it'll be his fault. I know that look in his eye. It's been there for months.\""},
	"lighter": {"title": "Marcus's lighter", "text": "\"ENGRAVED: To M — best friends forever. It's been here recently. Someone lived at this cave mouth. Watching.\""},
	"guitar": {"title": "Broken guitar", "text": "\"The neck is snapped clean. Someone strung a single new string on it. Why would anyone restring a dead guitar?\""},
	"vera_note": {"title": "Scratched wall", "text": "\"IT LEARNS. DON'T LET IT LEARN YOUR NAME.\""},
}

func get_cutscene(id: String) -> Dictionary:
	return CUTSCENES.get(id, {"lines": [], "cues": []})

func get_lore(id: String) -> Dictionary:
	return LORE.get(id, {})
