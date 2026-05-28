# select_units_panel.gd
extends Panel

#region Signals
signal unit_selected(unit: UnitObject)
#endregion

#region Scene Refs
var combat_manager: CombatManager
var player_self: Player
@onready var unit_list: ListBox = self.find_child("VListBox")
@onready var lockout_panel: Panel = self.find_child("LockOutPanel")
#endregion

###################################################################################################
#region Lifecycle
func update(contest: Contest) -> void:
	_update_lockout(contest)
	var units: Array[UnitObject]
	var committed_units: Array[UnitObject]
	if contest.get_origin_actor() == player_self:
		units = contest.get_origin_lander().get_units()
		committed_units = contest.get_origin_units()
	else:
		units = contest.get_target_lander().get_units()
		committed_units = contest.get_target_units()
	var available_units = units.filter(func(u): return u not in committed_units)
	unit_list.set_objects(
		available_units,
		func(u): return u.get_unit_data().name
	)
#endregion

#region Binders
func bind_combat_manager(cm: CombatManager) -> void:
	combat_manager = cm

func bind_player(p: Player) -> void:
	player_self = p
#endregion


#region Forwarders
func fwd_unit_selected(unit: UnitObject) -> void:
	unit_selected.emit(unit)
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
#endregion

# End Of File
