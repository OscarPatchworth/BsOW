extends Panel

# signals

# enums

# constants

# static variables
var biome_label: Label

var data_terrian

# @export variables

# remaining regular variables

# @onready variables
@onready var data_node_ref = get_node("%DataNodeRefs")

###################################################################################################
###	Methods

###	_built_in_methods()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Ready Labels
	biome_label = find_child("Biome")

	# Ready refrences
	data_terrian = get_node("/" + data_node_ref.DATA_TERRIAN)

	# Ready Other
	become_invisable()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


### Custom Methods
func update_display_info(terrian_info: Dictionary) -> void:
	#print("Update Terrian Panel info signal recived from Player_Cntrl  ||  " + str(terrian_info["Biome"]))
	
	# Update Info
	biome_label.text = str(
		data_terrian.get_enum_key(data_terrian.BiomeType, terrian_info["Biome"])
		)
	

func become_invisable() ->void:
	self.hide()


func become_visable() -> void:
	self.show()

### Connected Signals
