#combat_panel.gd
extends Panel

# signals
signal unit_selected(unit: UnitObject)
signal unit_deslected(unit: UnitObject)

# enums

# constants

# static variables
var combat_manager: GameManager
var player_self: Player

# @export variables

# remaining regular variables

# @onready variables
@onready var attack_units_pannel: Panel = self.find_child("AttackUnitsPanel")
@onready var defend_units_panel: Panel = self.find_child("DefendUnitsPanel")
@onready var attack_ablt_panel: Panel = self.find_child("AttackAbilitiesPanel")
@onready var defend_ablt_panel: Panel = self.find_child("DefendAbilitiesPanel")
@onready var select_units_panel: Panel = self.find_child("SelectUnitsPanel")
@onready var select_ablt_panel: Panel = self.find_child("SelectAbilitiesPanel")
@onready var fight_btn: GameButton = self.find_child("FightBtn")



###################################################################################################
###	Methods
func free_children(parent: Node) -> void:
	for i in parent.get_children():
		i.queue_free()


func _ready() -> void:
	setup_signals()


func update(combat_state: Contest):
	### Code taken from chatGPT
	for child in get_children():
		if child.has_method("update"):
			child.update(combat_state)
	###

func fwd_unit_selected(unit: UnitObject):
	unit_selected.emit(unit)


## Calls
func bind_combat_manager(cm: GameManager):
	combat_manager = cm
	#print("Combat UI | Combat Manager Bound")

	### Code taken from chatGPT
	for child in get_children():
		if child.has_method("bind_combat_manager"):
			child.bind_combat_manager(cm)
	###


func setup_combat_display(contest: Contest):
	print("Combat UI | @ setup()")
	update(contest)


func bind_player(p: Player):
	player_self = p
	for child in get_children():
		if child.has_method("bind_player"):
			child.bind_player(p)


func update_combat_display(contest: Contest):
	update(contest)


func fwd_unit_deslected(unit: UnitObject):
	unit_deslected.emit(unit)
	

## Get/Set (er)s


### Connected Signals
func setup_signals():
	select_units_panel.unit_selected.connect(self.fwd_unit_selected)
	attack_units_pannel.unit_deslected.connect(fwd_unit_deslected)
	defend_units_panel.unit_deslected.connect(fwd_unit_deslected)
