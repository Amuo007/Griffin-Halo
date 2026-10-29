extends Node
## Story tables: characters, voices, cutscene scripts. Filled in Phase 7.

const VOICES := {
	"griffin": "en-US-GuyNeural",
	"marcus": "en-US-ChristopherNeural",
	"elena": "en-US-JennyNeural",
	"vera": "en-US-AriaNeural",
}

# Each cutscene: {"id": String, "lines": [{"speaker","text","emotion","seconds"}], "cues": [...]}
const CUTSCENES := {
	"intro": {"lines": [], "cues": []},
	"wake": {"lines": [], "cues": []},
	"journal": {"lines": [], "cues": []},
	"vera": {"lines": [], "cues": []},
	"alpha": {"lines": [], "cues": []},
	"gate": {"lines": [], "cues": []},
	"dawn": {"lines": [], "cues": []},
}

func get_cutscene(id: String) -> Dictionary:
	return CUTSCENES.get(id, {"lines": [], "cues": []})
