#ConnectedLanderControlButton.gd
class_name ConnectedLanderControlButton
extends GameButton

# signals

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
	print(lander.get_biome().name)

## Calls
func bind_selector(selector: GameManager):
	selector_manager = selector
	#print("lander_control_button selector_manager bound")


func update_display():
	self.text = lander.get_biome().name
	self.icon = lander.get_biome().poker_icon


## Get/Set (er)s

### Connected Signals
