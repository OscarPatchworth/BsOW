#combat_progress_bar.gd
extends ProgressBar

# signals

# enums

# constants
const delselected_fill_perc: int = 64
const selected_fill_perc: int = 100


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