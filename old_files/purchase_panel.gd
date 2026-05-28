#purchase_panel.gd
extends Panel

# signals
signal purchase_action_req(req: Action)
signal close_market()

# enums

# constants

# static variables
var lander_manager: LanderManager
var player_self: Player


# @export variables

# remaining regular variables
var active_lander: Lander

# @onready variables
@onready var lander_listbox: ListBox = self.find_child("LandersListBox")
@onready var market_listbox: ListBox = self.find_child("MarketListBox")
@onready var finish_btn: Button = self.find_child("FinishBtn")


###################################################################################################
###	Methods
func _ready() -> void:
	self.hide()
	lander_listbox.list_btn_pressed.connect(self.lander_btn_pressed)
	market_listbox.list_btn_pressed.connect(self.market_btn_pressed)
	finish_btn.pressed.connect(self.pressed_close_market)


func free_children(parent: Node) -> void:
	for i in parent.get_children():
		i.queue_free()


func lander_btn_pressed(lnd: Lander):
	active_lander = lnd
	# Get purchases from lander
	var lander_purchases = []
	# Add any building Upgrades
	lander_purchases = get_lander_purchasables(lnd)
	


	market_listbox.set_objects(lander_purchases, func(purchasable): return purchasable.name)
	

func market_btn_pressed(item):
	var buy_req = Action.new()
	buy_req.set_type(Action.RequestType.BUY)
	buy_req.set_actor(player_self)
	buy_req.set_origin_lander(active_lander)
	buy_req.set_purchasable(item)
	purchase_action_req.emit(buy_req)


func get_lander_purchasables(lnd: Lander) -> Array:
	var all_purchases = []
	# Building Upgrages
	##print(lnd.get_purchases())
	for upgrade in lnd.get_purchases()["Building upgrades"]:
		all_purchases.append(upgrade)

	# Units
	for unit in player_self.get_species().units:
		if unit.get_type() in lnd.get_purchases()["Unit Types"]:
			all_purchases.append(unit)

	# Buildings
	for unit in lnd.get_units():
		#print(unit.get_purchases())
		if lnd.building == null and unit.get_purchases()["buildings"] != []:
			for building in unit.get_purchases()["buildings"]:
				if building not in all_purchases:
					all_purchases.append(building)


	# Abilites

	return all_purchases


func pressed_close_market():
	lander_listbox.clear()
	market_listbox.clear()
	close_market.emit()

### Connected Signals


## Calls
func bind_lander_manager(lm: LanderManager):
	lander_manager = lm


func bind_player(p: Player):
	player_self = p


func run_market():
	self.show()
	var landers = lander_manager.get_landers_actor_has(player_self)
	lander_listbox.set_objects(landers, func(lnd): return lnd.get_biome().name)

	# Adjust btns
	var lander_btns = await lander_listbox.get_btns()
	for i in range(lander_btns.size()):
		# If lander doesn't have purchases disable it's btn
		if get_lander_purchasables(landers[i]) == []:
			lander_btns[i].disabled = true

			
## Get/Set (er)s

### Connected Signals
