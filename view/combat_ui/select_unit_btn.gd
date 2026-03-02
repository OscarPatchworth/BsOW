#combat_unit_btn.gd
extends GameButton

# signals
signal unit_selected(unit: UnitObject)


# enums

# constants

# static variables
var unit: UnitObject

# @export variables

# remaining regular variables

# @onready variables

###################################################################################################
###	Methods
func free_children(parent: Node) -> void:
	for i in parent.get_children():
		i.queue_free()


### Connected Signals
func _pressed() -> void:
	unit_selected.emit(unit)


## Calls

## Get/Set (er)s
func get_unit() -> UnitObject:
	return unit
func set_unit(u: UnitObject):
	unit = u


### Connected Signals