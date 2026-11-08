# simple_ai.gd
class_name SimpleAI
extends Actor

## A placeholder opponent: picks random defenders/attackers and declares ready.


#region Virtual overrides
func _enter_combat(contest: Contest) -> void:
	print("SimpleAI | Entering combat")
	var side: int = get_combat_side()
	var max_units := _combat_manager.get_max_units(side)
	var available_units := contest.get_lander(side).get_units().duplicate()

	for i in max_units:
		if available_units.is_empty():
			break
		var chosen_unit: UnitInstance = available_units.pick_random()
		available_units.erase(chosen_unit)
		var select := Action.create(Action.Type.SELECT_COMBAT_UNIT)
		select.set_units([chosen_unit] as Array[UnitInstance])
		request_action(select)

	request_action(Action.create(Action.Type.DECLARE_COMBAT_READY))
#endregion
