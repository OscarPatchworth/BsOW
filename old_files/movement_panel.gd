#movement_panel.gd
#class_name ClassName
extends Panel

# signals
signal move_action_req(req: Action)

# enums

# constants

# static variables
var lander_manager: LanderManager

# @export variables

# remaining regular variables
var from_lander: Lander
var to_lander: Lander

var origin_units: Array[UnitObject]

# @onready variables
@onready var from_panel: Panel = self.find_child("FromPanel")
@onready var to_panel: Panel = self.find_child("ToPanel")
@onready var arrow_rtl: RichTextLabel = self.find_child("ArrowRTL")
@onready var from_list_box: ListBox = from_panel.find_child("VListBox")
@onready var to_list_box: ListBox = to_panel.find_child("VListBox")
@onready var action_btns: HBoxContainer = self.find_child("ActionBtns")
@onready var cancle_btn: Button = action_btns.find_child("CancleBtn")
@onready var move_btn: Button = action_btns.find_child("MoveBtn")

###################################################################################################
###	Methods
func _ready() -> void:
	from_list_box.list_btn_pressed.connect(self.unit_selected)
	cancle_btn.pressed.connect(self.cancel_movement)
	move_btn.pressed.connect(self.req_move_action)


func free_children(parent: Node) -> void:
	for i in parent.get_children():
		i.queue_free()


func unit_selected(unit: UnitObject):
	if unit in origin_units:
		origin_units.erase(unit)
	else:
		origin_units.append(unit)
	print(origin_units)


func cancel_movement():
	close_ui()


func close_ui():
	from_lander = null
	to_lander = null
	origin_units = []
	self.hide()


func req_move_action():
	var new_action =  Action.new()
	new_action.set_type(Action.RequestType.MOVEMENT)
	new_action.set_origin_lander(from_lander)
	new_action.set_target_lander(to_lander)
	new_action.set_origin_units(origin_units)
	move_action_req.emit(new_action)
	close_ui()

### Connected Signals


## Calls
func bind_lander_manager(lm: LanderManager):
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
		
		# update ListBoxs
		from_list_box.set_objects(from_lander.get_units(), func(unit): return unit.get_unit_data().name)
		to_list_box.set_objects(to_lander.get_units(), func(unit): return unit.get_unit_data().name)



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
