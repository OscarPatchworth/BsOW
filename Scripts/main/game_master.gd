extends Node

# signals
# enums
enum GameState {START, PLACE_TERRIAN}

# constants
# static variables
# @export variables
# remaining regular variables
var game_state: GameState
var ui_starting_display
var ui_next_biome_display
var data_store_terrian
var player_node

# @onready variables
@onready var data_node_ref = get_node("%DataNodeRefs")
@export var biome_hex: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	###	Get Refrences
	ui_starting_display = get_node("/" + data_node_ref.UI_BIOMES_START)
	ui_next_biome_display = get_node("/" + data_node_ref.UI_BIOME_DISPLAY)
	data_store_terrian = get_node("/" + data_node_ref.DATA_TERRIAN)
	player_node = get_node("/" + data_node_ref.PLAYER + "/UserControler")

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
	newHex.updateBiome(data_store_terrian.next_biome)


###################################################################################################
### Connected Signals

func _on_button_button_up() -> void:
	#switch_state_place_terrian()
	pass


func _on_user_controler_biome_placed(ply_state: int, spawn_spot: Dictionary) -> void:
	instance_terrian(spawn_spot)
	if(ply_state == player_node.PlayerStateMachine.PLACE_STARTING_TERRIAN):
		var terrian_btns = ui_starting_display.get_child(0).get_children()
		for terrian_btn in terrian_btns:
			if terrian_btn.is_pressed():
				terrian_btn.delete_self()
		if(terrian_btns.size() <= 1):
				switch_state_place_terrian()

	
	pass # Replace with function body.
