# selected_combat_units_display.gd
extends Control

#region Signals
signal unit_deslected(unit: UnitObject)
#endregion

#region Enums
enum FillDir {
	FILL_LEFT_TO_RIGHT = 0,
	FILL_RIGHT_TO_LEFT = 2
}
enum CombatState {
	SELECTING,
	READY
}
#endregion

#region Constants
const DESELECT_FILL: float = 0.64
const SELECT_FILL: float = 1.0
const WON_FILL: float = 1.3
const LOST_FILL: float = 0.7
#endregion

#region Scene Refs
var fill_stylebox = StyleBoxFlat.new()
@onready var btn: Button = self.find_child("Button")
@onready var fill: Panel = self.find_child("Fill")
@onready var rtl: RichTextLabel = self.find_child("RichTextLabel")
#endregion

#region Runtime State
var bar_colour: Color:
	get:
		return bar_colour
	set(col):
		bar_colour = col
		update_colour()

var is_filled: bool = false:
	get:
		return is_filled
	set(yn):
		is_filled = yn
		update_filled()

var fill_dir: FillDir = FillDir.FILL_LEFT_TO_RIGHT:
	get:
		return fill_dir
	set(dir):
		fill_dir = dir

var unit: UnitObject:
	get:
		return unit
	set(u):
		unit = u
		if u == null:
			is_filled = false
		else:
			btn.show()
			is_filled = true
		update_all()

var combat_state: CombatState = CombatState.SELECTING:
	get:
		return combat_state
	set(state):
		combat_state = state
		update_all()
#endregion

###################################################################################################
#region Lifecycle
func _ready() -> void:
	fill.add_theme_stylebox_override("panel", fill_stylebox)
	connect_signals()
#endregion

#region Signal Connections
func connect_signals() -> void:
	btn.pressed.connect(fwd_unit_deselected)
	btn.mouse_entered.connect(btn_mouse_entered)
	btn.mouse_exited.connect(btn_mouse_exited)
#endregion

#region Display Updates
func update_all() -> void:
	update_colour()
	update_filled()
	update_txt()
	update_btn_style()

func update_colour() -> void:
	fill_stylebox.bg_color = bar_colour

func update_filled() -> void:
	if is_filled:
		if fill_dir == FillDir.FILL_LEFT_TO_RIGHT:
			fill.set_anchor_and_offset(SIDE_LEFT, 0, 0)
			fill.set_anchor_and_offset(SIDE_RIGHT, SELECT_FILL, 0)
		else:
			fill.set_anchor_and_offset(SIDE_RIGHT, 1, 0)
			fill.set_anchor_and_offset(SIDE_LEFT, 1 - SELECT_FILL, 0)
		btn.show()
	else:
		btn.hide()
		if fill_dir == FillDir.FILL_LEFT_TO_RIGHT:
			fill.set_anchor_and_offset(SIDE_LEFT, 0, 0)
			fill.set_anchor_and_offset(SIDE_RIGHT, DESELECT_FILL, 0)
		else:
			fill.set_anchor_and_offset(SIDE_RIGHT, 1, 0)
			fill.set_anchor_and_offset(SIDE_LEFT, 1 - DESELECT_FILL, 0)

func update_txt() -> void:
	rtl.set_text("" if unit == null else unit.get_unit_data().name)

func update_btn_style() -> void:
	btn.set_disabled(combat_state == CombatState.READY)

func update_outcome(c_out: CombatOutcome) -> void:
	combat_state = CombatState.READY
	rtl.set_text(str(c_out.get_total()))
#endregion

#region Callbacks
func btn_mouse_entered() -> void:
	pass

func btn_mouse_exited() -> void:
	pass

func fwd_unit_deselected() -> void:
	unit_deslected.emit(unit)
#endregion

# End Of File