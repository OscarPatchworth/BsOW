#defend_units_panel.gd
extends Panel

# signals

# enums
enum AlignmentOptions {
	LEFT_TO_RIGHT,
	RIGHT_TO_LEFT,
	CENTER
}

enum CombatSide {
	DEFENDING,
	ATTACKING
}


# constants
const ATTACK_COLOUR = Color.MAROON
const DEFEND_COLOUR = Color.TURQUOISE

const PB_RATIO = int(2)
const PB_SPACE_RATIO = int(1)
const PB_MARGIN_PERC = float(0.02)

const LENGTH_ANCHOR: float = 1.168
const MARGIN_ANCHOR: float = 0.02

# static variables
var combat_manager: GameManager

# @export variables
@export var combat_pb: PackedScene
@export var fill_align: AlignmentOptions
@export var combat_side: CombatSide
@export var bar_colour: Color

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
	var max_units:int = combat_manager.get_max_defend_units() if combat_side == CombatSide.DEFENDING else combat_manager.get_max_attack_units()

	# Calc the height% of each ratio/cell/tile for the pb spacing
	var segment_height_perc = (1 - 2 * PB_MARGIN_PERC) / ( max_units * PB_RATIO + (max_units-1) * PB_SPACE_RATIO)


	for i in range(max_units):
		var new_pb = combat_pb.instantiate()
		
		# Correct for Fill mode:
		if(fill_align == AlignmentOptions.RIGHT_TO_LEFT):
			new_pb.set_fill_mode(ProgressBar.FillMode.FILL_END_TO_BEGIN)

		# Apply PB colour
		#new_pb.colour

		self.add_child(new_pb)

		new_pb.set_anchors_and_offsets_preset(LayoutPreset.PRESET_TOP_WIDE, LayoutPresetMode.PRESET_MODE_KEEP_SIZE, 0)
		var pb_top: float
		var pb_bottom: float

		if(i == 0):
			pb_top = PB_MARGIN_PERC
		else:
			pb_top = (i * (PB_RATIO + PB_SPACE_RATIO)) * segment_height_perc + PB_MARGIN_PERC
		
		new_pb.anchor_top = pb_top
		new_pb.anchor_bottom = pb_top + (PB_RATIO * segment_height_perc)
		if(fill_align == AlignmentOptions.LEFT_TO_RIGHT):
			new_pb.anchor_left = MARGIN_ANCHOR
			new_pb.anchor_right = LENGTH_ANCHOR
		else:
			new_pb.anchor_left = (1 - LENGTH_ANCHOR)
			new_pb.anchor_right = (1 - MARGIN_ANCHOR)
			
		# For testing Purposes
		# Pls delete	
		if(i == 2):
			new_pb.set_value(100)

## Get/Set (er)s

### Connected Signals
