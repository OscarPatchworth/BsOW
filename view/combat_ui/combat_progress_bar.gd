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

# @onready variables

###################################################################################################
###	Methods
func _ready() -> void:
	self.add_theme_stylebox_override("fill", pb_stylebox)


func free_children(parent: Node) -> void:
	for i in parent.get_children():
		i.queue_free()


func update_colour():
	pb_stylebox.bg_color = bar_colour


func update_filled():
	set_value(selected_fill_perc) if is_filled else set_value(delselected_fill_perc)
	
### Connected Signals


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

### Connected Signals
