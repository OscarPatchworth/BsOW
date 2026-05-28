#ConnectedLanderControlButton.gd
class_name ConnectedLanderControlButton
extends Button

# signals
signal btn_pressed(lander: Lander)
signal move_units_action_req(req: Action)
signal attack_lander_action_req(req: Action)

# enums
enum DisplayState {
	NEUTRAL,
	ALLY,
	ENEMY
}

# constants

# static variables
var selector_manager: Node

var style_box_defualt: StyleBox = preload("res://src/ui/lander_panel/landers/lander_btn_defualt.res")
var style_box_enemy: StyleBox = preload("res://src/ui/lander_panel/landers/lander_btn_enemy.res")
var style_box_ally: StyleBox = preload("res://src/ui/lander_panel/landers/lander_btn_ally.res")
# remaining regular variables
var lander: Lander
var display_state: DisplayState = DisplayState.NEUTRAL

# @export variables


# @onready variables

###################################################################################################
###	Methods
func free_children(parent: Node) -> void:
	for i in parent.get_children():
		i.queue_free()


### Connected Signals
func _pressed():
	btn_pressed.emit(lander)

	# Determine Action to emit based on lander-state-to-self_player
	if(display_state == DisplayState.ENEMY):
		# Attack Action Req
		var attack_req = Action.new()
		attack_req.set_type(Action.RequestType.ATTACK)
		attack_lander_action_req.emit(attack_req)
	else:
		# Move Action Req
		var move_units_req = Action.new()
		move_units_req.set_type(Action.RequestType.MOVEMENT)
		move_units_action_req.emit(move_units_req)

## Calls
func bind_selector(selector: Node):
	selector_manager = selector
	#print("lander_control_button selector_manager bound")


func update_display():
	self.text = lander.get_biome().name
	self.icon = lander.get_biome().poker_icon
	
	match display_state:
		DisplayState.NEUTRAL:
			self.add_theme_stylebox_override("normal", style_box_defualt)
		DisplayState.ENEMY:
			self.add_theme_stylebox_override("normal", style_box_enemy)
		DisplayState.ALLY:
			self.add_theme_stylebox_override("normal", style_box_ally)
		_:
			print("Connected Lander Btn Error: Btn has no assigned DisplayState")




## Get/Set (er)s

### Connected Signals
