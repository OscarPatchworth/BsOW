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
var cur_combat: Contest
# @onready variables
@onready var view_port := get_viewport().get_visible_rect().size
@onready var container_size:Vector2 = self.size

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
	cur_combat = combat_state
	# Clear Panel
	free_children(self)
	generate_unit_pbs(combat_state)


func generate_unit_pbs(combat_state: Contest):
	# Call once and store. So if value changes during func() no out of bounds error. Just outdate display. 
	var max_units:int = combat_manager.get_max_defend_units() if combat_side == CombatSide.DEFENDING else combat_manager.get_max_attack_units()
	# @onChange this func() will be recalled anyway so outdated info won't be a problem
	var selected_units: Array[UnitObject] = combat_state.get_defending_units() if combat_side == CombatSide.DEFENDING else combat_state.get_invading_units()

	for i in range(max_units):
		var new_display = unit_display_control.instantiate()
		
		# Correct for Fill mode:
		if(fill_align == AlignmentOptions.RIGHT_TO_LEFT):
			new_display.set_fill_dir(new_display.FillDir.FILL_RIGHT_TO_LEFT)

		new_display.unit_deslected.connect(self.fwd_unit_deslected)

		self.add_child(new_display)
		anchor_unit_display(new_display, i)

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


func anchor_unit_display(unit_display: Control, i: int):
	# init anchor targets
	var target_top: float
	var target_bttm: float
	var target_left: float
	var target_right: float

	# Calc the height% of each ratio/cell/tile for the pb spacing
	var max_units:int = combat_manager.get_max_defend_units() if combat_side == CombatSide.DEFENDING else combat_manager.get_max_attack_units()
	var segment_perc = (1 - 2 * DISPLAY_MARGIN_PERC) / ( max_units * DISPLAY_RATIO + (max_units-1) * DISPLAY_SPACE_RATIO)

	if(i == 0):
		target_top = DISPLAY_MARGIN_PERC
	else:
		target_top = (i * (DISPLAY_RATIO + DISPLAY_SPACE_RATIO)) * segment_perc + DISPLAY_MARGIN_PERC
	
	target_bttm = target_top + (DISPLAY_RATIO * segment_perc)
	if(fill_align == AlignmentOptions.LEFT_TO_RIGHT):
		target_left = MARGIN_ANCHOR
		target_right = LENGTH_ANCHOR
	else:
		target_left = (1 - LENGTH_ANCHOR)
		target_right = (1 - MARGIN_ANCHOR)

	# Apply anchors
	#print("Container: " + str(container_size) + " | " +"left: " + str(target_left) + " | " + "right: " + str(target_right - target_left) )
	unit_display.position.x = target_left * container_size.x
	unit_display.size.x = (target_right - target_left) * container_size.x
	unit_display.position.y = target_top * container_size.y
	unit_display.size.y = (target_bttm - target_top) * container_size.y


func tween_anchor_unit_display(unit_display: Control, i: int, duration: float = 1.0):
	# Update container_size in case the panel resized
	container_size = self.size
	# init anchor targets
	var target_top: float
	var target_bttm: float
	var target_left: float
	var target_right: float
	# var start_pos := unit_display.global_position  # Removed unused variable
	# Calc the height% of each ratio/cell/tile for the pb spacing
	var max_units:int = combat_manager.get_max_defend_units() if combat_side == CombatSide.DEFENDING else combat_manager.get_max_attack_units()
	var segment_perc = (1 - 2 * DISPLAY_MARGIN_PERC) / ( max_units * DISPLAY_RATIO + (max_units-1) * DISPLAY_SPACE_RATIO)

	if(i == 0):
		target_top = DISPLAY_MARGIN_PERC
	else:
		target_top = (i * (DISPLAY_RATIO + DISPLAY_SPACE_RATIO)) * segment_perc + DISPLAY_MARGIN_PERC
	
	#unit_display.anchor_top = top_perc
	target_bttm = target_top + (DISPLAY_RATIO * segment_perc)
	if(fill_align == AlignmentOptions.LEFT_TO_RIGHT):
		target_left = MARGIN_ANCHOR
		target_right = LENGTH_ANCHOR
	else:
		target_left = (1 - LENGTH_ANCHOR)
		target_right = (1 - MARGIN_ANCHOR)

	# Convert % size to px size
	# Do the end converts bcs they're dependent on the start anchors .`. need to keep units the same
	target_right = (target_right - target_left) * container_size.x
	target_bttm = (target_bttm - target_top) * container_size.y
	target_left = target_left * container_size.x
	target_top = target_top * container_size.y

	# Apply Tween:
	var tween := create_tween().set_parallel(true).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(unit_display, "position:x", target_left, duration)
	tween.tween_property(unit_display, "size:x", target_right, duration)
	tween.tween_property(unit_display, "position:y", target_top , duration)
	tween.tween_property(unit_display, "size:y", target_bttm, duration)

	


func fwd_unit_deslected(unit: UnitObject):
	unit_deslected.emit(unit)


func combat_outcome(c_out: Array[CombatOutcome]):
	var outcome: Array[CombatOutcome]
	if combat_side == CombatSide.ATTACKING:
		outcome = c_out.filter(func(i): return (i.get_unit() in cur_combat.get_invading_units()))
	elif combat_side == CombatSide.DEFENDING:
		outcome = c_out.filter(func(i): return (i.get_unit() in cur_combat.get_defending_units()))

	# Create a list of units in the new order
	for i in range(self.get_child_count()):
		var unit_display = self.get_child(i)
		var target_unit = unit_display.get_unit()
		if target_unit != null:
			for j in range(outcome.size()):
				if outcome[j].get_unit() == target_unit:
					unit_display.update_outcome(outcome[j])
					tween_anchor_unit_display(unit_display, j)
					break


## Get/Set (er)s
func get_combat_side() -> CombatSide:
	return combat_side
func set_combat_side(side: CombatSide):
	combat_side = side


### Connected Signals
