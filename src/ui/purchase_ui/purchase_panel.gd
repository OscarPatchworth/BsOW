# purchase_panel.gd
extends Panel

#region Signals
signal purchase_action_req(req: Action)
signal close_market()
#endregion

#region Scene Refs
var lander_manager: LanderManager
var player_self: Player
var active_lander: Lander
@onready var lander_listbox: ListBox = self.find_child("LandersListBox")
@onready var market_listbox: ListBox = self.find_child("MarketListBox")
@onready var finish_btn: Button = self.find_child("FinishBtn")
#endregion

###################################################################################################
#region Lifecycle
func _ready() -> void:
	self.hide()
	connect_signals()
#endregion

#region Binders
func bind_lander_manager(lm: LanderManager) -> void:
	lander_manager = lm

func bind_player(p: Player) -> void:
	player_self = p
#endregion

#region Signals
func connect_signals() -> void:
	lander_listbox.list_btn_pressed.connect(lander_btn_pressed)
	market_listbox.list_btn_pressed.connect(market_btn_pressed)
	finish_btn.pressed.connect(close_btn_pressed)
#endregion

#region Public API
func run_market() -> void:
	self.show()
	var landers = lander_manager.get_landers_actor_has(player_self)
	lander_listbox.set_objects(landers, func(lnd): return lnd.get_biome().name)
	var lander_btns = await lander_listbox.get_btns()
	for i in range(lander_btns.size()):
		if get_lander_purchasables(landers[i]) == []:
			lander_btns[i].disabled = true
#endregion

#region Handlers
func lander_btn_pressed(lnd: Lander) -> void:
	active_lander = lnd
	market_listbox.set_objects(
		get_lander_purchasables(lnd),
		func(purchasable): return purchasable.name
	)

func market_btn_pressed(item) -> void:
	var buy_req = Action.new()
	buy_req.set_type(Action.RequestType.BUY)
	buy_req.set_actor(player_self)
	buy_req.set_origin_lander(active_lander)
	buy_req.set_purchasable(item)
	purchase_action_req.emit(buy_req)

func close_btn_pressed() -> void:
	lander_listbox.clear()
	market_listbox.clear()
	close_market.emit()
#endregion

#region Helpers
func get_lander_purchasables(lnd: Lander) -> Array:
	var all_purchases = []
	for upgrade in lnd.get_purchases()["Building upgrades"]:
		all_purchases.append(upgrade)
	for unit in player_self.get_species().units:
		if unit.get_type() in lnd.get_purchases()["Unit Types"]:
			all_purchases.append(unit)
	for unit in lnd.get_units():
		if lnd.building == null and unit.get_purchases()["buildings"] != []:
			for building in unit.get_purchases()["buildings"]:
				if building not in all_purchases:
					all_purchases.append(building)
	return all_purchases
#endregion

# End Of File
