# text_utils.gd
class_name TextUtils
extends RefCounted

## Small text helpers shared by the UI.


## "DUSTCLOUD_COLLAPSE" -> "Dustcloud Collapse"
static func to_title_case(text: String) -> String:
	var words := text.split("_")
	for i in words.size():
		words[i] = words[i].to_lower().capitalize()
	return " ".join(words)
