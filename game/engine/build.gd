class_name Build
extends RefCounted
## Which build this is: the release tag ("v1.2.0") a student's site was cut from, or
## "main-<commit>" on the preview address, or "dev" in the editor. export.sh writes it into
## data/build_id.json (from scripts/build-id.sh) so the title screen can show it, and the
## same id is on the release note and in the service worker's cache name (#184).

const PATH := "res://data/build_id.json"
const UNKNOWN := "dev"


static func id() -> String:
	if not FileAccess.file_exists(PATH):
		return UNKNOWN
	var data = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if data is Dictionary and str(data.get("id", "")) != "":
		return str(data.id)
	return UNKNOWN
