#wallet_panel.gd
#class_name ClassName
extends Panel

# signals

# enums

# constants
const GOLD_UTF: String = "0x0001FA99"
const FOOD_UTF: String = "0x0001F356"
const MINERAL_UTF: String = "0x0001F48E"
const WOOF_UTF: String = "0x0001FAB5"
const STONE_UTF: String = "0x0001FAA8"
const MIN_SIZE := Vector2(200, 60)

# static variables

# @export variables

# remaining regular variables
var player_wallet: EconData

# @onready variables
@onready var vbox: VBoxContainer = self.find_child("VBoxContainer")

###################################################################################################
###	Methods
func free_children(parent: Node) -> void:
	for i in parent.get_children():
		i.queue_free()


func run_wallet_display():
	update_display()

func update_display():
	if player_wallet == null:
		print("Wallet Panel | Err | Calling Null player wallet")
		return
	free_children(vbox)
	for game_resource in player_wallet.get_resource_dict().keys():
		# Make new RTL
		var r_display = RichTextLabel.new()
		r_display.bbcode_enabled = true
		r_display.custom_minimum_size = MIN_SIZE

		var display_text: String = add_game_resource_icon(r_display, game_resource)
		display_text += " " + str(player_wallet.get_resource_dict()[game_resource])
		# Apply font-size
		display_text = "[font_size=30]" + display_text + " [/font_size]"
		
		r_display.bbcode_text = display_text
		vbox.add_child(r_display)


func add_game_resource_icon(rtl: RichTextLabel, r: String) -> String:
	match r:
		"gold":
			return ("[char=%s]" % [GOLD_UTF])
		"food":
			return ("[char=%s]" % [FOOD_UTF])
		"mineral":
			return ("[char=%s]" % [MINERAL_UTF])
		"wood":
			return ("[char=%s]" % [WOOF_UTF])
		"stone":
			return ("[char=%s]" % [STONE_UTF])
		_:
			return ("")

### Connected Signals


## Calls
func bind_wallet(w: EconData):
	player_wallet = w
	run_wallet_display()

func econ_changed():
	update_display()


func game_state_changed(state):
	if state == 0: #setup
		self.hide()
	elif state == 1: # Main game loop
		self.show()
	else: # Dead
		pass
	
## Get/Set (er)s

### Connected Signals
