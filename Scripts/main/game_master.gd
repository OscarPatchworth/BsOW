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

# @onready variables


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	###	Get Refrences
	ui_starting_display = self.get_node("../../UI/StarterBiomeDisplay")
	ui_next_biome_display = self.get_node("../../UI/NextBiomeDisplay")

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


func switch_state_place_terrian():
	game_state = GameState.PLACE_TERRIAN
	ui_next_biome_display.show()
	ui_starting_display.hide()

### Update() states
func update_state_start():
	pass


func update_state_place_terrian():
	pass

###################################################################################################
### Connected Signals

func _on_button_button_up() -> void:
	#switch_state_place_terrian()
	pass
