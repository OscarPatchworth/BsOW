# select_ablt_panel.gd
extends Panel

#region Scene Refs
var combat_manager: CombatManager
var player_self: Player
@onready var ablt_btn_container: Container = self.find_child("VBoxContainer")
@onready var lockout_panel: Panel = self.find_child("LockOutPanel")
#endregion

###################################################################################################
#region Lifecycle
func update(contest: Contest) -> void:
	_update_lockout(contest)
	# Placeholder — ability system not yet implemented
	var msg = Label.new()
	msg.name = "msg"
	msg.text = "No Abilities Available"
	ablt_btn_container.add_child(msg)
#endregion

#region Binders
func bind_combat_manager(cm: CombatManager) -> void:
	combat_manager = cm

func bind_player(p: Player) -> void:
	player_self = p
#endregion

#region Helpers
func _update_lockout(contest: Contest) -> void:
	if not contest.get_origin_ready() and not contest.get_target_ready():
		lockout_panel.hide()
	elif (contest.get_origin_actor() == player_self and contest.get_origin_ready()
	or contest.get_target_actor() == player_self and contest.get_target_ready()):
		lockout_panel.show()
	else:
		lockout_panel.hide()
	# Clear previous content
	for child in ablt_btn_container.get_children():
		child.queue_free()
#endregion

# End Of File
