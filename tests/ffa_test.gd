extends Node

## Free-for-all test: the default match (the player plus two AIs, each for themselves).
##   godot --headless --path . res://tests/ffa_test.tscn
## Checks setup with three actors, a few full rounds, knocking one AI out without ending the
## game, and the board markers (selection ring, battle arrows and alerts).
## Exit code 0 means every check passed. FFA_SEED=n picks another random seed.

const MAIN_SCENE: PackedScene = preload("res://main.tscn")
const ORIGIN := Vector3(-14, 0, -14)
const ROUNDS: int = 3

var _failures: Array[String] = []
var _check_count: int = 0
var _player: Player
var _ais: Array[SimpleAI] = []
var _turn_manager: TurnManager
var _lander_manager: LanderManager
var _gravity_system: GravitySystem
## Actor -> how many turns they started.
var _turn_enders := {}


func _ready() -> void:
	var seed_text := OS.get_environment("FFA_SEED")
	seed(int(seed_text) if seed_text != "" else 777)
	var root: GameRoot = MAIN_SCENE.instantiate()
	add_child(root)
	await _frames(2)
	_player = root.find_child("Player", true, false)
	_turn_manager = root.find_child("TurnManager", true, false)
	_lander_manager = root.find_child("LanderManager", true, false)
	_gravity_system = root.find_child("GravitySystem", true, false)
	for actor in _turn_manager.get_turn_order():
		if actor is SimpleAI:
			_ais.append(actor)
			(actor as SimpleAI).step_delay = 0.0
	_turn_manager.active_actor_changed.connect(_on_active_actor_changed)

	_check(_turn_manager.get_turn_order().size() == 3 and _ais.size() == 2, "the default match is you and two AIs")
	_check(_ais[0].get_color() != _ais[1].get_color() and _ais.all(func(ai: SimpleAI) -> bool: return ai.get_color() != _player.get_color()),
		"everyone has their own colour")
	await _set_up_player()
	_check(_ais.all(func(ai: SimpleAI) -> bool: return _lander_manager.get_setup_landers_of(ai).size() == 4),
		"each AI placed its own starting landers")
	_check(_ais.all(func(ai: SimpleAI) -> bool: return _has_command_tower(ai)), "each AI built a command tower")
	_check(_closest_between(_ais[0], _ais[1]) > 4.0, "the two AIs started apart (%.1f)" % _closest_between(_ais[0], _ais[1]))
	_check(_turn_manager.get_game_state() == TurnManager.GameState.MAIN_LOOP, "the game started once all three were set up")

	await _test_markers()
	await _play_rounds()
	await _test_knockout()

	print("\n==== FFA test: %d checks, %d failed ====" % [_check_count, _failures.size()])
	for failure in _failures:
		print("  FAIL: " + failure)
	get_tree().quit(1 if not _failures.is_empty() else 0)


func _set_up_player() -> void:
	var biomes: Array[BiomeData] = (_player.find_child("SetupPanel", true, false) as SetupPanel).get_remaining_biomes().duplicate()
	for i in biomes.size():
		var place := Action.create(Action.Type.PLACE_BIOME)
		place.set_position(ORIGIN + Vector3(i * 2.2, 0, 0))
		place.set_biome_data(biomes[i])
		_player.request_action(place)
	await _frames(2)
	var tower := Action.create(Action.Type.PLACE_BUILDING)
	tower.set_target_lander(_lander_manager.get_setup_landers_of(_player)[0])
	tower.set_building_data(_player.get_species().get_command_tower())
	_player.request_action(tower)
	await _wait_for_player_turn()


## The selection ring follows the lander panel; battles get arrows; attacks on us alert.
func _test_markers() -> void:
	var markers := _player.get_controller().get_markers()
	var home := _lander_manager.get_setup_landers_of(_player)[0]
	_player.get_ui().show_lander_panel(home)
	await _frames(2)
	_check(markers.get_selection() == home, "the selected lander is ringed")
	_player.get_ui().get_inspector().hide()
	await _frames(2)
	_check(markers.get_selection() == null, "closing the panel clears the ring")

	# A battle between the two AIs: an arrow until it ends (stand-in contest, nothing is rolled).
	var ai_lander_a := _lander_manager.get_landers_owned_by(_ais[0])[0]
	var ai_lander_b := _lander_manager.get_landers_owned_by(_ais[1])[0]
	var ai_battle := Contest.new(ai_lander_a, ai_lander_b)
	_player._on_any_combat_started(ai_battle)
	_check(markers.has_arrow(ai_battle), "a battle between AIs gets an arrow")
	_player._on_any_combat_ended(ai_battle)
	_check(not markers.has_arrow(ai_battle), "the arrow goes when the battle ends")

	# An AI attacking us: arrow, "UNDER ATTACK!" and an alert.
	home.add_units([UnitInstance.new(_player.get_species().get_units()[0], _player)] as Array[UnitInstance])
	var raider_lander := _lander_manager.spawn_protected_lander(ORIGIN + Vector3(0, 0, -6), _ais[0], 1)
	var raid := Contest.new(raider_lander, home)
	_player._on_any_combat_started(raid)
	var hint := _player.find_children("*", "PhaseHint", true, false)[0] as PhaseHint
	_check(markers.has_arrow(raid) and "attacking your" in hint._label.text, "an attack on you shows an arrow and an alert")
	_player._on_any_combat_ended(raid)
	raider_lander.remove_units(raider_lander.get_units().duplicate())
	home.remove_units(home.get_units().duplicate())


## A few rounds where the player just places a lander and ends the turn: every AI takes its
## turns and the game keeps going round all three.
func _play_rounds() -> void:
	var round_start := _turn_manager.get_round_number()
	# A garrison at home, so the AIs don't simply walk in and end the test early.
	var home := _lander_manager.get_setup_landers_of(_player)[0]
	var garrison: Array[UnitInstance] = []
	for i in home.get_unit_capacity():
		garrison.append(UnitInstance.new(_player.get_species().get_units()[0], _player))
	home.add_units(garrison)
	for round_index in ROUNDS:
		if _turn_manager.get_game_state() != TurnManager.GameState.MAIN_LOOP or _player not in _turn_manager.get_turn_order():
			break
		var place := Action.create(Action.Type.PLACE_LANDER)
		place.set_position(_clear_spot_near(_lander_manager.get_setup_landers_of(_player)[0]))
		_player.request_action(place)
		await _frames(1)
		_player.request_action(Action.create(Action.Type.PROGRESS_TURN))
		_player.request_action(Action.create(Action.Type.PROGRESS_TURN))
		await _wait_for_player_turn()
	_check(_turn_manager.get_round_number() >= round_start + ROUNDS or _turn_manager.get_game_state() == TurnManager.GameState.END,
		"%d rounds went by with three players (round %d)" % [ROUNDS, _turn_manager.get_round_number()])
	_check(_ais.all(func(ai: SimpleAI) -> bool: return _turn_enders.get(ai, 0) >= ROUNDS),
		"both AIs took their turns (turns started: %s)" % str(_turn_enders.values()))


## Knocking one AI out leaves a two-player game going.
func _test_knockout() -> void:
	if _turn_manager.get_game_state() != TurnManager.GameState.MAIN_LOOP:
		_check(true, "(game already over: knockout check skipped)")
		return
	var out := _ais[1] if _ais[1] in _turn_manager.get_turn_order() else _ais[0]
	_lander_manager.remove_assets_of(out)
	_turn_manager.eliminate_actor(out)
	_check(_turn_manager.get_turn_order().size() == 2 and _turn_manager.get_game_state() == TurnManager.GameState.MAIN_LOOP,
		"knocking one AI out leaves the other two playing")
	_check(_turn_manager.get_winner() == null, "nobody has won yet")


func _on_active_actor_changed(actor: Actor) -> void:
	_turn_enders[actor] = _turn_enders.get(actor, 0) + 1


#region Helpers
func _check(condition: bool, description: String) -> void:
	_check_count += 1
	print(("  ok   " if condition else "  FAIL ") + description)
	if not condition:
		_failures.append(description)


func _has_command_tower(actor: Actor) -> bool:
	return _lander_manager.get_landers().any(func(lander: Lander) -> bool:
		return lander.has_building() and lander.get_building().get_owner_actor() == actor and lander.get_building().is_command_tower())


func _closest_between(a: Actor, b: Actor) -> float:
	var closest := INF
	for first in _lander_manager.get_setup_landers_of(a):
		for second in _lander_manager.get_setup_landers_of(b):
			closest = minf(closest, first.get_board_position().distance_to(second.get_board_position()))
	return closest


func _clear_spot_near(lander: Lander) -> Vector3:
	for ring in range(1, 6):
		for i in 12:
			var angle := TAU * i / 12.0
			var spot := lander.get_board_position() + Vector3(cos(angle), 0, sin(angle)) * 2.3 * ring
			if _lander_manager.is_valid_lander_placement(spot):
				return spot
	return Vector3.ZERO


func _wait_for_player_turn() -> void:
	var deadline := Time.get_ticks_msec() + 60000
	while Time.get_ticks_msec() < deadline:
		var is_ours := _turn_manager.get_game_state() == TurnManager.GameState.MAIN_LOOP \
			and _turn_manager.get_active_actor() == _player \
			and _turn_manager.get_game_phase() == TurnManager.Phase.DUSTCLOUD_COLLAPSE
		if is_ours and _gravity_system.is_settled() and _ais.all(func(ai: SimpleAI) -> bool: return not ai.is_busy()):
			return
		if _turn_manager.get_game_state() == TurnManager.GameState.END or _player not in _turn_manager.get_turn_order():
			return
		await _frames(5)
	_check(false, "timed out waiting for the player's turn")


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame
#endregion
