# wallet_panel.gd
class_name WalletPanel
extends Panel

## Shows the player's resources with an emoji icon each.

const RESOURCE_ICONS := {
	"gold": "0x0001FA99",
	"food": "0x0001F356",
	"mineral": "0x0001F48E",
	"wood": "0x0001FAB5",
	"stone": "0x0001FAA8",
}
const LINE_MIN_SIZE := Vector2(200, 60)
const FONT_SIZE: int = 30

var _wallet: EconData

@onready var _lines_box: VBoxContainer = find_child("VBoxContainer")


#region Public API
func bind_wallet(wallet: EconData) -> void:
	_wallet = wallet
	refresh()


func refresh() -> void:
	for child in _lines_box.get_children():
		child.queue_free()
	var amounts := _wallet.to_dictionary()
	for resource_name in amounts:
		var line := RichTextLabel.new()
		line.bbcode_enabled = true
		line.custom_minimum_size = LINE_MIN_SIZE
		line.text = "[font_size=%d]%s %d [/font_size]" % [FONT_SIZE, _icon_bbcode(resource_name), amounts[resource_name]]
		_lines_box.add_child(line)


func apply_game_state(state: TurnManager.GameState) -> void:
	match state:
		TurnManager.GameState.SETUP:
			hide()
		TurnManager.GameState.MAIN_LOOP:
			show()
#endregion


#region Private
func _icon_bbcode(resource_name: String) -> String:
	if not RESOURCE_ICONS.has(resource_name):
		return ""
	return "[char=%s]" % RESOURCE_ICONS[resource_name]
#endregion
