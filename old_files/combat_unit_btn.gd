#combat_unit_btn.gd
extends Button

# signals

# enums

# constants

# static variables

# @export variables

# remaining regular variables

# @onready variables

###################################################################################################
###	Methods
func free_children(parent: Node) -> void:
	for i in parent.get_children():
		i.queue_free()


### Connected Signals


## Calls

## Get/Set (er)s

### Connected Signals
