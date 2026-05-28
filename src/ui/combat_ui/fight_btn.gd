# fight_btn.gd
extends Button

#region Signals
signal player_combat_ready
signal player_combat_not_ready
#endregion

#region Constants
const FIGHT_BTN_ROT: float = 12.0
#endregion

#region Scene Refs
var combat_manager: CombatManager
var player_self: Actor
var ply_ready: bool = false
#endregion

###################################################################################################
#region Lifecycle
func update(contest: Contest) -> void:
	if (contest.get_origin_actor() == player_self and contest.get_origin_ready()
	or contest.get_target_actor() == player_self and contest.get_target_ready()):
		text = "READY"
		rotation = -FIGHT_BTN_ROT
		ply_ready = true
	else:
		text = "FIGHT"
		rotation = FIGHT_BTN_ROT
		ply_ready = false
#endregion

#region Binders
func bind_combat_manager(cm: CombatManager) -> void:
	combat_manager = cm

func bind_player(p: Player) -> void:
	player_self = p
#endregion

#region Callbacks
func _pressed() -> void:
	if ply_ready:
		player_combat_not_ready.emit()
	else:
		player_combat_ready.emit()
#endregion

# End Of File
