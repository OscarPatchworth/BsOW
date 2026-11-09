# ability_system.gd
# Autoload singleton, registered in project.godot as "AbilitySystem".
extends Node

## Where abilities (see Ability) plug into the game.
##
## 1. Value hooks. Every hooked getter in the game ends with
##        return AbilitySystem.resolve_get(self, &"property", _property)
##    and every hooked setter writes through
##        _property = AbilitySystem.resolve_set(self, &"property", _property, value)
##    An ability that lists a property in its value_hooks gets to change that value
##    (Ability.modify_value). Properties no ability hooks pass straight through, so the
##    hundreds of plain reads per frame stay cheap.
##        target   - the object that owns the value (a UnitInstance, Lander, EconData, ...)
##        property - the property name, matching the getter/setter name without get_/set_
##        value    - the stored (base) value
##    Search the codebase for "resolve_get(" / "resolve_set(" to list every hook point.
##
## 2. Rule hooks. The game asks here at the moments abilities care about:
##        add_combat_modifiers()     a unit's battle roll (bonuses and penalties)
##        check_move()               may this unit move there?
##        move_spends_movement()     does this move use up the unit's move?
##        after_combat_round()       react to kills (e.g. Pack Call)
##    Each asks the abilities in play for that unit: abilities_for().
##
## begin_match() registers what's in play (GameRoot calls it once the actors exist).

var _match_settings: MatchSettings
## Every ability that can come into play this match (rules, races, their units and buildings).
var _all_abilities: Array[Ability] = []
## Property -> abilities that hook it (Ability.value_hooks).
var _value_hooks := {}


#region Setup
func bind_match_settings(match_settings: MatchSettings) -> void:
	_match_settings = match_settings


## Registers the match rules and every ability the actors' races can bring into play.
func begin_match(actors: Array[Actor]) -> void:
	_all_abilities.clear()
	_value_hooks.clear()
	for ability in get_rule_abilities():
		_register(ability)
	for actor in actors:
		var species := actor.get_species()
		for ability in species.get_abilities():
			_register(ability)
		for unit_data in species.get_units():
			for ability in unit_data.get_abilities():
				_register(ability)
		for building_data in species.get_buildings():
			for ability in building_data.get_abilities():
				_register(ability)
#endregion


#region Value hooks
func resolve_get(target: Object, property: StringName, base_value: Variant) -> Variant:
	var hooks: Array = _value_hooks.get(property, [])
	if hooks.is_empty():
		return base_value
	var value: Variant = base_value
	for ability: Ability in hooks:
		value = ability.modify_value(target, property, value)
	return value


func resolve_set(_target: Object, _property: StringName, _current_value: Variant, new_value: Variant) -> Variant:
	return new_value
#endregion


#region Rule hooks
## Match-wide rules (MatchSettings.rule_abilities).
func get_rule_abilities() -> Array[Ability]:
	if _match_settings == null:
		return [] as Array[Ability]
	return _match_settings.get_rule_abilities()


## The abilities that apply to `unit` while it is on `lander`: the match rules, its race's
## traits, its own unit type's, the building on the lander, and a web on the lander.
## Each ability still decides for itself whether it fires.
func abilities_for(unit: UnitInstance, lander: Lander) -> Array[Ability]:
	var found: Array[Ability] = []
	_add_all(found, get_rule_abilities())
	var owner_actor := unit.get_owner_actor()
	if owner_actor != null and owner_actor.get_species() != null:
		_add_all(found, owner_actor.get_species().get_abilities())
	_add_all(found, unit.get_unit_data().get_abilities())
	if lander != null:
		if lander.has_building():
			_add_all(found, lander.get_building().get_building_data().get_abilities())
		if lander.has_web():
			_add_all(found, [lander.get_web().get_ability()] as Array[Ability])
	return found


## Adds every ability's bonus or penalty to `outcome` (one unit's roll in `contest`).
func add_combat_modifiers(outcome: CombatOutcome, contest: Contest, side: int) -> void:
	var unit := outcome.get_unit()
	var lander := contest.get_lander(side)
	for ability in abilities_for(unit, lander):
		ability.modify_roll(outcome, unit, lander, contest, side)
	outcome.set_total(outcome.calculate_total())


## "" if `unit` may move from `from` to `to`, otherwise the first ability's reason why not.
func check_move(unit: UnitInstance, from: Lander, to: Lander) -> String:
	for ability in abilities_for(unit, from):
		var reason := ability.check_move(unit, from, to)
		if reason != "":
			return reason
	return ""


## False if an ability makes this move free (it doesn't use up the unit's move this turn).
func move_spends_movement(unit: UnitInstance, from: Lander, to: Lander) -> bool:
	for ability in abilities_for(unit, from):
		if not ability.move_spends_movement(unit, from, to):
			return false
	return true


## After a battle round: every unit that won its pairing and killed the unit it faced gets its
## abilities' on_defeated_opponent. Returns the lines worth logging.
func after_combat_round(contest: Contest, outcomes_by_side: Dictionary) -> Array[String]:
	var notes: Array[String] = []
	for side: int in outcomes_by_side:
		var lander := contest.get_lander(side)
		for outcome: CombatOutcome in outcomes_by_side[side]:
			var opponent := outcome.get_opponent()
			if outcome.get_outcome() != CombatOutcome.Outcome.ALIVE or opponent == null \
					or opponent.get_outcome() != CombatOutcome.Outcome.DEAD:
				continue
			for ability in abilities_for(outcome.get_unit(), lander):
				var note := ability.on_defeated_opponent(outcome, lander)
				if note != "":
					notes.append(note)
	return notes


## A race's ability of a given script (e.g. its EnwebAbility), or null.
func find_species_ability(species: SpeciesData, script: Script) -> Ability:
	if species == null:
		return null
	for ability in species.get_abilities():
		if is_instance_of(ability, script):
			return ability
	return null
#endregion


#region Private
func _register(ability: Ability) -> void:
	if ability == null or ability in _all_abilities:
		return
	_all_abilities.append(ability)
	for property in ability.value_hooks:
		if not _value_hooks.has(property):
			_value_hooks[property] = []
		(_value_hooks[property] as Array).append(ability)


func _add_all(found: Array[Ability], abilities: Array[Ability]) -> void:
	for ability in abilities:
		if ability != null and ability not in found:
			found.append(ability)
#endregion
