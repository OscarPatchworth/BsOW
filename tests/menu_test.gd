extends Node

## Menu flow test: start screen -> Play -> pick Ettercap and 3 AIs -> Start match -> the game
## starts with those choices; Back returns to the start screen.
##   godot --headless --path . res://tests/menu_test.tscn
## This node steps out of the way of the scene changes (it hands "current scene" to a
## placeholder), so it survives them and can check each screen.

const START_SCENE := "res://scenes/menus/start_screen.tscn"
const ETTERCAP: SpeciesData = preload("res://data/species/ettercap.tres")

var _failures: Array[String] = []
var _check_count: int = 0


func _ready() -> void:
	await get_tree().process_frame
	var placeholder := Node.new()
	get_tree().root.add_child(placeholder)
	get_tree().current_scene = placeholder
	get_tree().change_scene_to_file(START_SCENE)

	var start := await _wait_for_scene("StartScreen") as StartScreen
	_check(start != null, "the start screen loads")
	if start == null:
		return _finish()
	_check(start.find_child("PlayButton", true, false) != null and start.find_child("QuitButton", true, false) != null,
		"it has Play and Quit")

	_press(start, "PlayButton")
	var setup := await _wait_for_scene("MatchSetupScreen") as MatchSetupScreen
	_check(setup != null, "Play opens the match setup screen")
	if setup == null:
		return _finish()
	_check(setup.find_child("Race_Lycanthrope", true, false) != null and setup.find_child("Race_Ettercap", true, false) != null
		and setup.find_child("Race_Random", true, false) != null, "it offers both races and Random")
	_check(setup.get_opponent_count() == 2, "two AIs are picked by default")

	_press(setup, "BackButton")
	start = await _wait_for_scene("StartScreen") as StartScreen
	_check(start != null, "Back returns to the start screen")
	_press(start, "PlayButton")
	setup = await _wait_for_scene("MatchSetupScreen") as MatchSetupScreen

	_press(setup, "Race_Ettercap")
	_press(setup, "Opponents3")
	_check(setup.get_chosen_species() == ETTERCAP and setup.get_opponent_count() == 3, "picking a race and 3 AIs")
	_press(setup, "StartButton")
	var game := await _wait_for_scene("Main") as GameRoot
	_check(game != null, "Start match loads the game")
	if game == null:
		return _finish()
	await get_tree().process_frame
	var turn_manager: TurnManager = game.find_child("TurnManager", true, false)
	var player: Player = game.find_child("Player", true, false)
	_check(player.get_species() == ETTERCAP, "you play the race you picked")
	_check(turn_manager.get_turn_order().size() == 4, "with the number of AIs you picked (%d actors)" % turn_manager.get_turn_order().size())
	_check(player.find_child("MainMenuButton", true, false) != null, "the game over panel has a Main menu button")
	MatchRequest.clear()
	_finish()


func _press(screen: Node, button_name: String) -> void:
	var button := screen.find_child(button_name, true, false) as BaseButton
	_check(button != null, "%s exists" % button_name)
	if button == null:
		return
	if button.toggle_mode:
		button.button_pressed = true
	button.pressed.emit()


## Waits (a few seconds at most) for the current scene to be the one named `scene_name`.
func _wait_for_scene(scene_name: String) -> Node:
	for i in 300:
		await get_tree().process_frame
		var scene := get_tree().current_scene
		if scene != null and scene.name == scene_name and scene.is_node_ready():
			return scene
	return null


func _check(condition: bool, description: String) -> void:
	_check_count += 1
	print(("  ok   " if condition else "  FAIL ") + description)
	if not condition:
		_failures.append(description)


func _finish() -> void:
	print("\n==== Menu test: %d checks, %d failed ====" % [_check_count, _failures.size()])
	for failure in _failures:
		print("  FAIL: " + failure)
	get_tree().quit(1 if not _failures.is_empty() else 0)
