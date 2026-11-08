# simple_ai.gd
class_name SimpleAI
extends Actor

## A simple opponent so a game can be play-tested alone. Its turn:
##   DUSTCLOUD_COLLAPSE  places a lander next to one of its own, heading towards the nearest enemy.
##   BUYING              buys a spawning building where it has none, then the best units it can afford.
##   COMBAT              attacks weaker neighbours one fight at a time (waiting for each to resolve),
##                       then claims empty neighbouring landers and marches spare units towards
##                       the nearest enemy, and ends its turn.
## In any combat it picks its strongest units and declares ready.
## Everything goes through request_action(), so it plays by exactly the same rules as the Player.
##
## Pacing: every action and decision is a queued step. Before each step the AI waits step_delay
## seconds (so a human can follow its turn) and for the GravitySystem to settle (connections can
## change while landers move). Steps queued in an earlier phase are dropped. With step_delay 0 and
## a settled board nothing waits, so the turn runs straight through (tests use this).

## Attacks per turn, so a turn always ends.
const MAX_ATTACKS_PER_TURN: int = 2
## Only attack when we bring at least this many more units than the defender has.
const ATTACK_ADVANTAGE: int = 1
## Units bought per lander per turn.
const MAX_UNITS_BOUGHT_PER_LANDER: int = 2
## How many spots to try around each lander when placing a new one.
const PLACEMENT_ANGLES: int = 12
## The new lander goes on one of this many spots closest to an enemy.
const PLACEMENT_SHORTLIST: int = 3

## Seconds between the AI's actions. GameRoot sets it from MatchSettings.ai_step_delay.
var step_delay: float = 0.6

var _gravity_system: GravitySystem
var _steps: Array[Callable] = []
var _step_tokens: Array[int] = []
var _phase_token: int = 0
var _is_running_steps: bool = false

var _attacks_this_turn: int = 0
var _attacked_landers: Array[Lander] = []
var _placement_attempts: int = 0


func bind_gravity_system(gravity_system: GravitySystem) -> void:
	_gravity_system = gravity_system


## True while the AI still has steps to take (tests wait for this).
func is_busy() -> bool:
	return _is_running_steps or not _steps.is_empty()


#region Virtual overrides
func _game_phase_changed(_phase: TurnManager.Phase) -> void:
	_phase_token += 1  # Anything still queued from the previous phase is stale.


func _take_phase(phase: TurnManager.Phase) -> void:
	_queue_step(_do_phase.bind(phase))


func _do_phase(phase: TurnManager.Phase) -> void:
	match phase:
		TurnManager.Phase.DUSTCLOUD_COLLAPSE:
			_placement_attempts = 0
			_place_lander()  # Placing the lander ends the phase by itself.
		TurnManager.Phase.BUYING:
			_buy()
			_end_phase()
		TurnManager.Phase.COMBAT:
			_attacks_this_turn = 0
			_attacked_landers.clear()
			_continue_combat_phase()
		_:
			_end_phase()


func _enter_combat(contest: Contest) -> void:
	_queue_step(_select_and_ready.bind(contest))


func _action_resolved(action: Action) -> void:
	match action.get_type():
		Action.Type.RESOLVE_COMBAT:
			var contest := _combat_manager.get_contest()
			if _combat_manager.is_in_progress() and contest.is_involved(self):
				_queue_step(_fight_next_round.bind(contest))
			elif _is_my_phase(TurnManager.Phase.COMBAT):
				_queue_step(_continue_combat_phase)  # Our battle is over: carry on with the turn.
		Action.Type.RETREAT_COMBAT:
			if _is_my_phase(TurnManager.Phase.COMBAT):
				_queue_step(_continue_combat_phase)


func _action_rejected(action: Action, reason: String) -> void:
	# Never leave the turn hanging: fall back to the next step.
	print("SimpleAI | %s rejected (%s)" % [Action.Type.find_key(action.get_type()), reason])
	match action.get_type():
		Action.Type.PLACE_LANDER:
			_queue_step(_place_lander)
		Action.Type.ATTACK:
			if _is_my_phase(TurnManager.Phase.COMBAT):
				_queue_step(_continue_combat_phase)
#endregion


#region Steps
## Sends `action` as its own paced step.
func _send(action: Action) -> void:
	_queue_step(request_action.bind(action))


func _queue_step(step: Callable) -> void:
	_steps.append(step)
	_step_tokens.append(_phase_token)
	_run_steps()


func _run_steps() -> void:
	if _is_running_steps:
		return  # The running loop picks the new step up.
	_is_running_steps = true
	while not _steps.is_empty():
		await _pause_before_step()
		var step: Callable = _steps.pop_front()
		var token: int = _step_tokens.pop_front()
		if token == _phase_token:
			step.call()
	_is_running_steps = false


## Waits step_delay, then for the board to settle. Returns at once when neither applies.
func _pause_before_step() -> void:
	if step_delay > 0.0:
		await get_tree().create_timer(step_delay).timeout
	if _gravity_system != null and not _gravity_system.is_settled():
		await _gravity_system.board_settled
#endregion


#region Dustcloud collapse
func _place_lander() -> void:
	var spot: Variant = _find_lander_spot()
	if spot == null:
		push_warning("SimpleAI | Found nowhere to place a lander; DUSTCLOUD_COLLAPSE can't end")
		return
	var place := Action.create(Action.Type.PLACE_LANDER)
	place.set_position(spot)
	_send(place)


## A clear spot connected to one of our landers, preferring the one closest to an enemy so the
## AI builds a path towards its opponents. Falls back to anywhere clear near the middle.
## Returns a Vector3, or null if nothing was found.
func _find_lander_spot() -> Variant:
	_placement_attempts += 1
	if _placement_attempts > 3:
		return null

	# Between the minimum spacing and the connection range, so the new lander is connected.
	var distance := (LanderManager.MIN_DISTANCE_BETWEEN_LANDERS + _lander_manager.get_connected_lander_distance()) / 2.0
	var candidates: Array[Vector3] = []
	for lander in _lander_manager.get_landers_owned_by(self):
		candidates.append_array(_clear_spots_around(Vector3(lander.position.x, 0, lander.position.z), distance))
	if candidates.is_empty():
		# We own nothing, or every lander is boxed in.
		for ring in range(1, 5):
			candidates = _clear_spots_around(Vector3.ZERO, distance * ring)
			if not candidates.is_empty():
				break
	if candidates.is_empty():
		return null

	var enemy_positions := _enemy_lander_positions()
	if enemy_positions.is_empty():
		return candidates.pick_random()
	# Pick among the few spots closest to an enemy, so it heads their way without being predictable.
	candidates.sort_custom(func(a: Vector3, b: Vector3) -> bool:
		return _distance_to_nearest(a, enemy_positions) < _distance_to_nearest(b, enemy_positions))
	return candidates.slice(0, PLACEMENT_SHORTLIST).pick_random()


func _clear_spots_around(centre: Vector3, radius: float) -> Array[Vector3]:
	var spots: Array[Vector3] = []
	var start_angle := randf() * TAU
	for i in PLACEMENT_ANGLES:
		var angle := start_angle + TAU * i / PLACEMENT_ANGLES
		var spot := centre + Vector3(cos(angle), 0, sin(angle)) * radius
		if _lander_manager.is_valid_lander_placement(spot):
			spots.append(spot)
	return spots


func _enemy_lander_positions() -> Array[Vector3]:
	var positions: Array[Vector3] = []
	for lander in _lander_manager.get_landers():
		var lander_owner := lander.get_owner_actor()
		if lander_owner != null and lander_owner != self:
			positions.append(Vector3(lander.position.x, 0, lander.position.z))
	return positions


func _distance_to_nearest(point: Vector3, positions: Array[Vector3]) -> float:
	var nearest := INF
	for position in positions:
		nearest = minf(nearest, point.distance_squared_to(position))
	return nearest
#endregion


#region Buying
func _buy() -> void:
	# Purchases resolve after this step, so track what's left to spend here.
	var budget := EconData.new()
	budget.add(get_wallet())
	for lander in _lander_manager.get_landers_owned_by(self):
		if lander.has_building():
			_buy_units(lander, budget)
		else:
			_buy_spawning_building(lander, budget)


func _buy_spawning_building(lander: Lander, budget: EconData) -> void:
	for purchasable in lander.get_purchasables(self):
		var building_data := purchasable as BuildingData
		if building_data == null or not building_data.can_spawn_units():
			continue
		if building_data.is_unique_building() or not budget.can_afford(building_data.get_cost()):
			continue
		budget.subtract(building_data.get_cost())
		_request_purchase(lander, building_data)
		return


func _buy_units(lander: Lander, budget: EconData) -> void:
	var free_slots := lander.get_unit_capacity() - lander.get_units().size()
	var unit_options: Array[UnitData] = []
	for purchasable in lander.get_purchasables(self):
		if purchasable is UnitData:
			unit_options.append(purchasable)
	unit_options.sort_custom(func(a: UnitData, b: UnitData) -> bool:
		return _average_damage(a.get_damage()) > _average_damage(b.get_damage()))

	var bought := 0
	for unit_data in unit_options:
		while bought < mini(free_slots, MAX_UNITS_BOUGHT_PER_LANDER) and budget.can_afford(unit_data.get_cost()):
			budget.subtract(unit_data.get_cost())
			_request_purchase(lander, unit_data)
			bought += 1


func _request_purchase(lander: Lander, purchasable: Resource) -> void:
	var purchase := Action.create(Action.Type.PURCHASE)
	purchase.set_target_lander(lander)
	purchase.set_purchasable(purchasable)
	_send(purchase)
#endregion


#region Battles
## Tops up our selection with the strongest units still standing, then readies up.
func _select_and_ready(contest: Contest) -> void:
	var side := contest.get_side_of(self)
	var selected := contest.get_units(side)
	var available := contest.get_available_units(side).duplicate()
	available.sort_custom(_is_stronger)
	var room := _combat_manager.get_max_units(side) - selected.size()
	for unit in available:
		if room <= 0:
			break
		if unit in selected:
			continue
		var select := Action.create(Action.Type.SELECT_COMBAT_UNIT)
		select.set_units([unit] as Array[UnitInstance])
		_send(select)
		room -= 1
	_send(Action.create(Action.Type.DECLARE_COMBAT_READY))


## A round is over and the battle goes on: keep fighting, or (as attacker) retreat when outnumbered.
func _fight_next_round(contest: Contest) -> void:
	var side := contest.get_side_of(self)
	var ours := contest.get_available_units(side).size()
	var theirs := contest.get_available_units(Contest.get_opposite_side(side)).size()
	if side == Contest.Side.ATTACKER and ours < theirs:
		_send(Action.create(Action.Type.RETREAT_COMBAT))
	else:
		_select_and_ready(contest)
#endregion


#region Combat phase
## One step of the combat phase: start an attack and wait for it, or move and end the phase.
func _continue_combat_phase() -> void:
	if _combat_manager.is_in_progress():
		return  # Still fighting; _action_resolved calls back in when it's over.
	if _attacks_this_turn < MAX_ATTACKS_PER_TURN and _try_attack():
		return
	_spread_units()
	_end_phase()


## Attacks the weakest enemy neighbour we clearly outnumber. Returns true if an attack was requested.
func _try_attack() -> bool:
	var best_source: Lander = null
	var best_target: Lander = null
	var best_margin := ATTACK_ADVANTAGE - 1
	for source in _lander_manager.get_landers_owned_by(self):
		var attackers := mini(source.get_units().size(), _combat_manager.get_max_units(Contest.Side.ATTACKER))
		if attackers == 0:
			continue
		for target in _lander_manager.get_connected_landers(source):
			var target_owner := target.get_owner_actor()
			if target_owner == null or target_owner == self or not target.has_units() or target in _attacked_landers:
				continue
			var margin := attackers - target.get_units().size()
			if margin > best_margin:
				best_margin = margin
				best_source = source
				best_target = target
	if best_target == null:
		return false

	_attacks_this_turn += 1
	_attacked_landers.append(best_target)
	var attack := Action.create(Action.Type.ATTACK)
	attack.set_source_lander(best_source)
	attack.set_target_lander(best_target)
	_send(attack)
	return true


## Each lander with spare units (it always keeps one behind) makes one move per turn:
##   1. claim an empty, unowned neighbour with half its units (the one nearest an enemy), or
##   2. send all its spare units to an owned neighbour that is closer to an enemy,
##      so units march along the AI's chain of landers towards the front.
## Moves only ever go strictly closer to an enemy, so units never bounce back and forth.
func _spread_units() -> void:
	var enemy_positions := _enemy_lander_positions()
	var incoming := {}  # Lander -> units already sent there this turn.
	for source in _lander_manager.get_landers_owned_by(self):
		var units := source.get_units()
		if units.size() < 2:
			continue

		var claim_target := _pick_claim_target(source, incoming, enemy_positions)
		if claim_target != null:
			_request_move(source, claim_target, units, floori(units.size() / 2.0), incoming)
			continue
		var advance_target := _pick_advance_target(source, incoming, enemy_positions)
		if advance_target != null:
			_request_move(source, advance_target, units, units.size() - 1, incoming)


## An empty neighbour to claim: an undefended enemy lander (its building can be taken) first,
## otherwise an empty neutral one nearest an enemy.
func _pick_claim_target(source: Lander, incoming: Dictionary, enemy_positions: Array[Vector3]) -> Lander:
	var best: Lander = null
	for target in _lander_manager.get_connected_landers(source):
		if target in incoming or target.has_units():
			continue
		var target_owner := target.get_owner_actor()
		if target_owner == self:
			continue
		if best == null:
			best = target
			continue
		var is_enemy := target_owner != null
		var best_is_enemy := best.get_owner_actor() != null
		if (is_enemy and not best_is_enemy) or (is_enemy == best_is_enemy and _closer_to_enemy(target, best, enemy_positions)):
			best = target
	return best


func _pick_advance_target(source: Lander, incoming: Dictionary, enemy_positions: Array[Vector3]) -> Lander:
	if enemy_positions.is_empty():
		return null
	var best: Lander = null
	for target in _lander_manager.get_connected_landers(source):
		if target.get_owner_actor() != self or _free_slots(target, incoming) <= 0:
			continue
		if not _closer_to_enemy(target, source, enemy_positions):
			continue
		if best == null or _closer_to_enemy(target, best, enemy_positions):
			best = target
	return best


func _request_move(source: Lander, target: Lander, units: Array[UnitInstance], wanted: int, incoming: Dictionary) -> void:
	var count := mini(wanted, _free_slots(target, incoming))
	if count <= 0:
		return
	var moving: Array[UnitInstance] = []
	for i in count:
		moving.append(units[i])
	incoming[target] = incoming.get(target, 0) + count
	var move := Action.create(Action.Type.MOVE_UNITS)
	move.set_source_lander(source)
	move.set_target_lander(target)
	move.set_units(moving)
	if target.has_building() and target.get_building().get_owner_actor() != self:
		move.set_building_fate(_choose_building_fate(target.get_building()))
	_send(move)


## Capture a building our species could build itself (we can use it); raze anything else.
func _choose_building_fate(building: BuildingInstance) -> Action.BuildingFate:
	if building.get_building_data() in get_species().get_buildings():
		return Action.BuildingFate.CAPTURE
	return Action.BuildingFate.RAZE


func _free_slots(lander: Lander, incoming: Dictionary) -> int:
	return lander.get_unit_capacity() - lander.get_units().size() - incoming.get(lander, 0)


func _closer_to_enemy(a: Lander, b: Lander, enemy_positions: Array[Vector3]) -> bool:
	if enemy_positions.is_empty():
		return false
	return (_distance_to_nearest(_flat(a.position), enemy_positions)
		< _distance_to_nearest(_flat(b.position), enemy_positions))
#endregion


#region Private
func _flat(position: Vector3) -> Vector3:
	return Vector3(position.x, 0, position.z)


func _end_phase() -> void:
	_send(Action.create(Action.Type.PROGRESS_TURN))


func _is_my_phase(phase: TurnManager.Phase) -> bool:
	return (is_active_actor()
		and _turn_manager.get_game_state() == TurnManager.GameState.MAIN_LOOP
		and _turn_manager.get_game_phase() == phase)


func _is_stronger(a: UnitInstance, b: UnitInstance) -> bool:
	return _average_damage(a.get_damage()) > _average_damage(b.get_damage())


func _average_damage(damage: DamageData) -> float:
	if damage == null:
		return 0.0
	return damage.get_dice_count() * (damage.get_dice_sides() + 1) / 2.0 + damage.get_modifier()
#endregion
