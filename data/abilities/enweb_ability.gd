# enweb_ability.gd
class_name EnwebAbility
extends Ability

## A race trait that lets its owner spin webs (the ENWEB action): in their Buying phase, for
## `cost`, onto a lander connected to one of theirs that they don't own. While the web is up,
## units on that lander that aren't of a race with this ability get `penalty` on their combat
## roll and can't move off it. Any of those units can spend its move to tear the web down
## (RAZE_WEB); otherwise it wears off after `duration_turns` of the web owner's turns.

@export var cost: EconData
@export var penalty: int = -1
@export var duration_turns: int = 2


func get_cost() -> EconData:
	return AbilitySystem.resolve_get(self, &"cost", cost if cost != null else EconData.new())


func get_duration_turns() -> int:
	return AbilitySystem.resolve_get(self, &"duration_turns", duration_turns)


## Webs don't hold or slow the race that spins them.
func is_caught(unit: UnitInstance, lander: Lander) -> bool:
	return lander.has_web() and lander.get_web().get_ability() == self and not is_trait_of(unit)


func modify_roll(outcome: CombatOutcome, unit: UnitInstance, lander: Lander, _contest: Contest, _side: int) -> void:
	if is_caught(unit, lander):
		outcome.add_modifier(penalty, get_display_name())


func check_move(unit: UnitInstance, from: Lander, _to: Lander) -> String:
	if is_caught(unit, from):
		return "%s is stuck in a web: tear it down first (uses a unit's move)" % unit.get_display_name()
	return ""
