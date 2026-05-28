# movement_panel.gd
extends Panel

#region Signals
signal move_action_req(req: Action)
#endregion

#region Scene Refs
var from_lander: Lander
var to_lander: Lander
var origin_units: Array[UnitObject]
@onready var from_panel: Panel = self.find_child("FromPanel")
@onready var to_panel: Panel = self.find_child("ToPanel")
@onready var from_list_box: ListBox = from_panel.find_child("VListBox")
@onready var to_list_box: ListBox = to_panel.find_child("VListBox")
@onready var action_btns: HBoxContainer = self.find_child("ActionBtns")
@onready var cancel_btn: GameButton = action_btns.find_child("CancleBtn")
@onready var move_btn: GameButton = action_btns.find_child("MoveBtn")
#endregion

###################################################################################################
#region Lifecycle
func _ready() -> void:
	connect_signals()
#endregion

#region Signals
func connect_signals() -> void:
	from_list_box.list_btn_pressed.connect(on_unit_pressed)
	cancel_btn.pressed.connect(on_cancel_pressed)
	move_btn.pressed.connect(on_move_pressed)
#endregion

#region Callbacks
func on_unit_pressed(unit: UnitObject) -> void:
	if unit in origin_units:
		origin_units.erase(unit)
	else:
		origin_units.append(unit)

func on_cancel_pressed() -> void:
	close_ui()

func on_move_pressed() -> void:
	var new_action = Action.new()
	new_action.set_type(Action.RequestType.MOVEMENT)
	new_action.set_origin_lander(from_lander)
	new_action.set_target_lander(to_lander)
	new_action.set_origin_units(origin_units)
	move_action_req.emit(new_action)
	close_ui()
#endregion

#region Public API
func run_movement(from: Lander, to: Lander) -> void:
	from_lander = from
	to_lander = to
	if to_lander == null or from_lander == null:
		print("Movement Panel | Err | run_movement() called without set landers")
		return
	from_panel.find_child("Label").text = from_lander.get_biome().name
	to_panel.find_child("Label").text = to_lander.get_biome().name
	from_list_box.set_objects(from_lander.get_units(), func(unit): return unit.get_unit_data().name)
	to_list_box.set_objects(to_lander.get_units(), func(unit): return unit.get_unit_data().name)
	self.show()
#endregion

#region Helpers
func close_ui() -> void:
	from_lander = null
	to_lander = null
	origin_units = []
	self.hide()
#endregion

#region State Queries
func get_to_lander() -> Lander:
	return to_lander
func set_to_lander(lnd: Lander) -> void:
	to_lander = lnd

func get_from_lander() -> Lander:
	return from_lander
func set_from_lander(lnd: Lander) -> void:
	from_lander = lnd
#endregion

# End Of File