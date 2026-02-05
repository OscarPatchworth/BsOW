#ConnectedLanderControlButton.gd
class_name ConnectedLanderControlButton
extends GameButton

# signals
signal btn_pressed(lander: Lander)
signal move_units_action_req(req: Action)

# enums

# constants

# static variables
var lander: Lander
var selector_manager: GameManager

# @export variables

# remaining regular variables

# @onready variables

###################################################################################################
###	Methods
func free_children(parent: Node) -> void:
	for i in parent.get_children():
		i.queue_free()


### Connected Signals
func _pressed():
	btn_pressed.emit(lander)

	var move_units_req = Action.new()
	move_units_req.set_type(Action.RequestType.MOVEMENT)
	move_units_action_req.emit(move_units_req)

## Calls
func bind_selector(selector: GameManager):
	selector_manager = selector
	#print("lander_control_button selector_manager bound")


func update_display():
	self.text = lander.get_biome().name
	self.icon = lander.get_biome().poker_icon


## Get/Set (er)s

### Connected Signals
