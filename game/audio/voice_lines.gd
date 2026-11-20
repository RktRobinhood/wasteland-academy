class_name VoiceLines
extends RefCounted
## The recorded take of a line said on screen, found by its text (FAL-1134): Bodge in
## the bazaar, a mini-boss's or boss's taunt in a fight. Each take is
## <ROOT><speaker>/lines/<the first 12 hex characters of the SHA-1 of the exact UTF-8
## line>.ogg, so an edited line has a new name and never plays an old take. The rule is
## the recording side's too (FAL-1132, FAL-1133).
##
##   VoiceLines.path("bodge", "You came back!")  # res://assets/audio/voice/bodge/lines/….ogg
##   VoiceLines.say("quadratics-boss", taunt)     # plays the take if there is one
##
## The speaker is "bodge", or "<zone key>-miniboss" / "<zone key>-boss". Takes play on
## the Voice bus through Audio.play_voice, as Spark's move lines do: one voice at a
## time, so a new line stops the one before, and nothing plays with the voice at zero.

const ROOT := "res://assets/audio/voice/"
const HASH_CHARS := 12

## Where the speakers' folders are. Tests point it at a fixture.
static var root := ROOT


## The file a line's take would be at, whether or not it exists.
static func path(speaker: String, text: String) -> String:
	return "%s%s/lines/%s.ogg" % [root, speaker, text.sha1_text().left(HASH_CHARS)]


## The line's take, or null when it hasn't been recorded.
static func take(speaker: String, text: String) -> AudioStream:
	if speaker == "" or text == "":
		return null
	var p := path(speaker, text)
	return load(p) as AudioStream if ResourceLoader.exists(p) else null


## Play the line's take if it has one. Returns the take's path, or "" when there is none
## (the line stays text only). Whether it is heard is up to the sound settings.
static func say(speaker: String, text: String) -> String:
	var stream := take(speaker, text)
	if stream == null:
		return ""
	Audio.play_voice(stream)
	return path(speaker, text)
