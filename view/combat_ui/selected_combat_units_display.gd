#selected_combat_units_display.gd
extends Control

# signals
signal unit_deslected(unit: UnitObject)

# enums
enum FillDir {
	FILL_LEFT_TO_RIGHT = 0, # 0 corrosponds to left Anchor Side in set_anchor)
	FILL_RIGHT_TO_LEFT = 2	# 2 corrosponds to right Anchor Side in set_anchor)
}

enum CombatState {
	SELECTING,
	READY
}

# constants
const delselected_fill_perc: float = 0.64
const selected_fill_perc: float = 1.0

# static variables

# @export variables

# remaining regular variables
var bar_colour: Color
var is_filled: bool = false
var fill_dir: FillDir = FillDir.FILL_LEFT_TO_RIGHT

var fill_stylebox = StyleBoxFlat.new()

var unit: UnitObject

var combat_state: CombatState = CombatState.SELECTING

# @onready variables
@onready var btn: GameButton = self.find_child("GameButton")
@onready var fill: Panel = self.find_child("Fill")
@onready var rtl: RichTextLabel = self.find_child("RichTextLabel")


###################################################################################################
###	Methods
func _ready() -> void:
	fill.add_theme_stylebox_override("panel", fill_stylebox)
	connect_signals()


func free_children(parent: Node) -> void:
	for i in parent.get_children():
		i.queue_free()


func update_all():
	update_colour()
	update_filled()
	update_txt()
	update_btn_style()


func update_colour():
	fill_stylebox.bg_color = bar_colour


func update_filled():
	if is_filled: 
		if(fill_dir == FillDir.FILL_LEFT_TO_RIGHT):
			fill.set_anchor_and_offset(SIDE_LEFT, 0, 0)
			fill.set_anchor_and_offset(SIDE_RIGHT, selected_fill_perc, 0)
		if(fill_dir == FillDir.FILL_RIGHT_TO_LEFT):
			fill.set_anchor_and_offset(SIDE_RIGHT, 1, 0)
			fill.set_anchor_and_offset(SIDE_LEFT, 1 - selected_fill_perc, 0)

		btn.show()
	else: 
		btn.hide()
		if(fill_dir == FillDir.FILL_LEFT_TO_RIGHT):
			fill.set_anchor_and_offset(SIDE_LEFT, 0, 0)
			fill.set_anchor_and_offset(SIDE_RIGHT, delselected_fill_perc, 0)
		if(fill_dir == FillDir.FILL_RIGHT_TO_LEFT):
			fill.set_anchor_and_offset(SIDE_RIGHT, 1, 0)
			fill.set_anchor_and_offset(SIDE_LEFT, 1 - delselected_fill_perc, 0)


func update_txt():
	if unit == null:
		rtl.set_text("")
	else:
		rtl.set_text(unit.get_unit_data().name)


func update_btn_style():
	if(combat_state == CombatState.SELECTING):
		btn.set_disabled(false)
	else: btn.set_disabled(true)

### Connected Signals
func connect_signals():
	btn.pressed.connect(self.fwd_unit_deselected)
	btn.mouse_entered.connect(btn_mouse_entered)
	btn.mouse_exited.connect(btn_mouse_exit)


func btn_mouse_entered():
	#set_colour(Color.FOREST_GREEN)
	pass
func btn_mouse_exit():
	#set_colour(Color.MAROON)
	pass


func fwd_unit_deselected():
	unit_deslected.emit(unit)
	print("Combat progress bar | unit deselected")
## Calls

## Get/Set (er)s
func get_colour() -> Color:
	return bar_colour
func set_colour(col: Color):
	bar_colour = col
	update_colour()

func get_filled() -> bool:
	return is_filled
func set_filled(yn: bool):
	is_filled = yn
	update_filled()

func get_unit() -> UnitObject:
	return unit
func set_unit(u: UnitObject):
	unit = u 
	if u == null: 
		set_filled(false)
		update_all()
	else: 
		btn.show()
		set_filled(true)
		update_all()


func get_fill_dir() -> FillDir:
	return fill_dir
func set_fill_dir(dir: FillDir):
	fill_dir = dir


func get_combat_state() -> CombatState:
	return combat_state
func set_combat_state(state: CombatState):
	combat_state = state
	update_all()



### Connected Signals
