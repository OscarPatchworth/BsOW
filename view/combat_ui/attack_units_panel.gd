#attack_units_panel.gd
extends Panel

# signals

# enums

# constants
const ATTACK_COLOUR = Color.MAROON
const DEFEND_COLOUR = Color.TURQUOISE

const PB_RATIO = int(2)
const PB_SPACE_RATIO = int(1)
const PB_MARGIN_PERC = float(0.02)

# static variables
var combat_manager: GameManager

# @export variables
@export var combat_pb: PackedScene

# remaining regular variables

# @onready variables

###################################################################################################
###	Methods
func free_children(parent: Node) -> void:
	for i in parent.get_children():
		i.queue_free()


### Connected Signals


## Calls
func bind_combat_manager(cm: GameManager):
	combat_manager = cm
	#print("attak units Panel | comabt UI | Combat Manager Bound")


func update(combat_state: Contest):
	# Clear Panel
	free_children(self)

	# Call once and store. So if value changes during func() no out of bounds error. Just outdate display. 
	# @onChange this func() will be recalled anyway so outdated info won't be a problem
	var max_attack_units = combat_manager.get_max_attack_units()

	var segment_height_perc = (1 - 2 * PB_MARGIN_PERC) / ( max_attack_units * PB_RATIO + (max_attack_units-1) * PB_SPACE_RATIO)

	for i in range(max_attack_units):
		var new_pb = combat_pb.instantiate()
		self.add_child(new_pb)

		new_pb.set_anchors_and_offsets_preset(LayoutPreset.PRESET_TOP_WIDE, LayoutPresetMode.PRESET_MODE_KEEP_SIZE, 0)
		var pb_top: float
		var pb_bottom: float

		if(i == 0):
			pb_top = PB_MARGIN_PERC
		else:
			pb_top = (i * (PB_RATIO + PB_SPACE_RATIO)) * segment_height_perc + PB_MARGIN_PERC
		
		#new_pb.set_anchor_and_offset(SIDE_TOP, pb_top, 0.0, false)	
		new_pb.anchor_top = pb_top

		pb_bottom = pb_top + (PB_RATIO * segment_height_perc)
		#new_pb.set_anchor_and_offset(SIDE_BOTTOM, pb_bottom, 0.0, false)	
		new_pb.anchor_bottom = pb_bottom

## Get/Set (er)s

### Connected Signals
