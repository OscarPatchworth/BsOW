#fight_btn.gd
extends GameButton

# signals
signal player_combat_ready

# enums

# constants
const FIGHT_BTN_ROT: float = 12.0

# static variables
var combat_manager: GameManager
# @export variables

# remaining regular variables
var player_self: Actor
# @onready variables

###################################################################################################
###	Methods
func free_children(parent: Node) -> void:
	for i in parent.get_children():
		i.queue_free()


func update(combat_state: Contest):
	if(combat_state.get_invading_actor() == player_self and combat_state.get_invading_ready()
	or combat_state.get_invading_actor() == player_self and combat_state.get_invading_ready()):
		text = "READY"
		rotation = -FIGHT_BTN_ROT
	else:
		text = "FIGHT"
		rotation = FIGHT_BTN_ROT


### Connected Signals
func _pressed() -> void:
	player_combat_ready.emit()


## Calls
func bind_combat_manager(cm: GameManager):
	combat_manager = cm
	#print("Fight Btn | comabt UI | Combat Manager Bound")

func bind_player(p: Player):
	player_self = p
	
## Get/Set (er)s

### Connected Signals