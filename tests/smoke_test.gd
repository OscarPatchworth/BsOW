# smoke_test.gd
extends Node

## Headless smoke test: loads main.tscn and drives a game through the real Action pipeline
## (setup -> command tower -> phases -> buy -> move -> combat -> upkeep), checking state as it goes.
##
## Run from the project folder:
##   godot --headless --path . res://tests/smoke_test.tscn
## Exit code 0 = all checks passed, 1 = something failed (details are printed).

const MAIN_SCENE: PackedScene = preload("res://main.tscn")
## Far from the origin lander, so the player's setup landers don't collide with anything.
const SETUP_ORIGIN := Vector3(-30, 0, -30)
## Where the AI scenario is built (far from everything else).
const AI_TEST_ORIGIN := Vector3(30, 0, 30)
const LANDER_SPACING: float = 2.2  # Above MIN_DISTANCE (2.0), below connection range (2.5).

var _failures: Array[String] = []
var _check_count: int = 0

var _root: GameRoot
var _player: Player
var _ai: SimpleAI
var _turn_manager: TurnManager
var _lander_manager: LanderManager
var _combat_manager: CombatManager
var _action_manager: ActionManager
var _rejections: Array[String] = []
var _resolved_types: Array[Action.Type] = []
var _resolved_actions: Array[Action] = []
## Food in each actor's wallet just before / after their latest COLLECT_UPKEEP.
var _food_before_upkeep := {}
var _food_after_upkeep := {}
## Food upkeep each actor should get, worked out from what they own when upkeep starts.
var _expected_food_upkeep := {}
## A copy of each actor's wallet right after their latest upkeep.
var _wallet_after_upkeep := {}
var _gold_before_upkeep := {}
var _expected_gold_upkeep := {}
var _upkeep_gold: int = 0


func _ready() -> void:
	seed(12345)
	_root = MAIN_SCENE.instantiate()
	add_child(_root)
	await _frames(3)

	_player = _root.find_child("Player", true, false)
	_ai = _root.find_child("SimpleAI", true, false)
	_turn_manager = _root.find_child("TurnManager", true, false)
	_lander_manager = _root.find_child("LanderManager", true, false)
	_combat_manager = _root.find_child("CombatManager", true, false)
	_action_manager = _root.find_child("ActionManager", true, false)
	_upkeep_gold = _root.find_child("MatchSettings", true, false).get_upkeep_gold()
	_action_manager.action_rejected.connect(_on_action_rejected)
	_action_manager.action_resolved.connect(_on_action_resolved)
	_action_manager.action_resolving.connect(_on_action_resolving)
	_combat_manager.combat_started.connect(_on_combat_started_auto_defend)

	_check(_player != null and _ai != null, "player and AI exist")
	_check(_turn_manager.get_game_state() == TurnManager.GameState.SETUP, "game starts in SETUP")

	await _test_setup()
	await _test_main_loop()

	print("\n==== Smoke test: %d checks, %d failed ====" % [_check_count, _failures.size()])
	for failure in _failures:
		print("  FAIL: " + failure)
	get_tree().quit(1 if not _failures.is_empty() else 0)


#region Tests
func _test_setup() -> void:
	var setup_panel: SetupPanel = _player.find_child("SetupPanel", true, false)
	var biome_count := _root.find_child("MatchSettings", true, false).get_starting_biome_count() as int
	var remaining: Array[BiomeData] = setup_panel._remaining_biomes.duplicate()
	_check(remaining.size() == biome_count, "setup panel offers %d biomes" % biome_count)

	var landers_before := _lander_manager.get_landers().size()
	for i in remaining.size():
		var action := Action.create(Action.Type.PLACE_BIOME)
		action.set_position(SETUP_ORIGIN + Vector3(i * LANDER_SPACING, 0, 0))
		action.set_biome_data(remaining[i])
		_request(action)
	await _frames(2)
	_check(_lander_manager.get_landers().size() == landers_before + biome_count, "all setup biomes placed as landers")
	_check(setup_panel._remaining_biomes.is_empty(), "setup panel list emptied")
	var controller: PlayerController = _player.find_child("PlayerController", true, false)
	_check(controller._is_placing_command_tower, "controller switched to command tower placement")

	var home := _lander_at(SETUP_ORIGIN)
	var food_before_main_loop := {}
	for actor: Actor in [_player, _ai]:
		food_before_main_loop[actor] = actor.get_wallet().get_amount(&"food")
	var tower := Action.create(Action.Type.PLACE_BUILDING)
	tower.set_target_lander(home)
	tower.set_building_data(_player.get_species().get_command_tower())
	_request(tower)
	await _frames(3)

	_check(home.has_building(), "command tower built")
	_check(home.get_owner_actor() == _player, "home lander owned by player")
	_check(_turn_manager.get_game_state() == TurnManager.GameState.MAIN_LOOP, "setup finished -> MAIN_LOOP")
	_check(_turn_manager.get_game_phase() == TurnManager.Phase.DUSTCLOUD_COLLAPSE, "first phase is DUSTCLOUD_COLLAPSE")
	var first_actor := _turn_manager.get_active_actor()
	_check(first_actor.get_wallet().get_amount(&"food") == food_before_main_loop[first_actor] + _expected_upkeep(first_actor, &"food"),
		"first actor collected upkeep at the start of the main loop")

	# Only the game may request system actions.
	var food_now := _player.get_wallet().get_amount(&"food")
	_request(Action.create(Action.Type.COLLECT_UPKEEP))
	_check(_player.get_wallet().get_amount(&"food") == food_now and _last_rejection_contains("Only the game"),
		"actors can't request system actions")


func _test_main_loop() -> void:
	# If the AI went first it has already played its turn by itself.
	_check(_turn_manager.get_active_actor() == _player, "player is the active actor once setup is done")
	_check(_turn_manager.get_game_phase() == TurnManager.Phase.DUSTCLOUD_COLLAPSE, "player turn starts at DUSTCLOUD_COLLAPSE")

	# Rules: buying only happens in BUYING, and only the active actor may progress the turn.
	var home := _lander_at(SETUP_ORIGIN)
	var unit_data := _first_unit_purchasable(home)
	_check(unit_data != null, "home lander offers a unit to buy")
	var early_buy := Action.create(Action.Type.PURCHASE)
	early_buy.set_target_lander(home)
	early_buy.set_purchasable(unit_data)
	_request(early_buy)
	_check(home.get_units().is_empty(), "PURCHASE rejected outside the BUYING phase")
	var ai_progress := Action.create(Action.Type.PROGRESS_TURN)
	ai_progress.set_actor(_ai)
	_action_manager.request_action(ai_progress)
	_check(_turn_manager.get_game_phase() == TurnManager.Phase.DUSTCLOUD_COLLAPSE, "PROGRESS_TURN rejected when it isn't the actor's turn")

	# Dustcloud collapse can't be skipped; placing a lander ends it.
	_request(Action.create(Action.Type.PROGRESS_TURN))
	_check(_turn_manager.get_game_phase() == TurnManager.Phase.DUSTCLOUD_COLLAPSE and _last_rejection_contains("can't be skipped"),
		"DUSTCLOUD_COLLAPSE can't be skipped with PROGRESS_TURN")
	var landers_before := _lander_manager.get_landers().size()
	var place := Action.create(Action.Type.PLACE_LANDER)
	place.set_position(SETUP_ORIGIN + Vector3(0, 0, 10))
	_request(place)
	await _frames(1)
	_check(_lander_manager.get_landers().size() == landers_before + 1, "PLACE_LANDER spawned a lander")
	_check(_turn_manager.get_game_phase() == TurnManager.Phase.BUYING, "PLACE_LANDER progressed to BUYING")

	# Rules: no attacking outside COMBAT.
	var early_attack := Action.create(Action.Type.ATTACK)
	early_attack.set_source_lander(home)
	early_attack.set_target_lander(_lander_at(SETUP_ORIGIN + Vector3(LANDER_SPACING, 0, 0)))
	_request(early_attack)
	_check(_combat_manager.get_contest() == null, "ATTACK rejected outside the COMBAT phase")

	# The lander panel's shop buttons now send a PURCHASE (they used to buy for free).
	var shop_button := UnitShopButton.new()
	shop_button.set_unit_data(unit_data)
	var shop_actions: Array[Action] = []
	shop_button.action_requested.connect(func(action: Action) -> void: shop_actions.append(action))
	shop_button._pressed()
	shop_button.free()
	_check(shop_actions.size() == 1 and shop_actions[0].get_type() == Action.Type.PURCHASE
		and shop_actions[0].get_purchasable() == unit_data, "unit shop button requests a PURCHASE")

	# Buying: purchase a unit on the home lander.
	var gold_before := _player.get_wallet().get_amount(&"gold")
	var buy := Action.create(Action.Type.PURCHASE)
	buy.set_target_lander(home)
	buy.set_purchasable(unit_data)
	_request(buy)
	buy = Action.create(Action.Type.PURCHASE)
	buy.set_target_lander(home)
	buy.set_purchasable(unit_data)
	_request(buy)
	await _frames(1)
	_check(home.get_units().size() == 2, "two units bought onto home lander")
	_check(_player.get_wallet().get_amount(&"gold") == gold_before - 2 * unit_data.get_cost().get_amount(&"gold"),
		"wallet charged for both units")

	# Lander panel UI paths.
	_player.get_selector_manager().select_lander(home)
	_player._ui.show_lander_panel(home)
	await _frames(1)

	_request(Action.create(Action.Type.PROGRESS_TURN))
	await _frames(1)
	_check(_turn_manager.get_game_phase() == TurnManager.Phase.COMBAT, "progressed to COMBAT")

	# Move one unit to the neighbouring (empty) setup lander.
	var neighbour := _lander_at(SETUP_ORIGIN + Vector3(LANDER_SPACING, 0, 0))
	_check(neighbour in _lander_manager.get_connected_landers(home), "neighbour lander is connected")
	var move := Action.create(Action.Type.MOVE_UNITS)
	move.set_source_lander(home)
	move.set_target_lander(neighbour)
	move.set_units([home.get_units()[0]] as Array[UnitInstance])
	_request(move)
	await _frames(1)
	_check(home.get_units().size() == 1 and neighbour.get_units().size() == 1, "MOVE_UNITS moved one unit")

	await _test_combat(home)

	var scenario := await _build_ai_scenario()

	# Finish the turn. The AI then plays its whole turn by itself (the test auto-defends for the player):
	# CLEANUP -> AI UPKEEP -> AI turn -> CLEANUP -> player UPKEEP -> DUSTCLOUD_COLLAPSE.
	var season_before := _turn_manager.get_season_index()
	var round_before := _turn_manager.get_round_number()

	var actor_changes: Array[Actor] = []
	var phase_seen_on_actor_change: Array[TurnManager.Phase] = []
	var record_actor_change := func(actor: Actor) -> void:
		actor_changes.append(actor)
		phase_seen_on_actor_change.append(_turn_manager.get_game_phase())
	_turn_manager.active_actor_changed.connect(record_actor_change)
	_resolved_actions.clear()
	_request(Action.create(Action.Type.PROGRESS_TURN))
	await _frames(1)
	_turn_manager.active_actor_changed.disconnect(record_actor_change)

	_check(actor_changes == ([_ai, _player] as Array[Actor]), "turn went to the AI and back to the player")
	_check(phase_seen_on_actor_change == ([TurnManager.Phase.UPKEEP, TurnManager.Phase.UPKEEP] as Array[TurnManager.Phase]),
		"active_actor_changed fires once the phase is already the new turn's UPKEEP")
	_check(_turn_manager.get_game_phase() == TurnManager.Phase.DUSTCLOUD_COLLAPSE, "player's next turn starts at DUSTCLOUD_COLLAPSE")
	_check(_turn_manager.get_round_number() == round_before + 1, "round number incremented once")
	_check(_turn_manager.get_season_index() == (season_before + 1) % 4, "season advanced")
	_check(_food_after_upkeep[_ai] == _food_before_upkeep[_ai] + _expected_food_upkeep[_ai], "AI collected upkeep for its landers")
	_check(_food_after_upkeep[_player] == _food_before_upkeep[_player] + _expected_food_upkeep[_player], "player collected upkeep for owned landers")
	for actor: Actor in [_ai, _player]:
		_check(_wallet_after_upkeep[actor].get_amount(&"gold") == _gold_before_upkeep[actor] + _expected_gold_upkeep[actor],
			"%s gained %d upkeep gold (plus any lander gold)" % [actor.name, _upkeep_gold])
	_check_ai_turn(scenario)


## A spot where the AI should act: a 3-unit AI garrison, an empty neutral lander next to it,
## and a player lander with a single unit next to it.
func _build_ai_scenario() -> Dictionary:
	_lander_manager.spawn_protected_lander(AI_TEST_ORIGIN, _ai, 3)
	var ai_base := _lander_manager.get_landers()[-1]
	var neutral := _lander_manager.spawn_random_lander(AI_TEST_ORIGIN + Vector3(LANDER_SPACING, 0, 0))
	var bait := _lander_manager.spawn_random_lander(AI_TEST_ORIGIN + Vector3(0, 0, LANDER_SPACING))
	bait.add_units([UnitInstance.new(_player.get_species().get_units()[0], _player)] as Array[UnitInstance])
	await _frames(2)
	return {"ai_base": ai_base, "neutral": neutral, "bait": bait}


func _check_ai_turn(scenario: Dictionary) -> void:
	var placed := _ai_actions(Action.Type.PLACE_LANDER)
	var purchases := _ai_actions(Action.Type.PURCHASE)
	var attacks := _ai_actions(Action.Type.ATTACK)
	var moves := _ai_actions(Action.Type.MOVE_UNITS)
	var progresses := _ai_actions(Action.Type.PROGRESS_TURN)

	_check(placed.size() == 1, "AI placed one lander in DUSTCLOUD_COLLAPSE")
	_check(progresses.size() == 2, "AI ended BUYING and COMBAT itself (DUSTCLOUD ended by placing)")
	var bought_building := purchases.any(func(action: Action) -> bool: return action.get_purchasable() is BuildingData)
	var tower_cost: EconData = null
	for purchasable in scenario["ai_base"].get_purchasables(_ai):
		if purchasable is BuildingData and purchasable.can_spawn_units():
			tower_cost = purchasable.get_cost()
	if tower_cost != null and _wallet_after_upkeep[_ai].can_afford(tower_cost):
		_check(bought_building, "AI bought a spawning building for a garrison")
	else:
		# It went first and already spent its resources on buildings last turn.
		_check(not bought_building, "AI didn't try to buy a building it can't afford")
	_check(attacks.any(func(action: Action) -> bool: return action.get_target_lander() == scenario["bait"]),
		"AI attacked the weaker player lander next to it")
	_check(attacks.size() <= SimpleAI.MAX_ATTACKS_PER_TURN, "AI stayed within its attack limit")
	# It claims an empty neighbour: the one in the scenario, the bait if its attack emptied it,
	# or the lander it placed this turn (it aims those at the nearest enemy, i.e. the bait).
	var claims := moves.filter(func(action: Action) -> bool: return action.get_source_lander() == scenario["ai_base"])
	_check(not claims.is_empty(), "AI moved units from its base onto a neighbouring lander")
	_check(claims.all(func(action: Action) -> bool: return action.get_target_lander().get_owner_actor() == _ai),
		"AI now owns the lander it claimed")
	_check(scenario["ai_base"].has_units(), "AI kept units behind on its base")


func _test_combat(home: Lander) -> void:
	# An AI garrison right next to the home lander.
	var enemy_position := Vector3(home.position.x, 0, home.position.z - LANDER_SPACING)
	_lander_manager.spawn_protected_lander(enemy_position, _ai, 2)
	await _frames(1)
	var enemy := _lander_manager.get_landers()[-1]
	_check(enemy.get_owner_actor() == _ai and enemy.get_units().size() == 2, "AI garrison spawned")

	var resolved: Array = []
	_combat_manager.combat_resolved.connect(func(outcomes: Array[CombatOutcome]) -> void: resolved.append(outcomes))

	var attack := Action.create(Action.Type.ATTACK)
	attack.set_source_lander(home)
	attack.set_target_lander(enemy)
	_request(attack)
	await _frames(1)
	var contest := _combat_manager.get_contest()
	_check(contest != null and contest.get_side_of(_player) == Contest.Side.ATTACKER, "contest started with player attacking")
	_check(contest.is_ready(Contest.Side.DEFENDER), "AI defender picked units and readied")
	_check(contest.get_units(Contest.Side.DEFENDER).size() == 2, "AI chose its defenders")

	var attacker_unit := home.get_units()[0]
	_request(_combat_unit_action(Action.Type.SELECT_COMBAT_UNIT, enemy.get_units()[0]))
	_check(contest.get_units(Contest.Side.ATTACKER).is_empty(), "player can't select an enemy unit")
	_request(_combat_unit_action(Action.Type.SELECT_COMBAT_UNIT, attacker_unit))
	_check(contest.get_units(Contest.Side.ATTACKER) == [attacker_unit], "player selected an attacker")
	_request(_combat_unit_action(Action.Type.DESELECT_COMBAT_UNIT, attacker_unit))
	_check(contest.get_units(Contest.Side.ATTACKER).is_empty(), "player deselected the attacker")
	_request(Action.create(Action.Type.PROGRESS_TURN))
	_check(_turn_manager.get_game_phase() == TurnManager.Phase.COMBAT, "can't end the phase in the middle of a combat")
	_request(_combat_unit_action(Action.Type.SELECT_COMBAT_UNIT, attacker_unit))
	_resolved_types.clear()
	_request(Action.create(Action.Type.DECLARE_COMBAT_READY))
	await _frames(1)
	_check(_resolved_types == ([Action.Type.DECLARE_COMBAT_READY, Action.Type.RESOLVE_COMBAT] as Array[Action.Type]),
		"both sides ready -> RESOLVE_COMBAT queued as a follow-up action")

	_check(resolved.size() == 1, "combat resolved once")
	if resolved.size() == 1:
		var outcomes: Array = resolved[0]
		_check(outcomes.size() == 3, "one outcome per fighting unit")
		for outcome: CombatOutcome in outcomes:
			_check(outcome.get_rolls().size() == outcome.get_unit().get_damage().get_dice_count(), "rolls kept intact")
			if outcome.get_outcome() == CombatOutcome.Outcome.DEAD:
				var lander := home if outcome.get_unit().get_owner_actor() == _player else enemy
				_check(outcome.get_unit() not in lander.get_units(), "dead unit removed from its lander")
	_check(_combat_manager.get_phase() == CombatManager.CombatPhase.CLEANUP, "combat ended in CLEANUP")
#endregion


#region Helpers
func _request(action: Action) -> void:
	_player._on_child_action_requested(action)


func _combat_unit_action(type: Action.Type, unit: UnitInstance) -> Action:
	var action := Action.create(type)
	action.set_units([unit] as Array[UnitInstance])
	return action


func _expected_upkeep(actor: Actor, key: StringName) -> int:
	var total := 0
	for lander in _lander_manager.get_landers_owned_by(actor):
		total += lander.get_upkeep().get_amount(key)
	return total


func _last_rejection_contains(text: String) -> bool:
	return not _rejections.is_empty() and text in _rejections[-1]


func _on_action_rejected(_action: Action, reason: String) -> void:
	_rejections.append(reason)


func _on_action_resolved(action: Action) -> void:
	_resolved_types.append(action.get_type())
	_resolved_actions.append(action)
	if action.get_type() == Action.Type.COLLECT_UPKEEP:
		_food_after_upkeep[action.get_actor()] = action.get_actor().get_wallet().get_amount(&"food")
		var wallet_copy := EconData.new()
		wallet_copy.add(action.get_actor().get_wallet())
		_wallet_after_upkeep[action.get_actor()] = wallet_copy


func _on_action_resolving(action: Action) -> void:
	if action.get_type() == Action.Type.COLLECT_UPKEEP:
		_food_before_upkeep[action.get_actor()] = action.get_actor().get_wallet().get_amount(&"food")
		_expected_food_upkeep[action.get_actor()] = _expected_upkeep(action.get_actor(), &"food")
		_gold_before_upkeep[action.get_actor()] = action.get_actor().get_wallet().get_amount(&"gold")
		_expected_gold_upkeep[action.get_actor()] = _upkeep_gold + _expected_upkeep(action.get_actor(), &"gold")


## Stands in for the human when the AI attacks: picks the first unit and declares ready.
func _on_combat_started_auto_defend(contest: Contest) -> void:
	if contest.get_side_of(_player) != Contest.Side.DEFENDER:
		return
	_request(_combat_unit_action(Action.Type.SELECT_COMBAT_UNIT, contest.get_lander(Contest.Side.DEFENDER).get_units()[0]))
	_request(Action.create(Action.Type.DECLARE_COMBAT_READY))


func _ai_actions(type: Action.Type) -> Array[Action]:
	var found: Array[Action] = []
	for action in _resolved_actions:
		if action.get_type() == type and action.get_actor() == _ai and not action.is_system():
			found.append(action)
	return found


func _first_unit_purchasable(lander: Lander) -> UnitData:
	for purchasable in lander.get_purchasables(_player):
		if purchasable is UnitData:
			return purchasable
	return null


func _lander_at(position: Vector3) -> Lander:
	var best: Lander = null
	for lander in _lander_manager.get_landers():
		var flat := Vector2(lander.position.x - position.x, lander.position.z - position.z)
		if flat.length() < 0.5:
			best = lander
	return best


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame


func _check(condition: bool, description: String) -> void:
	_check_count += 1
	if condition:
		print("  ok   " + description)
	else:
		print("  FAIL " + description)
		_failures.append(description)
#endregion
