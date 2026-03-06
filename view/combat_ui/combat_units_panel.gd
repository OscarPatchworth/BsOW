#combat_units_panel.gd.gd
extends Panel

# signals
signal unit_deslected(unit: UnitObject)

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

enum CombatState {
	SELECTING,
	READY
}


# constants
const ATTACK_COLOUR = Color.MAROON
const DEFEND_COLOUR = Color.TURQUOISE

const DISPLAY_RATIO = int(2)
const DISPLAY_SPACE_RATIO = int(1)
const DISPLAY_MARGIN_PERC = float(0.02)

const LENGTH_ANCHOR: float = 1.168
const MARGIN_ANCHOR: float = 0.02

# static variables
var combat_manager: GameManager

# @export variables
@export var unit_display_control: PackedScene
@export var fill_align: AlignmentOptions
@export var bar_colour: Color

# remaining regular variables
var combat_state: CombatState = CombatState.SELECTING
var combat_side: CombatSide

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
	generate_unit_pbs(combat_state)


func generate_unit_pbs(combat_state: Contest):
	# Call once and store. So if value changes during func() no out of bounds error. Just outdate display. 
	# @onChange this func() will be recalled anyway so outdated info won't be a problem
	var max_units:int = combat_manager.get_max_defend_units() if combat_side == CombatSide.DEFENDING else combat_manager.get_max_attack_units()
	var selected_units: Array[UnitObject] = combat_state.get_defending_units() if combat_side == CombatSide.DEFENDING else combat_state.get_invading_units()

	# Calc the height% of each ratio/cell/tile for the pb spacing
	var segment_height_perc = (1 - 2 * DISPLAY_MARGIN_PERC) / ( max_units * DISPLAY_RATIO + (max_units-1) * DISPLAY_SPACE_RATIO)

	for i in range(max_units):
		var new_display = unit_display_control.instantiate()
		
		# Correct for Fill mode:
		if(fill_align == AlignmentOptions.RIGHT_TO_LEFT):
			new_display.set_fill_dir(new_display.FillDir.FILL_RIGHT_TO_LEFT)

		new_display.unit_deslected.connect(self.fwd_unit_deslected)

		self.add_child(new_display)
		anchor_unit_display(new_display, i, segment_height_perc)

		new_display.set_colour(bar_colour)

		var display_state: CombatState
	
		if(combat_side == CombatSide.DEFENDING):
			if combat_state.get_defending_ready():
				display_state = new_display.CombatState.READY 
			else: display_state = new_display.CombatState.SELECTING 		
		else:	
			if combat_state.get_invading_ready():
				display_state = new_display.CombatState.READY 
			else: display_state = new_display.CombatState.SELECTING 		
				
	
		new_display.set_combat_state(display_state)

		if selected_units.size() >= i+1:
			new_display.set_unit(selected_units[i])
		else:
			new_display.set_unit(null)		
		#


func anchor_unit_display(unit_display: Control, i: int, segment_perc: float):
		#unit_display.set_anchors_and_offsets_preset(LayoutPreset.PRESET_TOP_WIDE, LayoutPresetMode.PRESET_MODE_KEEP_SIZE, 0)
		var top_perc: float

		if(i == 0):
			top_perc = DISPLAY_MARGIN_PERC
		else:
			top_perc = (i * (DISPLAY_RATIO + DISPLAY_SPACE_RATIO)) * segment_perc + DISPLAY_MARGIN_PERC
		
		unit_display.anchor_top = top_perc
		unit_display.anchor_bottom = top_perc + (DISPLAY_RATIO * segment_perc)
		if(fill_align == AlignmentOptions.LEFT_TO_RIGHT):
			unit_display.anchor_left = MARGIN_ANCHOR
			unit_display.anchor_right = LENGTH_ANCHOR
		else:
			unit_display.anchor_left = (1 - LENGTH_ANCHOR)
			unit_display.anchor_right = (1 - MARGIN_ANCHOR)


func fwd_unit_deslected(unit: UnitObject):
	unit_deslected.emit(unit)

## Get/Set (er)s
func get_combat_side() -> CombatSide:
	return combat_side
func set_combat_side(side: CombatSide):
	combat_side = side


### Connected Signals
