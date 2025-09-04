extends Node

# signals
signal players_generate_biome_resources
signal player_change_state(state: int)
signal update_active_player(player: Node)

# enums
enum GameState {START, PLACE_TERRIAN}

# constants
# static variables
var data_store_terrian
var data_settings

# @export variables
@export var biome_hex: PackedScene
@export var player_node: PackedScene

# remaining regular variables
var game_state: GameState
var ui_starting_display
var ui_next_biome_display
var active_player


# @onready variables
@onready var data_node_ref = get_node("%DataNodeRefs")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	###	Get Refrences
	ui_starting_display = get_node("/" + data_node_ref.UI_BIOMES_START)
	ui_next_biome_display = get_node("/" + data_node_ref.UI_BIOME_DISPLAY)
	data_store_terrian = get_node("/" + data_node_ref.DATA_TERRIAN)
	data_settings = get_node("/" + data_node_ref.DATA_SETTINGS)
	
	###	Init Players
	var players_node = get_node("/" + data_node_ref.PLAYERS)
	for i in range(data_settings.player_count):
		var new_player = player_node.instantiate()
		players_node.add_child(new_player)
	set_active_player(get_tree().get_first_node_in_group("players"))

	### Init State Machine
	switch_state_start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	match game_state:
		GameState.START:
			update_state_start()
		GameState.PLACE_TERRIAN:
			update_state_place_terrian()

###################################################################################################
###	State Machine Funcs

### Switching to states
func switch_state_start():
	game_state = GameState.START
	ui_next_biome_display.hide()

	data_store_terrian.next_biome = 0
	data_store_terrian.queued_biome = 0


func switch_state_place_terrian():
	game_state = GameState.PLACE_TERRIAN
	ui_next_biome_display.show()
	ui_starting_display.hide()

	data_store_terrian.rand_queded_biomes()

	player_change_state.emit((game_state + 1))


### Update() states
func update_state_start():
	pass


func update_state_place_terrian():
	pass


###################################################################################################
### Custome Func()
func instance_terrian(spawn_spot: Dictionary) -> void:
	var newHex = biome_hex.instantiate()
	var terrian_folder = get_node("/" + data_node_ref.terrian_node_folder)
	terrian_folder.add_child(newHex)
	var newPos = spawn_spot["position"]
	newPos.y =+ 0.1
	newHex.position = newPos
	newHex.set_biome(data_store_terrian.get_biome_res(data_store_terrian.next_biome))

func set_active_player(player: Node) -> void:
	active_player = player
	update_active_player.emit(player)
	print(active_player.name)


func ply_attempt_build(build_res:BuildingRes, callback) -> void:
	# Check Player can pay for building
	var can_pay = true
	var build_cost = build_res.cost.get_resource_dict()
	var ply_res = active_player.player_resources.get_resource_dict()

	for i in build_res.cost.get_resource_dict():
		if(ply_res[i] < build_cost[i]):
			can_pay = false
	if(can_pay): 
		for i in build_res.cost.get_resource_dict():
			ply_res[i] -= build_cost[i]
			active_player.player_resources.set_resource_value(i, ply_res[i])
	else: print("\n Not enough resources \n ")
	callback.call(can_pay)
	#print("Building In Progress ...")


func ply_attempt_buy_unit(unit_res: UnitRes, callback) -> void:
	# Check Player can pay for unit
	var can_pay = true
	var unit_cost = unit_res.cost.get_resource_dict()
	var ply_res = active_player.player_resources.get_resource_dict()

	for i in unit_res.cost.get_resource_dict():
		if(ply_res[i] < unit_cost[i]):
			can_pay = false
	if(can_pay): 
		for i in unit_res.cost.get_resource_dict():
			ply_res[i] -= unit_cost[i]
			active_player.player_resources.set_resource_value(i, ply_res[i])
	else: print("\n Not enough resources \n ")
	callback.call(can_pay)
	#print("Training Units In Progress ...")
	pass

func update_terrian_pannel_info(terrain) -> void:
	var target = active_player.find_child("UserControler", true, false)
	print(target)
	target.generate_and_emit_terrian_banner_info(terrain)


func get_active_player() -> player:
	return active_player

###################################################################################################
### Connected Signals

func _on_button_button_up() -> void:
	#switch_state_place_terrian()
	pass


func _on_user_controler_biome_placed(ply_state: int, spawn_spot: Dictionary) -> void:
	instance_terrian(spawn_spot)
	if(ply_state == 1):
		var terrian_btns = ui_starting_display.get_child(0).get_children()
		for terrian_btn in terrian_btns:
			if terrian_btn.is_pressed():
				terrian_btn.delete_self()
		if(terrian_btns.size() <= 1):
				switch_state_place_terrian()
	elif(ply_state == 2):
		players_generate_biome_resources.emit()
		

	
	pass # Replace with function body.
