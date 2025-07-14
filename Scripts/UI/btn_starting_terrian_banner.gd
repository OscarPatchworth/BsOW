extends Panel

# signals

# enums

# constants

# static variables

# @export variables
@export var starting_terrian_btn: PackedScene

# remaining regular variables
var starting_terrian_selected: bool

# @onready variables
@onready var data_node_ref = get_node("%DataNodeRefs")
@onready var data_settings =  get_node("/" + data_node_ref.DATA_SETTINGS)


###################################################################################################
###	Methods

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
	var banner_size = Vector2(self.size.x,self.size.y)

	var btn_amount = data_settings.starting_terrian_amount+1
	var btn_spacing: float = 1 / ((2.0 * btn_amount) + 1)

	for i in range(1, btn_amount):
		var btn = starting_terrian_btn.instantiate()
		self.add_child(btn)
		btn.position.y = banner_size.y/3
		
		btn.position.x = 2 * i * btn_spacing * banner_size.x



	var button_children = self.get_children()
	for btn in button_children:
		btn.set_script(load(data_node_ref.class_btn_terrian_select))

### Connected Signals
