# combined_arms_ability.gd
class_name CombinedArmsAbility
extends Ability

## A match rule: a ranged unit gets `bonus` when melee units fight alongside it (on the same
## side of the same battle round).

@export var bonus: int = 2

const RANGED_TYPES: Array[int] = [UnitData.UnitType.RANGED_BASIC, UnitData.UnitType.RANGED_ADVANCED]
const MELEE_TYPES: Array[int] = [UnitData.UnitType.MELEE_BASIC, UnitData.UnitType.MELEE_ADVANCED]


func modify_roll(outcome: CombatOutcome, unit: UnitInstance, _lander: Lander, contest: Contest, side: int) -> void:
	if unit.get_unit_type() not in RANGED_TYPES:
		return
	for ally in contest.get_units(side):
		if ally != unit and ally.get_unit_type() in MELEE_TYPES:
			outcome.add_modifier(bonus, get_display_name())
			return
