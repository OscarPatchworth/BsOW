#select_units_panel.gd
extends Panel

# signals
signal unit_selected(unit: UnitObject)
# enums

# constants

# static variables
var combat_manager: GameManager
var player_self: Player

# @export variables
@export var unit_btn_script: Script

# remaining regular variables

# @onready variables
@onready var unit_btn_container: Container = self.find_child("VBoxContainer")

###################################################################################################
###	Methods
func free_children(parent: Node) -> void:
	for i in parent.get_children():
		i.queue_free()


### Connected Signals


## Calls
func bind_combat_manager(cm: GameManager):
	combat_manager = cm
	#print("Select units Panel | comabt UI | Combat Manager Bound")


func bind_player(p: Player):
	player_self = p
	for child in get_children():
		if child.has_method("bind_player"):
			child.bind_player(p)


func update(combat_state: Contest):
	free_children(unit_btn_container)

	var units: Array[UnitObject]

	if combat_state.get_invading_actor() == player_self:
		units = combat_state.get_invading_units()
	else:
		units = combat_state.get_defending_units()

	for unit in units:
		var new_btn = GameButton.new()
		new_btn.set_script(unit_btn_script)
		new_btn.unit_selected.connect(fwd_unit_selected)
		new_btn.set_unit(unit)

		new_btn.text = unit.get_unit_data().name
		unit_btn_container.add_child(new_btn)


## Get/Set (er)s


### Connected Signals
func fwd_unit_selected(unit: UnitObject):
	unit_selected.emit(unit)
