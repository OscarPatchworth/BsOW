# wallet_panel.gd
extends Panel

#region Constants
const GOLD_UTF: String = "0x0001FA99"
const FOOD_UTF: String = "0x0001F356"
const MINERAL_UTF: String = "0x0001F48E"
const WOOD_UTF: String = "0x0001FAB5"
const STONE_UTF: String = "0x0001FAA8"
const MIN_SIZE := Vector2(200, 60)
#endregion

#region Scene Refs
var player_wallet: EconData
@onready var vbox: VBoxContainer = self.find_child("VBoxContainer")
#endregion

###################################################################################################
#region Lifecycle
func game_state_changed(state: int) -> void:
	match state:
		0: self.hide()  # Setup
		1: self.show()  # Game Loop
#endregion

#region Binders
func bind_wallet(w: EconData) -> void:
	player_wallet = w
	update_display()
#endregion

#region Callbacks
func econ_changed() -> void:
	update_display()
#endregion

#region Display Updates
func update_display() -> void:
	if player_wallet == null:
		print("Wallet Panel | Err | Calling null on player wallet")
		return
	free_children(vbox)
	for game_resource in player_wallet.get_resource_dict().keys():
		var r_display = RichTextLabel.new()
		r_display.bbcode_enabled = true
		r_display.custom_minimum_size = MIN_SIZE
		var display_text: String = get_resource_icon(game_resource)
		display_text += " " + str(player_wallet.get_resource_dict()[game_resource])
		display_text = "[font_size=30]" + display_text + " [/font_size]"
		r_display.bbcode_text = display_text
		vbox.add_child(r_display)
#endregion

#region Helpers
func free_children(parent: Node) -> void:
	for i in parent.get_children():
		i.queue_free()

func get_resource_icon(r: String) -> String:
	match r:
		"gold": return "[char=%s]" % GOLD_UTF
		"food": return "[char=%s]" % FOOD_UTF
		"mineral": return "[char=%s]" % MINERAL_UTF
		"wood": return "[char=%s]" % WOOD_UTF
		"stone": return "[char=%s]" % STONE_UTF
		_: return ""
#endregion

# End Of File
