extends Panel

# signals

# enums

# constants

# static variables

# @export variables

# remaining regular variables
var starting_terrian_selected: bool

# @onready variables
@onready var data_node_ref = get_node("%DataNodeRefs")


###################################################################################################
###	Methods

###	_built_in_methods()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	starting_terrian_selected = false
	check_starting_terrian_selected()
	init_starting_terrian_btns()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
### Custom Methods
func check_starting_terrian_selected() -> void:
	var button_children = self.get_children()
	print(button_children)


func init_starting_terrian_btns() -> void:
	var button_children = self.get_children()
	for btn in button_children:
		btn.set_script(load(data_node_ref.class_btn_terrian_select))
		pass

### Connected Signals
