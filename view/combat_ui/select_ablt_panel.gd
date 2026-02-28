#select_ablt_panel.gd
extends Panel

# signals

# enums

# constants

# static variables
var combat_manager: GameManager
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
func bind_combat_manager(cm: GameManager):
	combat_manager = cm
	#print("Select ablt Panel | comabt UI | Combat Manager Bound")


func update(combat_state: Contest):
	pass
	
## Get/Set (er)s

### Connected Signals