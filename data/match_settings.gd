#match_settings.gd
extends Node

# signals

# enums

# constants

# static variables

# @export variables
@export var number_of_opponents: int = 1
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
