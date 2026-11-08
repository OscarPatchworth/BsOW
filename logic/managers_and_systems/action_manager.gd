# action_manager.gd
class_name ActionManager
extends Node

## The rules gate. Every Action goes through request_action(): it is validated first
## (_validate returns a rejection reason, or "" when the action is allowed), then executed
## (or announced through an *_approved signal).

signal build_approved(action: Action)
signal biome_placement_approved(action: Action)
signal turn_progress_approved()

var _lander_manager: LanderManager
var _turn_manager: TurnManager
var _combat_manager: CombatManager


#region Public API
func bind_lander_manager(lander_manager: LanderManager) -> void:
	_lander_manager = lander_manager


func bind_turn_manager(turn_manager: TurnManager) -> void:
	_turn_manager = turn_manager


func bind_combat_manager(combat_manager: CombatManager) -> void:
	_combat_manager = combat_manager


func request_action(action: Action) -> void:
	var reason := _validate(action)
	if reason != "":
		_reject(action, reason)
		return
	_execute(action)
#endregion


#region Validation
## Returns why `action` is not allowed right now, or "" if it is.
func _validate(action: Action) -> String:
	if action.get_actor() == null:
		return "Action has no actor"
	match action.get_type():
		Action.Type.PLACE_BIOME:
			return _validate_place_biome(action)
		Action.Type.PLACE_BUILDING:
			return _validate_place_building(action)
		Action.Type.PLACE_LANDER:
			return _validate_place_lander(action)
		Action.Type.PURCHASE:
			return _validate_purchase(action)
		Action.Type.MOVE_UNITS:
			return _validate_move_units(action)
		Action.Type.ATTACK:
			return _validate_attack(action)
		Action.Type.PROGRESS_TURN:
			return _validate_progress_turn(action)
	return "Unknown action type"


func _validate_place_biome(action: Action) -> String:
	if _turn_manager.get_game_state() != TurnManager.GameState.SETUP:
		return "Biomes can only be placed during setup"
	if action.get_biome_data() == null:
		return "No biome chosen"
	if not _lander_manager.is_valid_lander_placement(action.get_position()):
		return "Invalid lander placement"
	return ""


## PLACE_BUILDING is only the free command tower at the end of setup.
## Every other building is bought with PURCHASE.
func _validate_place_building(action: Action) -> String:
	if _turn_manager.get_game_state() != TurnManager.GameState.SETUP:
		return "Buildings are bought with PURCHASE outside of setup"
	var command_tower := action.get_actor().get_species().get_command_tower()
	if action.get_building_data() != command_tower:
		return "Only the command tower can be placed for free"
	var lander := action.get_target_lander()
	if lander == null:
		return "Missing target lander"
	if lander.has_building():
		return "Lander already has a building"
	if _has_command_tower(action.get_actor()):
		return "Actor already has a command tower"
	return ""


func _validate_place_lander(action: Action) -> String:
	var reason := _require_turn(action, TurnManager.Phase.DUSTCLOUD_COLLAPSE)
	if reason != "":
		return reason
	if not _lander_manager.is_valid_lander_placement(action.get_position()):
		return "Invalid lander placement"
	return ""


func _validate_purchase(action: Action) -> String:
	var reason := _require_turn(action, TurnManager.Phase.BUYING)
	if reason != "":
		return reason

	var actor := action.get_actor()
	var lander := action.get_target_lander()
	var purchasable := action.get_purchasable()
	if lander == null:
		return "Missing target lander"
	if purchasable == null:
		return "Nothing chosen to buy"
	if lander.get_owner_actor() != actor:
		return "Actor does not own the target lander"
	if purchasable not in lander.get_purchasables(actor):
		return "'%s' can't be bought on this lander" % purchasable.get("display_name")
	if not actor.get_wallet().can_afford(_get_cost(purchasable)):
		return "Actor can not afford '%s'" % purchasable.get("display_name")

	if purchasable is BuildingData and lander.has_building():
		return "Lander already has a building (upgrades aren't implemented yet)"
	if purchasable is UnitData and lander.is_full():
		return "Lander is full"
	return ""


func _validate_move_units(action: Action) -> String:
	var reason := _require_turn(action, TurnManager.Phase.COMBAT)
	if reason != "":
		return reason
	reason = _require_two_connected_landers(action)
	if reason != "":
		return reason

	var actor := action.get_actor()
	var source := action.get_source_lander()
	var target := action.get_target_lander()
	var units := action.get_units()
	if units.is_empty():
		return "No units chosen"
	for unit in units:
		if unit not in source.get_units():
			return "A chosen unit is not on the source lander"
		if unit.get_owner_actor() != actor:
			return "A chosen unit belongs to someone else"
	var target_owner := target.get_owner_actor()
	if target_owner != null and target_owner != actor:
		return "Target lander is hostile"
	if target.get_units().size() + units.size() > target.get_unit_capacity():
		return "Target lander doesn't have room for those units"
	return ""


func _validate_attack(action: Action) -> String:
	var reason := _require_turn(action, TurnManager.Phase.COMBAT)
	if reason != "":
		return reason
	reason = _require_two_connected_landers(action)
	if reason != "":
		return reason

	var source_units := action.get_source_lander().get_units()
	var target_units := action.get_target_lander().get_units()
	if source_units.is_empty():
		return "Source lander has no units"
	if target_units.is_empty():
		return "Target lander has no units"
	if source_units[0].get_owner_actor() != action.get_actor():
		return "Attacking units don't belong to the attacking actor"
	if target_units[0].get_owner_actor() == action.get_actor():
		return "Source and target landers are allies"
	return ""


func _validate_progress_turn(action: Action) -> String:
	if _turn_manager.get_game_state() != TurnManager.GameState.MAIN_LOOP:
		return "The turn can only be progressed in the main loop"
	if _turn_manager.get_active_actor() != action.get_actor():
		return "It is not this actor's turn"
	if _turn_manager.get_game_phase() in _turn_manager.get_admin_phases():
		return "Admin phases can't be progressed by an actor"
	return ""


## Main loop, this actor's turn, and the given phase.
func _require_turn(action: Action, phase: TurnManager.Phase) -> String:
	if _turn_manager.get_game_state() != TurnManager.GameState.MAIN_LOOP:
		return "Only allowed in the main loop"
	if _turn_manager.get_active_actor() != action.get_actor():
		return "It is not this actor's turn"
	if _turn_manager.get_game_phase() != phase:
		return "Only allowed in the %s phase" % TurnManager.get_phase_name(phase)
	return ""


func _require_two_connected_landers(action: Action) -> String:
	var source := action.get_source_lander()
	var target := action.get_target_lander()
	if source == null or target == null:
		return "Missing source or target lander"
	if source == target:
		return "Source and target are the same lander"
	if target not in _lander_manager.get_connected_landers(source):
		return "Target lander is not connected to the source lander"
	return ""
#endregion


#region Execution
## Applies an action that has already passed _validate().
func _execute(action: Action) -> void:
	match action.get_type():
		Action.Type.PLACE_BIOME:
			biome_placement_approved.emit(action)
		Action.Type.PLACE_BUILDING:
			build_approved.emit(action)
		Action.Type.PLACE_LANDER:
			_lander_manager.spawn_random_lander(action.get_position())
			turn_progress_approved.emit()
		Action.Type.PURCHASE:
			action.get_actor().get_wallet().subtract(_get_cost(action.get_purchasable()))
			if action.get_purchasable() is BuildingData:
				action.get_target_lander().build(action)
			else:
				action.get_target_lander().buy_unit(action)
		Action.Type.MOVE_UNITS:
			_lander_manager.move_units(action)
		Action.Type.ATTACK:
			_combat_manager.start_combat(action)
		Action.Type.PROGRESS_TURN:
			turn_progress_approved.emit()
#endregion


#region Private
func _get_cost(purchasable: Resource) -> EconData:
	if purchasable is BuildingData:
		return (purchasable as BuildingData).get_cost()
	if purchasable is UnitData:
		return (purchasable as UnitData).get_cost()
	return EconData.new()


func _has_command_tower(actor: Actor) -> bool:
	var command_tower := actor.get_species().get_command_tower()
	for lander in _lander_manager.get_landers_owned_by(actor):
		if lander.has_building() and lander.get_building().get_building_data() == command_tower:
			return true
	return false


func _reject(action: Action, reason: String) -> void:
	print("ActionManager | Rejected %s | %s" % [Action.Type.find_key(action.get_type()), reason])
#endregion
