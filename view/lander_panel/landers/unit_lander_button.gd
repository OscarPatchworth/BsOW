#unit_lander_control_button.gd
class_name UnitLanderControlButton
extends GameButton

# signals
signal unit_selected(unit: UnitObject)
signal unit_deselected(unit: UnitObject)

# enums

# constants

# static variables
var unit: UnitObject
var selector_manager: GameManager

# @export variables

# remaining regular variables

# @onready variables

###################################################################################################
###	Methods
func _init() -> void:
	self.set_toggle_mode(true)


func free_children(parent: Node) -> void:
	for i in parent.get_children():
		i.queue_free()


### Connected Signals
func _pressed():
	print(unit.get_unit_data().name)


## Calls
func bind_selector(selector: GameManager):
	selector_manager = selector
	#print("unit_lander_control_button selector_manager bound")


func update_display():
	if unit.get_unit_data() != null:
		self.text = unit.get_unit_data().name
		self.icon = unit.get_unit_data().get_icon()


## Get/Set (er)s

### Connected Signals
func _toggled(toggled_on: bool) -> void:
	if toggled_on:
		unit_selected.emit(unit)
	else:
		unit_deselected.emit(unit)
