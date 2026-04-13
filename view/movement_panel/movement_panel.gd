#movement_panel.gd
#class_name ClassName
extends Panel

# signals

# enums

# constants

# static variables
var lander_manager: GameManager

# @export variables

# remaining regular variables
var from_lander: Lander
var to_lander: Lander

var selected_units: Array[UnitObject]

# @onready variables
@onready var from_panel: Panel = self.find_child("FromPanel")
@onready var to_panel: Panel = self.find_child("ToPanel")
@onready var arrow_rtl: RichTextLabel = self.find_child("ArrowRTL")
@onready var from_list_box: ListBox = from_panel.find_child("ListBox")
@onready var to_list_box: ListBox = to_panel.find_child("ListBox")

###################################################################################################
###	Methods
func _ready() -> void:
	from_list_box.list_btn_pressed.connect(self.unit_selected)


func free_children(parent: Node) -> void:
	for i in parent.get_children():
		i.queue_free()


func unit_selected(unit: UnitObject):
	if unit in selected_units:
		selected_units.erase(unit)
	else:
		selected_units.append(unit)
	print(selected_units)


### Connected Signals


## Calls
func bind_lander_manager(lm: GameManager):
	lander_manager = lm


func run_movement(from: Lander, to: Lander,):
	self.show()
	to_lander = to
	from_lander = from

	if(to_lander == null or from_lander == null):
		print("Movement Panel | Err | setup_display() called without set landers ")
		return
	else:
		# setup titles
		from_panel.find_child("Label").text = from_lander.get_biome().name
		to_panel.find_child("Label").text = to_lander.get_biome().name
		
		# Format units for ListBox
		var formated_from_units = from_lander.get_units().map(func(unit): return {"object" : unit, "text" : unit.get_unit_data().name})
		var formated_to_units = to_lander.get_units().map(func(unit): return {"object" : unit, "text" : unit.get_unit_data().name})
		
		# update ListBoxs
		from_list_box.set_objects(formated_from_units)
		to_list_box.set_objects(formated_to_units)



## Get/Set (er)s
func get_to_lander() -> Lander:
	return to_lander
func set_to_lander(lnd: Lander):
	to_lander = lnd


func get_from_lander() -> Lander:
	return from_lander
func set_from_lander(lnd: Lander):
	from_lander = lnd


### Connected Signals
