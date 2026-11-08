# action_manager.gd
class_name ActionManager
extends Node

## The rules gate. Every Action goes through request_action(); valid ones are executed
## (or announced through an *_approved signal), invalid ones are rejected with a message.

signal build_approved(action: Action)
signal unit_purchase_approved(action: Action)
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
	match action.get_type():
		Action.Type.PLACE_LANDER:
			_handle_place_lander(action)
		Action.Type.MOVE_UNITS:
			_handle_move_units(action)
		Action.Type.ATTACK:
			_handle_attack(action)
		Action.Type.PURCHASE:
			_handle_purchase(action)
		Action.Type.PLACE_BUILDING:
			_handle_place_building(action)
		Action.Type.BUY_UNIT:
			_handle_buy_unit(action)
		Action.Type.PROGRESS_TURN:
			_handle_progress_turn(action)
		Action.Type.PLACE_BIOME:
			_handle_place_biome(action)
		_:
			_reject(action, "Unknown action type")
#endregion


#region Handlers
func _handle_place_lander(action: Action) -> void:
	if not _lander_manager.is_valid_lander_placement(action.get_position()):
		_reject(action, "Invalid lander placement")
		return
	_lander_manager.spawn_random_lander(action.get_position())
	turn_progress_approved.emit()


func _handle_place_building(action: Action) -> void:
	if action.get_target_lander().has_building():
		_reject(action, "Lander already has a building")
		return
	build_approved.emit(action)


func _handle_buy_unit(action: Action) -> void:
	var lander := action.get_target_lander()
	if lander == null:
		_reject(action, "Missing target lander")
		return
	var building := lander.get_building()
	if building == null:
		_reject(action, "Target lander has no building to spawn units from")
		return
	if not building.can_spawn_units():
		_reject(action, "'%s' can not spawn units" % building.get_display_name())
		return
	if action.get_unit_data().get_unit_type() not in building.get_spawnable_unit_types():
		_reject(action, "'%s' can not spawn unit type %s" % [
			building.get_display_name(), UnitData.UnitType.find_key(action.get_unit_data().get_unit_type())])
		return
	unit_purchase_approved.emit(action)


func _handle_move_units(action: Action) -> void:
	var target_owner := action.get_target_lander().get_owner_actor()
	if target_owner != null and target_owner != action.get_actor():
		_reject(action, "Target lander is hostile")
		return
	_lander_manager.move_units(action)


func _handle_attack(action: Action) -> void:
	var source_units := action.get_source_lander().get_units()
	var target_units := action.get_target_lander().get_units()
	if source_units.is_empty():
		_reject(action, "Source lander has no units")
		return
	if target_units.is_empty():
		_reject(action, "Target lander has no units")
		return
	if source_units[0].get_owner_actor() == target_units[0].get_owner_actor():
		_reject(action, "Source and target landers are allies")
		return
	if source_units[0].get_owner_actor() != action.get_actor():
		_reject(action, "Attacking units don't belong to the attacking actor")
		return
	_combat_manager.start_combat(action)


func _handle_progress_turn(action: Action) -> void:
	var phase := _turn_manager.get_game_phase()
	if phase in _turn_manager.get_admin_phases():
		_reject(action, "Admin phases can't be progressed by an actor")
		return
	if phase in _turn_manager.get_non_skippable_phases():
		# Not enforced yet: the warning is kept so the rule is visible.
		print("ActionManager | Rules | Actor is progressing a non-skippable phase")
	turn_progress_approved.emit()


func _handle_purchase(action: Action) -> void:
	var purchasable := action.get_purchasable()
	var wallet := action.get_actor().get_wallet()
	var lander := action.get_source_lander()

	if purchasable is BuildingData:
		var cost := (purchasable as BuildingData).get_cost()
		if not wallet.can_afford(cost):
			_reject(action, "Actor can not afford the building")
			return
		if lander.has_building():
			_reject(action, "Lander already has a building")
			return
		wallet.subtract(cost)
		lander.build(action)

	elif purchasable is UnitData:
		var cost := (purchasable as UnitData).get_cost()
		if not wallet.can_afford(cost):
			_reject(action, "Actor can not afford the unit")
			return
		wallet.subtract(cost)
		lander.buy_unit(action)

	else:
		_reject(action, "Purchasable is not a BuildingData or UnitData")


func _handle_place_biome(action: Action) -> void:
	if not _lander_manager.is_valid_lander_placement(action.get_position()):
		_reject(action, "Invalid lander placement")
		return
	biome_placement_approved.emit(action)
#endregion


#region Private
func _reject(action: Action, reason: String) -> void:
	print("ActionManager | Rejected %s | %s" % [Action.Type.find_key(action.get_type()), reason])
#endregion
