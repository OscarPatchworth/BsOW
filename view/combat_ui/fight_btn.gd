#fight_btn.gd
extends GameButton

# signals
signal player_combat_ready

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
func _pressed() -> void:
	player_combat_ready.emit()


## Calls
func bind_combat_manager(cm: GameManager):
	combat_manager = cm
	#print("Fight Btn | comabt UI | Combat Manager Bound")


func update(combat_state: Contest):
	pass

## Get/Set (er)s

### Connected Signals