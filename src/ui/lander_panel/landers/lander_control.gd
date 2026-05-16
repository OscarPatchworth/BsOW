# lander_control.gd
extends VBoxContainer

#region Signals
signal lander_control_updated
signal move_units_action_req(req: Action)
signal attack_action_req(req: Action)
signal target_lander_changed(lander: Lander)
signal unit_selected(unit: UnitObject)
signal unit_deselected(unit: UnitObject)
#endregion

#region Scene Refs
var selector: Dictionary
var lander_manager: LanderManager
var cur_lander: Lander
@export var ui_player: Actor
@export var connected_lander_btn_script: Script
@export var unit_lander_btn_script: Script
@onready var lander_hflow: HFlowContainer = self.find_child("Landers")
@onready var units_hflow: HFlowContainer = self.find_child("Units")
#endregion

###################################################################################################
#region Lifecycle
func update() -> void:
	cur_lander = selector.selected_lander
	if cur_lander == null:
		print("Lander Control: null lander selected")
		return
	update_connected_landers()
	update_unit_landers()
	lander_control_updated.emit()
#endregion

#region Binders
func bind_selector(sel: Dictionary) -> void:
	selector = sel

func bind_lander_manager(lm: LanderManager) -> void:
	lander_manager = lm
#endregion

#region Display Updates
func update_connected_landers() -> void:
	free_children(lander_hflow)
	var connected_landers: Array[Lander] = lander_manager.get_connected_landers(cur_lander)
	for lander in connected_landers:
		var new_lnd_btn = ConnectedLanderControlButton.new()
		new_lnd_btn.lander = lander
		if lander.get_ownr() != null:
			if lander.get_ownr() == ui_player:
				new_lnd_btn.display_state = ConnectedLanderControlButton.DisplayState.ALLY
			else:
				new_lnd_btn.display_state = ConnectedLanderControlButton.DisplayState.ENEMY
		lander_hflow.add_child(new_lnd_btn)
		new_lnd_btn.update_display()
		new_lnd_btn.btn_pressed.connect(func(lander): target_lander_changed.emit(lander))
		new_lnd_btn.move_units_action_req.connect(fwd_move_units_req)
		new_lnd_btn.attack_lander_action_req.connect(fwd_attack_req)

func update_unit_landers() -> void:
	free_children(units_hflow)
	for unit in cur_lander.units:
		var new_unit_btn = UnitLanderControlButton.new()
		new_unit_btn.unit = unit
		new_unit_btn.update_display()
		units_hflow.add_child(new_unit_btn)
		new_unit_btn.unit_selected.connect(func(u): unit_selected.emit(u))
		new_unit_btn.unit_deselected.connect(func(u): unit_deselected.emit(u))
#endregion

#region Helpers
func free_children(parent: Node) -> void:
	for i in parent.get_children():
		i.queue_free()
#endregion

#region Forwarders
func fwd_move_units_req(req: Action) -> void:
	move_units_action_req.emit(req)

func fwd_attack_req(req: Action) -> void:
	attack_action_req.emit(req)
#endregion

# End Of File
