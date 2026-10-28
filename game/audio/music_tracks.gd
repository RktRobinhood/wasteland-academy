class_name MusicTracks
extends RefCounted
## The one place a location's music is chosen (FAL-385).
##
## The loops come from the FAL-371 round 2/3 proposal, which Studio Manager
## approved with two recommended seeds per cue. `seed` is the shipped default
## (recommendation A). `alternate` is recommendation B, kept here so Matt's
## listening pass costs one line.
##
## To swap a cue to its alternate:
##   1. change that cue's `seed:` to its `alternate:` value, and
##   2. copy the matching loop in beside the others. Only the twelve defaults
##      are committed, to keep the web export down:
##        assets/audio/proposed/fal-371/round2/<cue>-r2-seed<seed>-loop.ogg
##     -> game/assets/audio/music/<cue>-seed<seed>-loop.ogg
##      The Engine Core exploration seeds come from round 3, so that source file
##      is named engine-core-r3-seed<seed>-loop.ogg.
##
## `bpm` and `seconds` are measured facts from the review, for whoever adds
## tempo or beat-matched transitions later. Every loop is Ogg Vorbis q6,
## 44.1kHz stereo, -18 LUFS-I, and joins end-to-start on its own.

const DIR := "res://assets/audio/music/"

## Location key -> the cue that plays there. Boss cues keep their region's
## instruments; see SPEC.md §4 for the islands and the Thunderdome.
const CUES := {
	"overworld": {
		"seed": 37202, "alternate": 37203,
		"name": "Overworld", "bpm": 72, "seconds": 106.666667,
	},
	"scrap-fields": {
		"seed": 37201, "alternate": 37202,
		"name": "The Scrap Fields", "bpm": 76, "seconds": 101.052630,
	},
	"scrap-fields-boss": {
		"seed": 37203, "alternate": 37202,
		"name": "The Scrap Fields — boss", "bpm": 76, "seconds": 101.052630,
	},
	"signal-tower": {
		"seed": 37202, "alternate": 37203,
		"name": "The Signal Tower", "bpm": 80, "seconds": 96.000000,
	},
	"signal-tower-boss": {
		"seed": 37202, "alternate": 37203,
		"name": "The Signal Tower — boss", "bpm": 80, "seconds": 96.000000,
	},
	"dry-flats": {
		"seed": 37202, "alternate": 37203,
		"name": "The Dry Flats", "bpm": 68, "seconds": 112.941179,
	},
	"dry-flats-boss": {
		"seed": 37202, "alternate": 37201,
		"name": "The Dry Flats — boss", "bpm": 68, "seconds": 112.941179,
	},
	"radio-spires": {
		"seed": 37201, "alternate": 37202,
		"name": "Radio Spires", "bpm": 74, "seconds": 103.783787,
	},
	"radio-spires-boss": {
		"seed": 37202, "alternate": 37201,
		"name": "Radio Spires — boss", "bpm": 74, "seconds": 103.783787,
	},
	"engine-core": {
		"seed": 37301, "alternate": 37302,
		"name": "The Engine Core", "bpm": 88, "seconds": 87.272721,
	},
	"engine-core-boss": {
		"seed": 37202, "alternate": 37201,
		"name": "The Engine Core — boss", "bpm": 88, "seconds": 87.272721,
	},
	"thunderdome": {
		"seed": 37201, "alternate": 37202,
		"name": "The Thunderdome", "bpm": 96, "seconds": 80.000000,
	},
}


## The loop that plays at `cue`, or "" if there is no such location.
static func path(cue: String) -> String:
	if not CUES.has(cue):
		return ""
	return "%s%s-seed%d-loop.ogg" % [DIR, cue, int(CUES[cue]["seed"])]


## The loop Matt would hear if this cue were switched to its alternate. Not
## committed; see the note at the top.
static func alternate_path(cue: String) -> String:
	if not CUES.has(cue):
		return ""
	return "%s%s-seed%d-loop.ogg" % [DIR, cue, int(CUES[cue]["alternate"])]


## The menu name for a location, or the key itself if it is unknown.
static func display_name(cue: String) -> String:
	if not CUES.has(cue):
		return cue
	return String(CUES[cue]["name"])
