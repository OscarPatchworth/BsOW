# ability.gd
class_name Ability
extends Resource

## A rule that changes how the game plays. Abilities are data: a script that extends this one,
## saved as a .tres and attached where it belongs:
##   SpeciesData.abilities    traits of a race (apply to that race's units)
##   UnitData.abilities       traits of one kind of unit
##   BuildingData.abilities   effects of a building (apply on its lander)
##   MatchSettings.rule_abilities   rules for everyone (e.g. combined arms)
## A web on a lander also carries the ability that spun it.
##
## The AbilitySystem finds the abilities in play for a unit (see AbilitySystem.abilities_for)
## and calls the hooks below. Every hook does nothing by default; override the ones you need.
## Hooks get the context they need as arguments, so an ability never looks anything up itself.

@export var display_name: String
@export_multiline var description: String
## Properties this ability can change through AbilitySystem.resolve_get (see modify_value).
@export var value_hooks: Array[StringName] = []


#region Hooks
## Combat: add modifiers to `outcome` for `unit`, which is fighting on `lander` for `side`
## (Contest.Side) of `contest`. Use outcome.add_modifier(amount, display_name).
func modify_roll(_outcome: CombatOutcome, _unit: UnitInstance, _lander: Lander, _contest: Contest, _side: int) -> void:
	pass


## Movement: "" if `unit` may move from `from` to `to`, otherwise why not.
func check_move(_unit: UnitInstance, _from: Lander, _to: Lander) -> String:
	return ""


## Movement: false if this move doesn't use up the unit's one move this turn.
func move_spends_movement(_unit: UnitInstance, _from: Lander, _to: Lander) -> bool:
	return true


## Combat: `outcome.get_unit()` won its pairing and the unit it faced died. `lander` is where
## the winner fought. Return a line for the battle log, or "".
func on_defeated_opponent(_outcome: CombatOutcome, _lander: Lander) -> String:
	return ""


## Values: change `value` of `property` on `target` (only called for properties in value_hooks).
func modify_value(_target: Object, _property: StringName, value: Variant) -> Variant:
	return value
#endregion


#region Helpers for subclasses
## True if `unit` belongs to a race that has this ability.
func is_trait_of(unit: UnitInstance) -> bool:
	var owner_actor := unit.get_owner_actor()
	return owner_actor != null and owner_actor.get_species() != null and self in owner_actor.get_species().get_abilities()


func get_display_name() -> String:
	return AbilitySystem.resolve_get(self, &"display_name", display_name)


func get_description() -> String:
	return AbilitySystem.resolve_get(self, &"description", description)
#endregion
