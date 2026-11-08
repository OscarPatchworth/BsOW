# action.gd
class_name Action
extends RefCounted

## A request to change the game state. Every change goes through the ActionManager as an Action:
## actors request them (UI, controller, AI), and the game requests "system" actions for its
## own steps (upkeep, resolving combat, skipping admin phases).

enum Type {
	# Actor actions
	MOVE_UNITS,
	ATTACK,
	PURCHASE,
	PLACE_LANDER,
	PLACE_BUILDING,
	PROGRESS_TURN,
	PLACE_BIOME,
	SELECT_COMBAT_UNIT,
	DESELECT_COMBAT_UNIT,
	DECLARE_COMBAT_READY,
	WITHDRAW_COMBAT_READY,
	RETREAT_COMBAT,
	# System actions (only the game requests these)
	FINISH_SETUP,
	COLLECT_UPKEEP,
	RESOLVE_COMBAT,
}

## What happens to an enemy building when units move onto its undefended lander.
enum BuildingFate {
	NONE,
	CAPTURE,  ## The building becomes the mover's.
	RAZE,     ## The building is destroyed.
}

var _type: Type
var _actor: Actor
var _position: Vector3
var _source_lander: Lander
var _target_lander: Lander
var _units: Array[UnitInstance] = []
var _building_data: BuildingData
var _unit_data: UnitData
var _biome_data: BiomeData
## A BuildingData or UnitData chosen from the market.
var _purchasable: Resource
var _building_fate: BuildingFate = BuildingFate.NONE

# Pipeline flags. Not hooked: they control how the action is processed, they aren't game state.
var _is_system: bool = false
var _cancel_reason: String = ""


static func create(type: Type) -> Action:
	var action := Action.new()
	action.set_type(type)
	return action


## An action the game requests for itself. `actor` is who it applies to (e.g. whose upkeep).
static func create_system(type: Type, actor: Actor = null) -> Action:
	var action := create(type)
	action._is_system = true
	action.set_actor(actor)
	return action


#region Public API
func is_system() -> bool:
	return _is_system


## Called from an ActionManager.action_resolving listener to stop this action from executing.
func cancel(reason: String) -> void:
	_cancel_reason = reason if reason != "" else "Cancelled"


func is_cancelled() -> bool:
	return _cancel_reason != ""


func get_cancel_reason() -> String:
	return _cancel_reason


func to_debug_dictionary() -> Dictionary:
	return {
		"type": Type.find_key(_type),
		"is_system": _is_system,
		"actor": _actor.name if _actor else "",
		"position": _position,
		"source_lander": _describe_lander(_source_lander),
		"target_lander": _describe_lander(_target_lander),
		"units": _units.size(),
		"building_data": _building_data.get_display_name() if _building_data else "",
		"unit_data": _unit_data.get_display_name() if _unit_data else "",
		"biome_data": _biome_data.get_display_name() if _biome_data else "",
		"purchasable": _purchasable.get("display_name") if _purchasable else "",
		"building_fate": BuildingFate.find_key(_building_fate),
	}
#endregion


#region Accessors
func get_type() -> Type:
	return AbilitySystem.resolve_get(self, &"type", _type)


func set_type(value: Type) -> void:
	_type = AbilitySystem.resolve_set(self, &"type", _type, value)


func get_actor() -> Actor:
	return AbilitySystem.resolve_get(self, &"actor", _actor)


func set_actor(value: Actor) -> void:
	_actor = AbilitySystem.resolve_set(self, &"actor", _actor, value)


func get_position() -> Vector3:
	return AbilitySystem.resolve_get(self, &"position", _position)


func set_position(value: Vector3) -> void:
	_position = AbilitySystem.resolve_set(self, &"position", _position, value)


func get_source_lander() -> Lander:
	return AbilitySystem.resolve_get(self, &"source_lander", _source_lander)


func set_source_lander(value: Lander) -> void:
	_source_lander = AbilitySystem.resolve_set(self, &"source_lander", _source_lander, value)


func get_target_lander() -> Lander:
	return AbilitySystem.resolve_get(self, &"target_lander", _target_lander)


func set_target_lander(value: Lander) -> void:
	_target_lander = AbilitySystem.resolve_set(self, &"target_lander", _target_lander, value)


func get_units() -> Array[UnitInstance]:
	return AbilitySystem.resolve_get(self, &"units", _units)


func set_units(value: Array[UnitInstance]) -> void:
	_units = AbilitySystem.resolve_set(self, &"units", _units, value)


func get_building_data() -> BuildingData:
	return AbilitySystem.resolve_get(self, &"building_data", _building_data)


func set_building_data(value: BuildingData) -> void:
	_building_data = AbilitySystem.resolve_set(self, &"building_data", _building_data, value)


func get_unit_data() -> UnitData:
	return AbilitySystem.resolve_get(self, &"unit_data", _unit_data)


func set_unit_data(value: UnitData) -> void:
	_unit_data = AbilitySystem.resolve_set(self, &"unit_data", _unit_data, value)


func get_biome_data() -> BiomeData:
	return AbilitySystem.resolve_get(self, &"biome_data", _biome_data)


func set_biome_data(value: BiomeData) -> void:
	_biome_data = AbilitySystem.resolve_set(self, &"biome_data", _biome_data, value)


func get_building_fate() -> BuildingFate:
	return AbilitySystem.resolve_get(self, &"building_fate", _building_fate)


func set_building_fate(value: BuildingFate) -> void:
	_building_fate = AbilitySystem.resolve_set(self, &"building_fate", _building_fate, value)


func get_purchasable() -> Resource:
	return AbilitySystem.resolve_get(self, &"purchasable", _purchasable)


func set_purchasable(value: Resource) -> void:
	_purchasable = AbilitySystem.resolve_set(self, &"purchasable", _purchasable, value)
#endregion


#region Private
func _describe_lander(lander: Lander) -> String:
	if lander == null or lander.get_biome_data() == null:
		return ""
	return lander.get_biome_data().get_display_name()
#endregion
