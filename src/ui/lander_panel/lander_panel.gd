# lander_panel.gd
# The root/router for the Lander (Debug) Panel
extends Panel

#region Signals
signal build_action_req(req: Action)
signal buy_unit_action_req(req: Action)
signal move_units_action_req(req: Action)
signal attack_action_req(req: Action)
#endregion

#region Scene Refs
var lander_manager: LanderManager
var selector := {
	"origin_lander": null,
	"origin_units": [],
	"target_lander": null,
	"player": null
}
@onready var building_control: Control = self.find_child("BuildingControl")
@onready var unit_control: Control = self.find_child("UnitControl")
@onready var lander_control: Control = self.find_child("LanderControl")
@onready var biome_label: Label = find_child("BiomeLabel")
#endregion

###################################################################################################
#region Lifecycle
func _ready() -> void:
	bind_selector_to_children()
	connect_signals()

func update() -> void:
	var cur_lander = selector.origin_lander
	if cur_lander:
		biome_label.text = str(cur_lander.biome_data.name)
		update_building_control(cur_lander)
		update_unit_control(cur_lander)
		update_lander_control(cur_lander)
#endregion

#region Binders
func bind_selector_to_children() -> void:
	building_control.bind_selector(selector)
	unit_control.bind_selector(selector)
	lander_control.bind_selector(selector)


func bind_lander_manager(lm: LanderManager) -> void:
	lander_manager = lm
	lander_control.bind_lander_manager(lm)


func bind_player(p: Player):
	selector.player = p
	
#endregion

#region Selector Mutations
func on_target_lander_changed(lander: Lander) -> void:
	selector.target_lander = lander


func on_unit_selected(unit: UnitObject) -> void:
	if unit in selector.origin_units:
		print("Selector Err: unit already in origin_units[]")
		return
	selector.origin_units.append(unit)


func on_unit_deselected(unit: UnitObject) -> void:
	if unit not in selector.origin_units:
		print("Selector Err: unit not in origin_units[]")
		return
	selector.origin_units.erase(unit)

func clear_origin_units() -> void:
	selector.origin_units = []
#endregion

#region Signal Connections
func connect_signals() -> void:
	building_control.build_action_req.connect(fwd_build_request)
	unit_control.buy_unit_action_req.connect(fwd_buy_unit_action_req)
	lander_control.move_units_action_req.connect(fwd_move_units_req)
	lander_control.attack_action_req.connect(fwd_attack_action_req)
	lander_control.target_lander_changed.connect(on_target_lander_changed)
	lander_control.unit_selected.connect(on_unit_selected)
	lander_control.unit_deselected.connect(on_unit_deselected)
	lander_control.lander_control_updated.connect(clear_origin_units)
#endregion

#region Forwarders
func fwd_build_request(req: Action) -> void:
	build_action_req.emit(req)


func fwd_buy_unit_action_req(buy_unit_req: Action) -> void:
	buy_unit_req.target_lander = selector.origin_lander
	buy_unit_action_req.emit(buy_unit_req)


func fwd_move_units_req(req: Action) -> void:
	req.target_lander = selector.target_lander
	req.origin_lander = selector.origin_lander
	req.origin_units = selector.origin_units
	move_units_action_req.emit(req)


func fwd_attack_action_req(req: Action) -> void:
	req.target_lander = selector.target_lander
	req.origin_lander = selector.origin_lander
	req.origin_units = selector.origin_units
	attack_action_req.emit(req)
#endregion

#region Callbacks
func update_building_control(cur_lander: Lander) -> void:
	if cur_lander.has_building:
		building_control.set_state_building_details()
	else:
		building_control.set_state_building_shop()


func update_unit_control(cur_lander: Lander) -> void:
	if cur_lander.units.size() >= cur_lander.unit_capacity:
		unit_control.set_state_details()
	else:
		unit_control.set_state_shop()


func update_lander_control(cur_lander: Lander) -> void:
	lander_control.update()
#endregion

# End Of File
