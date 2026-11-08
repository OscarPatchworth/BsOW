# actor.gd
class_name Actor
extends Node

## Base class for anything that takes turns: the local Player and AI opponents.

var _species: SpeciesData
var _wallet: EconData

var _turn_manager: TurnManager
var _lander_manager: LanderManager
var _combat_manager: CombatManager

## Which side of the current contest this actor is on, or -1 when not in combat.
var _combat_side: int = -1


#region Public API
func bind_turn_manager(turn_manager: TurnManager) -> void:
	_turn_manager = turn_manager


func bind_lander_manager(lander_manager: LanderManager) -> void:
	_lander_manager = lander_manager


func bind_combat_manager(combat_manager: CombatManager) -> void:
	_combat_manager = combat_manager
#endregion


#region Accessors
func get_species() -> SpeciesData:
	return AbilitySystem.resolve_get(self, &"species", _species)


func set_species(value: SpeciesData) -> void:
	_species = AbilitySystem.resolve_set(self, &"species", _species, value)


func get_wallet() -> EconData:
	return AbilitySystem.resolve_get(self, &"wallet", _wallet)


func set_wallet(value: EconData) -> void:
	_wallet = AbilitySystem.resolve_set(self, &"wallet", _wallet, value)


func get_combat_side() -> int:
	return AbilitySystem.resolve_get(self, &"combat_side", _combat_side)


func set_combat_side(value: int) -> void:
	_combat_side = AbilitySystem.resolve_set(self, &"combat_side", _combat_side, value)
#endregion


#region Signal handlers
func _on_combat_manager_combat_started(contest: Contest) -> void:
	if not contest.is_involved(self):
		return  # Not our fight. (Spectating could hook in here later.)
	set_combat_side(contest.get_side_of(self))
	_enter_combat(contest)
#endregion


#region Virtual
## Override in subclasses: called when a contest this actor is part of starts.
func _enter_combat(_contest: Contest) -> void:
	pass
#endregion
