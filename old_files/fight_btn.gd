#fight_btn.gd
extends GameButton

# signals
signal player_combat_ready
signal player_combat_not_ready

# enums

# constants
const FIGHT_BTN_ROT: float = 12.0

# static variables
var combat_manager: CombatManager
# @export variables

# remaining regular variables
var player_self: Actor
var ply_ready: bool = false

# @onready variables

###################################################################################################
###	Methods
func free_children(parent: Node) -> void:
	for i in parent.get_children():
		i.queue_free()


func update(combat_state: Contest):
	if(combat_state.get_origin_actor() == player_self and combat_state.get_origin_ready()
	or combat_state.get_origin_actor() == player_self and combat_state.get_origin_ready()):
		text = "READY"
		rotation = -FIGHT_BTN_ROT
		ply_ready = true
	else:
		text = "FIGHT"
		rotation = FIGHT_BTN_ROT
		ply_ready = false


### Connected Signals
func _pressed() -> void:
	if(ply_ready):
		player_combat_not_ready.emit()
	else:
		player_combat_ready.emit()


## Calls
func bind_combat_manager(cm: CombatManager):
	combat_manager = cm
	#print("Fight Btn | comabt UI | Combat Manager Bound")

func bind_player(p: Player):
	player_self = p

## Get/Set (er)s

### Connected Signals
