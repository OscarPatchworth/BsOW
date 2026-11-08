# simple_ai.gd
class_name SimpleAI
extends Actor

## A placeholder opponent: picks random defenders/attackers and declares ready.

signal combat_unit_selected(unit: UnitInstance)
signal combat_unit_deselected(unit: UnitInstance)
signal combat_ready(actor: Actor)
signal combat_not_ready(actor: Actor)


#region Virtual overrides
func _enter_combat(contest: Contest) -> void:
	print("SimpleAI | Entering combat")
	var side: Contest.Side = get_combat_side()
	var max_units := _combat_manager.get_max_units(side)
	var available_units := contest.get_lander(side).get_units().duplicate()

	for i in max_units:
		if available_units.is_empty():
			break
		var chosen_unit: UnitInstance = available_units.pick_random()
		available_units.erase(chosen_unit)
		combat_unit_selected.emit(chosen_unit)

	combat_ready.emit(self)
#endregion
