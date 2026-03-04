#combat_progress_bar.gd
extends ProgressBar

# signals

# enums

# constants
const delselected_fill_perc: int = 64
const selected_fill_perc: int = 100

# static variables

# @export variables

# remaining regular variables
var bar_colour: Color
var is_filled: bool = false

var pb_stylebox = StyleBoxFlat.new()

var unit: UnitObject

# @onready variables
@onready var btn: GameButton = self.find_child("GameButton")


###################################################################################################
###	Methods
func _ready() -> void:
	self.add_theme_stylebox_override("fill", pb_stylebox)
	connect_signals()


func free_children(parent: Node) -> void:
	for i in parent.get_children():
		i.queue_free()


func update_all():
	update_colour()
	update_filled()
	update_txt()

func update_colour():
	pb_stylebox.bg_color = bar_colour


func update_filled():
	if is_filled: 
		set_value(selected_fill_perc)  
		btn.show()
	else: 
		btn.hide()
		set_value(delselected_fill_perc)
	

func update_txt():
	if unit == null:
		btn.text = ""
	else:
		btn.text = unit.get_unit_data().name


### Connected Signals
func connect_signals():
	btn.pressed.connect(self.fwd_unit_deselected)


func fwd_unit_deselected():
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

### Connected Signals
