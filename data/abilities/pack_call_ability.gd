# pack_call_ability.gd
class_name PackCallAbility
extends Ability

## Attach to a UnitData: each time one of these units kills the unit it faced, a basic melee
## unit of its race joins it on its lander (if there's room).


func on_defeated_opponent(outcome: CombatOutcome, lander: Lander) -> String:
	var unit := outcome.get_unit()
	if self not in unit.get_unit_data().get_abilities():
		return ""
	if lander.get_units().size() >= lander.get_unit_capacity():
		return ""
	var owner_actor := unit.get_owner_actor()
	for unit_data in owner_actor.get_species().get_units():
		if unit_data.get_unit_type() == UnitData.UnitType.MELEE_BASIC:
			lander.add_units([UnitInstance.new(unit_data, owner_actor)] as Array[UnitInstance])
			return "%s's kill called a %s to the pack (%s)" % [unit.get_display_name(), unit_data.get_display_name(), get_display_name()]
	return ""
