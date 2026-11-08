# lander_inspector.gd
class_name LanderInspector
extends PanelContainer

## Details for the selected lander (right side of the screen): biome, owner, upkeep, building,
## units, what it connects to, and a shop when the local player can buy here.
## Shop buttons say why they're disabled (wrong phase, can't afford, lander full, ...).

signal action_requested(action: Action)
signal closed()

var _player: Player
var _turn_manager: TurnManager
var _lander_manager: LanderManager
var _combat_manager: CombatManager
var _lander: Lander

var _title: Label
var _owner_label: Label
var _details: VBoxContainer
var _shop_box: VBoxContainer
var _shop_title: Label
var _hint: Label


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(340, 0)
	var box := VBoxContainer.new()
	add_child(box)

	var header := HBoxContainer.new()
	_title = HudTheme.make_label("", HudTheme.TITLE_FONT_SIZE)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)
	var close_button := HudTheme.make_button("✕")
	close_button.tooltip_text = "Close"
	close_button.pressed.connect(func() -> void:
		hide()
		closed.emit())
	header.add_child(close_button)
	box.add_child(header)

	_owner_label = HudTheme.make_label()
	box.add_child(_owner_label)
	_details = VBoxContainer.new()
	_details.add_theme_constant_override("separation", 3)
	box.add_child(_details)

	box.add_child(HSeparator.new())
	_shop_title = HudTheme.make_label("Shop", HudTheme.SMALL_FONT_SIZE, HudTheme.MUTED)
	box.add_child(_shop_title)
	_shop_box = VBoxContainer.new()
	box.add_child(_shop_box)
	_hint = HudTheme.make_label("", HudTheme.SMALL_FONT_SIZE, HudTheme.MUTED)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.custom_minimum_size.x = 300
	box.add_child(_hint)
	hide()


#region Public API
func bind(player: Player, turn_manager: TurnManager, lander_manager: LanderManager, combat_manager: CombatManager) -> void:
	_player = player
	_turn_manager = turn_manager
	_lander_manager = lander_manager
	_combat_manager = combat_manager


func show_lander(lander: Lander) -> void:
	_lander = lander
	show()
	refresh()


func get_lander() -> Lander:
	return _lander


func refresh() -> void:
	if not visible or _lander == null or not is_instance_valid(_lander):
		return
	var owner_actor := _lander.get_owner_actor()
	_title.text = _lander.get_biome_data().get_display_name()
	if owner_actor == null:
		_owner_label.text = "Unclaimed"
		_owner_label.add_theme_color_override("font_color", HudTheme.MUTED)
	else:
		_owner_label.text = "Owner: %s (%s)" % [owner_actor.get_display_name(), owner_actor.get_species().get_display_name()]
		_owner_label.add_theme_color_override("font_color", owner_actor.get_color().lightened(0.3))
	_refresh_details(owner_actor)
	_refresh_shop(owner_actor)
#endregion


#region Private
func _refresh_details(owner_actor: Actor) -> void:
	for child in _details.get_children():
		child.free()
	var upkeep := HudTheme.format_cost(_lander.get_upkeep())
	_details.add_child(HudTheme.make_label("Upkeep: %s per turn" % ("nothing" if upkeep == "free" else upkeep),
		HudTheme.SMALL_FONT_SIZE, HudTheme.MUTED))

	if _lander.has_building():
		var building := _lander.get_building()
		var text := "Building: %s" % building.get_display_name()
		var is_undefended_enemy := not _lander.has_units() and building.get_owner_actor() != _player
		if is_undefended_enemy:
			text += "  (undefended)"
		_details.add_child(HudTheme.make_label(text, HudTheme.FONT_SIZE, HudTheme.WARN if is_undefended_enemy else HudTheme.TEXT))
	else:
		_details.add_child(HudTheme.make_label("No building", HudTheme.FONT_SIZE, HudTheme.MUTED))

	var units := _lander.get_units()
	_details.add_child(HudTheme.make_label("Units %d / %d" % [units.size(), _lander.get_unit_capacity()]))
	var counts := {}
	for unit in units:
		counts[unit.get_display_name()] = counts.get(unit.get_display_name(), 0) + 1
	for unit_name: String in counts:
		var sample: UnitInstance = units.filter(func(u: UnitInstance) -> bool: return u.get_display_name() == unit_name)[0]
		var damage := sample.get_damage()
		_details.add_child(HudTheme.make_label("   %d × %s   %s" % [counts[unit_name], unit_name, _dice_text(damage)],
			HudTheme.SMALL_FONT_SIZE))

	var connected := _lander_manager.get_connected_landers(_lander)
	_details.add_child(HudTheme.make_label("Connected to %d lander%s" % [connected.size(), "" if connected.size() == 1 else "s"],
		HudTheme.SMALL_FONT_SIZE, HudTheme.MUTED))


func _refresh_shop(owner_actor: Actor) -> void:
	for child in _shop_box.get_children():
		child.free()
	var is_ours := owner_actor == _player
	var purchasables: Array[Resource] = []
	if is_ours:
		purchasables = _lander.get_purchasables(_player)
	_shop_title.visible = is_ours and not purchasables.is_empty()
	_shop_box.visible = _shop_title.visible

	var phase_problem := ""
	if _turn_manager.get_game_state() != TurnManager.GameState.MAIN_LOOP or _turn_manager.get_active_actor() != _player:
		phase_problem = "You can buy on your turn, in the Buying phase"
	elif _turn_manager.get_game_phase() != TurnManager.Phase.BUYING:
		phase_problem = "You can buy in the Buying phase"

	for purchasable in purchasables:
		var button := ShopButton.new()
		button.set_purchasable(purchasable)
		button.set_target_lander(_lander)
		var problem := phase_problem
		if problem == "":
			problem = _purchase_problem(purchasable)
		button.disabled = problem != ""
		button.tooltip_text = problem if problem != "" else "Buy %s" % purchasable.get("display_name")
		button.action_requested.connect(action_requested.emit)
		_shop_box.add_child(button)

	if not is_ours:
		_hint.text = "Drag one of your connected landers onto this one to attack it." if owner_actor != null and _lander.has_units() \
			else ("Move units here to take it (capture or raze its building)." if owner_actor != null else "Move units here to claim it.")
	elif _turn_manager.get_game_phase() == TurnManager.Phase.COMBAT and _turn_manager.get_active_actor() == _player:
		_hint.text = "Drag from this lander to a connected one to move units or attack."
	elif not purchasables.is_empty():
		_hint.text = phase_problem
	else:
		_hint.text = "Nothing to buy here. Units can build a building on a lander that has none."
	_hint.visible = _hint.text != ""


## Mirrors ActionManager's purchase rules so the button can say why it's disabled.
func _purchase_problem(purchasable: Resource) -> String:
	var cost: EconData = purchasable.get_cost()
	if not _player.get_wallet().can_afford(cost):
		return "Not enough resources (costs %s)" % HudTheme.format_cost(cost)
	if purchasable is UnitData and _lander.is_full():
		return "This lander is full"
	if purchasable is BuildingData and _lander.has_building():
		return "This lander already has a building"
	return ""


static func _dice_text(damage: DamageData) -> String:
	if damage == null:
		return ""
	var text := "%dd%d" % [damage.get_dice_count(), damage.get_dice_sides()]
	if damage.get_modifier() != 0:
		text += "%+d" % damage.get_modifier()
	return text
#endregion
