class_name SfxCues
extends RefCounted
## The accepted FAL-372 sound effects, mirrored from the HTML game's js/sfx.js
## so both games answer to the same cue names.
##
## All seven are Kenney CC0 recordings, mono 16-bit 44.1kHz WAV at -1.1 dBTP.
## Provenance for every file is in assets/audio/CREDITS.md.
##
## `db` is a trim relative to the other effects, not a volume setting: it carries
## over the balance accepted for the HTML game, where the clear sting plays
## quieter than the rest. The player's own level is the SFX bus.

const DIR := "res://assets/audio/sfx/"

## Cue name -> file, relative trim, and the name shown in the sound check.
const CUES := {
	"confirm": {"file": "ui-confirm-01.wav", "db": 0.0, "name": "Button"},
	"correct": {"file": "answer-correct-01.wav", "db": 0.0, "name": "Right answer"},
	"retry": {"file": "answer-retry-01.wav", "db": 0.0, "name": "Try again"},
	"hint": {"file": "hint-relay-01.wav", "db": 0.0, "name": "Lifeline"},
	"reward": {"file": "scrap-reward-01.wav", "db": 0.0, "name": "Scrap"},
	"open": {"file": "encounter-open-01.wav", "db": 0.0, "name": "Encounter"},
	"clear": {"file": "encounter-clear-01.wav", "db": -4.0, "name": "Cleared"},
}


## The file for `cue`, or "" if there is no such effect.
static func path(cue: String) -> String:
	if not CUES.has(cue):
		return ""
	return DIR + String(CUES[cue]["file"])
