#combat_panel.gd
extends Panel

# signals
signal unit_selected(unit: UnitObject)
signal unit_deslected(unit: UnitObject)
signal player_combat_ready
signal player_combat_not_ready
signal combat_display_toggled(toggled_on: bool)
signal attack_req(req: Action)
signal comabt_ui_closed()

# enums

# constants

# static variables
var combat_manager: CombatManager
var player_self: Player

# @export variables

# remaining regular variables
var cur_contest: Contest
var combat_finished:bool = false


# @onready variables
@onready var self_units_pannel: Panel = self.find_child("SelfUnitsPanel")
@onready var opp_units_panel: Panel = self.find_child("OppUnitsPanel")
@onready var attack_ablt_panel: Panel = self.find_child("AttackAbilitiesPanel")
@onready var defend_ablt_panel: Panel = self.find_child("DefendAbilitiesPanel")
@onready var select_units_panel: Panel = self.find_child("SelectUnitsPanel")
@onready var select_ablt_panel: Panel = self.find_child("SelectAbilitiesPanel")
@onready var fight_btn: GameButton = self.find_child("FightBtn")
@onready var toggle_combat_display_btn: GameButton = self.find_child("ToggleDisplayBtn")
@onready var exit_combat_btn: GameButton = self.find_child("ExitCombatBtn")
@onready var repeat_combat_btn: GameButton = self.find_child("RepeatCombatBtn")

###################################################################################################
###	Methods
func free_children(parent: Node) -> void:
	for i in parent.get_children():
		i.queue_free()


func _ready() -> void:
	setup_signals()


func update(combat_state: Contest):
	cur_contest = combat_state
	
	# Set Combat Panels
	if(combat_state.get_invading_actor() == player_self):
		self_units_pannel.set_combat_side(self_units_pannel.CombatSide.ATTACKING) 
		opp_units_panel.set_combat_side(self_units_pannel.CombatSide.DEFENDING)	
	else:
		self_units_pannel.set_combat_side(self_units_pannel.CombatSide.DEFENDING) 
		opp_units_panel.set_combat_side(self_units_pannel.CombatSide.ATTACKING)	# Atk

	### Code taken from chatGPT
	for child in get_children():
		if child.has_method("update"):
			child.update(combat_state)
	###


func fwd_unit_selected(unit: UnitObject):
	unit_selected.emit(unit)


## Calls
func bind_combat_manager(cm: CombatManager):
	combat_manager = cm
	#print("Combat UI | Combat Manager Bound")

	### Code taken from chatGPT
	for child in get_children():
		if child.has_method("bind_combat_manager"):
			child.bind_combat_manager(cm)
	###


func setup_combat_display(contest: Contest):
	print("Combat UI | @ setup()")
	# Reset in_combat flag
	combat_finished = false

	# Hide End_combat btns
	exit_combat_btn.hide()
	repeat_combat_btn.hide()
	# Redraw state
	update(contest)


func bind_player(p: Player):
	player_self = p
	for child in get_children():
		if child.has_method("bind_player"):
			child.bind_player(p)


func update_combat_display(contest: Contest):
	update(contest)


func combat_outcome(c_out: Array[CombatOutcome]):
	# update in_combat flage
	combat_finished = true

	# Show end combat btns
	exit_combat_btn.show()
	if cur_contest.get_invading_actor() == player_self:
		repeat_combat_btn.show()

	# Update children end
	for child in get_children():
		if child.has_method("combat_outcome"):
			child.combat_outcome(c_out)


## Get/Set (er)s


### Connected Signals
func setup_signals():
	select_units_panel.unit_selected.connect(self.fwd_unit_selected)
	self_units_pannel.unit_deslected.connect(fwd_unit_deslected)
	opp_units_panel.unit_deslected.connect(fwd_unit_deslected)
	fight_btn.player_combat_ready.connect(fwd_player_combat_ready)
	fight_btn.player_combat_not_ready.connect(fwd_player_combat_not_ready)
	toggle_combat_display_btn.toggled.connect(self.toggle_combat_display)
	exit_combat_btn.pressed.connect(self.exit_combat)
	repeat_combat_btn.pressed.connect(self.repeat_attack)


func fwd_unit_deslected(unit: UnitObject):
	unit_deslected.emit(unit)
	

func fwd_player_combat_ready():
	player_combat_ready.emit()


func fwd_player_combat_not_ready():
	player_combat_not_ready.emit()


func toggle_combat_display(toggled_on: bool):
	if toggled_on:
		for child in get_children():
			if child != toggle_combat_display_btn:
				child.hide()
			else:
				child.text = "Show Combat Display"
	else:
		for child in get_children():
			if child != toggle_combat_display_btn:
				child.show()
			else:
				child.text = "Hide Combat Display"
	combat_display_toggled.emit(toggled_on)


func exit_combat():
	if combat_finished:
		# Defer null to allow access to other end of combat funcs()
		set_deferred("cur_contest", null) 
		self.hide()
		comabt_ui_closed.emit()
	else:
		print("Combat UI | Err | Exit Combat called while in combat")


func repeat_attack():
	if combat_finished and cur_contest.get_invading_actor() == null and cur_contest.get_invading_actor() == player_self:
		exit_combat()
		# generate new attack req
		var new_attack = Action.new()
		new_attack.set_type(Action.RequestType.ATTACK)
		new_attack.set_selected_lander(cur_contest.get_invading_lander())
		new_attack.set_target_lander(cur_contest.get_contested_lander())
		attack_req.emit(new_attack)
