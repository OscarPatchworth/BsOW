# building_ward_ability.gd
class_name BuildingWardAbility
extends Ability

## Attach to a BuildingData: the building's owner's units fighting on its lander (defending
## it, or attacking out of it) get `bonus` on their combat roll.

@export var bonus: int = 2


func modify_roll(outcome: CombatOutcome, unit: UnitInstance, lander: Lander, _contest: Contest, _side: int) -> void:
	if not lander.has_building():
		return
	var building := lander.get_building()
	if self in building.get_building_data().get_abilities() and building.get_owner_actor() == unit.get_owner_actor():
		outcome.add_modifier(bonus, get_display_name())
