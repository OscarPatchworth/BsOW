#combat_panel.gd
extends Panel

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
func setup_combat_display(contest: Contest):
	print("Combat UI | @ setup()")


## Get/Set (er)s

### Connected Signals
