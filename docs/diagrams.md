# BsOW diagrams

Mermaid diagrams of the code on `prototype`. GitHub renders them directly; in VS Code, install
the *Markdown Preview Mermaid Support* extension and open the Markdown preview.

**Reading the class diagrams:** every field listed on a `data/` or `logic/` class is read and written
through `get_x()` / `set_x()` (or `is_x()` / `has_x()` / `can_x()`), and those accessors go through
`AbilitySystem.resolve_get()` / `resolve_set()`. The accessors themselves are left out to keep the
diagrams small.

1. [Data resources](#1-data-resources-authored-templates)
2. [Abilities](#2-abilities)
3. [Runtime model](#3-runtime-model)
4. [Managers and actors](#4-managers-and-actors)
5. [Screens, scene tree and signal wiring](#5-screens-scene-tree-and-signal-wiring)
6. [HUD and board markers](#6-hud-and-board-markers)
7. [The Action pipeline](#7-the-action-pipeline)
8. [Playthrough: menus, setup and two rounds](#8-playthrough-menus-setup-and-two-rounds)
9. [Who built what](#9-who-built-what)

---

## 1. Data resources (authored templates)

`*Data` classes are `Resource`s authored in the inspector and saved as `.tres`. They are shared by every
instance made from them, so an ability that should affect *one* unit hooks `UnitInstance`, not `UnitData`.

```mermaid
classDiagram
    direction LR

    class SpeciesData {
        +String display_name
        +String description
        +Array~BuildingData~ buildings
        +Array~UnitData~ units
        +Array~BiomeData~ starting_biomes
        +BuildingData command_tower
        +Array~Ability~ abilities
    }

    class UnitData {
        +UnitData base
        +String display_name
        +PackedScene mesh_scene
        +Texture2D icon
        +EconData cost
        +UnitType unit_type
        +DamageData damage
        +bool can_build
        +Array~BuildingData~ buildables
        +Array~Ability~ abilities
        +is_or_inherits(other) bool
    }

    class UnitType {
        <<enumeration>>
        NULL
        MELEE_BASIC
        MELEE_ADVANCED
        RANGED_BASIC
        RANGED_ADVANCED
        SPECIAL
    }

    class BuildingData {
        +String display_name
        +EconData cost
        +EconData upkeep
        +PackedScene mesh_scene
        +Texture2D icon
        +bool is_unique
        +bool overrides_unit_capacity
        +int unit_capacity
        +bool can_spawn
        +Array~UnitType~ spawnable_unit_types
        +bool can_upgrade
        +Array~BuildingData~ upgrades
        +Array~Ability~ abilities
    }

    class BiomeData {
        +String display_name
        +Material mesh_material
        +Texture2D icon
        +EconData upkeep
    }

    class DamageData {
        +int dice_count
        +int dice_sides
        +int modifier
    }

    class EconData {
        +Array~StringName~ RESOURCE_KEYS$
        +int gold
        +int food
        +int mineral
        +int wood
        +int stone
        +amounts_changed() signal
        +get_amount(key) int
        +set_amount(key, value)
        +can_afford(cost) bool
        +add(other)
        +subtract(other)
    }

    class MatchSettings {
        <<Node>>
        +int opponent_count = 2
        +int starting_biome_count = 4
        +int starting_resource_amount = 10
        +int upkeep_gold = 3
        +float ai_step_delay
        +Array~BiomeData~ game_biomes
        +Array~Ability~ rule_abilities
        +int map_size
        +int max_attacker_units
        +int max_defender_units
        +pick_starting_biomes(species) Array
    }

    SpeciesData --> BuildingData : buildings, command_tower
    SpeciesData --> UnitData : units
    SpeciesData --> BiomeData : starting_biomes
    SpeciesData --> Ability : race traits
    UnitData --> UnitData : base (inherits unset fields)
    UnitData --> UnitType
    UnitData --> DamageData : damage
    UnitData --> EconData : cost
    UnitData --> BuildingData : buildables
    UnitData --> Ability : unit traits
    BuildingData --> EconData : cost, upkeep
    BuildingData --> BuildingData : upgrades
    BuildingData ..> UnitType : spawnable_unit_types
    BuildingData --> Ability : effects on its lander
    BiomeData --> EconData : upkeep
    MatchSettings --> BiomeData : game_biomes
    MatchSettings --> Ability : rule_abilities
```

`EconData` plays two roles: a **price or income** (`UnitData.cost`, `BiomeData.upkeep`,
`BuildingData.upkeep`) and an actor's **wallet**. `UnitData.base` is an inheritance chain: a
`UnitData` that leaves a field empty (cost, damage, buildables, abilities) falls back to its `base`.

Current content: two races, **Lycanthrope** (Lycanth Halfbreed, Alpha Werewolf, Moon Den) and
**Ettercap** (Ettercap spawn, Venom Spitter, Web Spire); buildings Base (command tower, +2 food),
Castle Tower, Moon Den and Web Spire; biomes Plains (2 food), Forest (2 wood), Mountain (1 mineral,
1 stone) and Badlands (2 gold).

---

## 2. Abilities

An ability is a `Resource` script that extends `Ability`, saved as a `.tres` in `data/abilities/` and
attached to a race, a kind of unit, a building or the match rules (section 1). Every hook does nothing
by default; each ability overrides the ones it needs and decides for itself whether it fires.

```mermaid
classDiagram
    direction TB

    class Ability {
        <<Resource>>
        +String display_name
        +String description
        +Array~StringName~ value_hooks
        +modify_roll(outcome, unit, lander, contest, side)
        +check_move(unit, from, to) String
        +move_spends_movement(unit, from, to) bool
        +on_defeated_opponent(outcome, lander) String
        +modify_value(target, property, value) Variant
        #is_trait_of(unit) bool
    }

    class BuildingWardAbility {
        +int bonus = 2
        modify_roll: owner's units on its lander
    }
    class CombinedArmsAbility {
        +int bonus = 2
        modify_roll: ranged next to allied melee
    }
    class BiomeStrideAbility {
        +BiomeData biome
        move_spends_movement: false biome to biome
    }
    class BiomeAversionAbility {
        +BiomeData biome
        check_move: not onto biome (unless taking a building)
    }
    class PackCallAbility {
        on_defeated_opponent: a basic melee unit joins
    }
    class SideBonusAbility {
        +int bonus = 1
        +int side
        +BiomeData biome
        modify_roll: on that side, on that biome
    }
    class EnwebAbility {
        +EconData cost
        +int penalty = -1
        +int duration_turns = 2
        +is_caught(unit, lander) bool
        modify_roll and check_move on a webbed lander
    }

    class AbilitySystem {
        <<autoload>>
        +bind_match_settings(settings)
        +begin_match(actors)
        +resolve_get(target, property, base_value) Variant
        +resolve_set(target, property, current, new_value) Variant
        +abilities_for(unit, lander) Array~Ability~
        +add_combat_modifiers(outcome, contest, side)
        +check_move(unit, from, to) String
        +move_spends_movement(unit, from, to) bool
        +after_combat_round(contest, outcomes_by_side) Array~String~
        +find_species_ability(species, script) Ability
    }

    class WebInstance {
        <<RefCounted>>
        +Actor owner_actor
        +EnwebAbility ability
        +int turns_left
    }

    Ability <|-- BuildingWardAbility
    Ability <|-- CombinedArmsAbility
    Ability <|-- BiomeStrideAbility
    Ability <|-- BiomeAversionAbility
    Ability <|-- PackCallAbility
    Ability <|-- SideBonusAbility
    Ability <|-- EnwebAbility
    AbilitySystem ..> Ability : asks
    WebInstance --> EnwebAbility : spun with
```

**Which abilities apply to a unit** (`AbilitySystem.abilities_for(unit, lander)`):

```mermaid
flowchart LR
    U(["a unit on a lander"]) --> R["MatchSettings.rule_abilities<br/>(Combined Arms)"]
    U --> S["its owner's SpeciesData.abilities<br/>(race traits)"]
    U --> D["its UnitData.abilities<br/>(Pack Call)"]
    U --> B["the lander's BuildingData.abilities<br/>(Castle Tower)"]
    U --> W["the lander's WebInstance.ability<br/>(Web)"]
    R & S & D & B & W --> L["one list, no duplicates:<br/>each ability decides if it fires"]
```

**Where the game asks them**

| Hook | Called from | Used by |
|---|---|---|
| `modify_roll` | `CombatManager._roll_side` → `AbilitySystem.add_combat_modifiers` (after the dice) | Castle Tower +2, Combined Arms +2, Lurkers +1, Web -1 |
| `check_move` | `ActionManager._validate_move_units` (and SimpleAI's planning) | Mountain Shy, Web |
| `move_spends_movement` | `ActionManager._execute(MOVE_UNITS)`, before `has_moved` is set | Forest Runners |
| `on_defeated_opponent` | `CombatManager.resolve_combat` → `AbilitySystem.after_combat_round` (after the dead are removed) | Pack Call |
| `modify_value` | `AbilitySystem.resolve_get`, only for properties listed in `value_hooks` | (none yet; the smoke test checks it works) |

| Ability | `.tres` | Attached to | Effect |
|---|---|---|---|
| Forest Runners | `forest_runners.tres` (BiomeStride) | Lycanthrope | Forest to Forest moves don't use up the unit's move |
| Mountain Shy | `mountain_shy.tres` (BiomeAversion) | Lycanthrope | Can't move onto Mountains, except to take or raze an enemy building there |
| Pack Call | `pack_call.tres` | Alpha Werewolf | Each enemy unit it kills calls a Lycanth Halfbreed to its lander, if there's room |
| Web | `web.tres` (Enweb) | Ettercap | `ENWEB` (1 gold, 2 mineral) on a lander next to yours: non-Ettercaps on it get -1 and can't move off; one spends its move on `RAZE_WEB`, or it wears off after 2 of the owner's turns |
| Lurkers | `lurkers.tres` (SideBonus) | Ettercap | +1 when defending a Mountain |
| Castle Tower | `castle_tower_ward.tres` (BuildingWard) | Castle Tower | The owner's units fighting on its lander get +2 |
| Combined Arms | `combined_arms.tres` | Match rule | Ranged units get +2 when allied melee units fight alongside them |

---

## 3. Runtime model

These objects exist while a match is running. `Action`, `Contest`, `CombatOutcome`, `UnitInstance`,
`BuildingInstance` and `WebInstance` are `RefCounted`: they free themselves when nothing references them.

```mermaid
classDiagram
    direction TB

    class Actor {
        <<Node>>
        +SpeciesData species
        +EconData wallet
        +Color color
        +int combat_side
        +action_requested(action) signal
        +request_action(action)
        +is_active_actor() bool
        +get_display_name() String
        +begin_setup()
        +bind_action_manager(m)
        +bind_turn_manager(m)
        +bind_lander_manager(m)
        +bind_combat_manager(m)
        #_take_setup()*
        #_take_phase(phase)*
        #_game_phase_changed(phase)*
        #_enter_combat(contest)*
        #_action_resolved(action)*
        #_action_rejected(action, reason)*
    }

    class Player {
        +get_display_name() You
        +get_ui() UiManager
        +get_controller() PlayerController
        #acts through its UI, not _take_phase
    }

    class SimpleAI {
        +float step_delay
        +is_busy() bool
        +bind_gravity_system(g)
        +bind_match_settings(s)
        #_take_setup() places its cluster, then its tower
        #_take_phase(phase) places, buys, webs, attacks, claims
        #_enter_combat(contest) picks strongest, readies
    }

    class Lander {
        <<RigidBody3D>>
        +BiomeData biome_data
        +BuildingInstance building
        +Array~UnitInstance~ units
        +int unit_capacity
        +WebInstance web
        +crashed_into(other, speed) signal
        +get_board_position() Vector3
        +get_owner_actor() Actor
        +get_upkeep() EconData
        +get_purchasables(actor) Array
        +build(action)
        +build_for(data, owner)
        +buy_unit(action)
        +add_units(units)
        +remove_units(units)
        +remove_building()
        +refresh_markers()
        +flash(color)
    }

    class UnitInstance {
        <<RefCounted>>
        +UnitData unit_data
        +Actor owner_actor
        +int hit_points
        +bool has_moved
        +get_display_name() String
        +get_unit_type() UnitType
        +get_damage() DamageData
        +can_build_buildings() bool
    }

    class BuildingInstance {
        <<RefCounted>>
        +BuildingData building_data
        +Actor owner_actor
        +int hit_points
        +is_command_tower() bool
        +can_spawn_units() bool
        +get_spawnable_unit_types() Array
    }

    class WebInstance {
        <<RefCounted>>
        +Actor owner_actor
        +EnwebAbility ability
        +int turns_left
    }

    class Action {
        <<RefCounted>>
        +Type type
        +Actor actor
        +Vector3 position
        +Lander source_lander
        +Lander target_lander
        +Array~UnitInstance~ units
        +BuildingData building_data
        +BiomeData biome_data
        +Resource purchasable
        +BuildingFate building_fate
        +create(type)$ Action
        +create_system(type, actor)$ Action
        +is_system() bool
        +cancel(reason)
    }

    class ActionType {
        <<enumeration>>
        MOVE_UNITS
        ATTACK
        PURCHASE
        PLACE_LANDER
        PLACE_BUILDING
        PROGRESS_TURN
        PLACE_BIOME
        SELECT_COMBAT_UNIT
        DESELECT_COMBAT_UNIT
        DECLARE_COMBAT_READY
        WITHDRAW_COMBAT_READY
        RETREAT_COMBAT
        ENWEB
        RAZE_WEB
        FINISH_SETUP (system)
        COLLECT_UPKEEP (system)
        RESOLVE_COMBAT (system)
        ELIMINATE_ACTOR (system)
    }

    class BuildingFate {
        <<enumeration>>
        NONE
        CAPTURE
        RAZE
    }

    class Contest {
        <<RefCounted>>
        +lander(side) Lander
        +units(side) Array~UnitInstance~
        +ready(side) bool
        +int round
        +Result result
        +Array~CombatOutcome~ last_outcomes
        +Array~String~ last_notes
        +get_actor(side) Actor
        +get_side_of(actor) int
        +get_available_units(side) Array
        +begin_next_round()
        +is_over() bool
    }

    class CombatOutcome {
        <<RefCounted>>
        +UnitInstance unit
        +Array~int~ rolls
        +Array~int~ modifiers
        +int total
        +Outcome outcome
        +Reason reason
        +CombatOutcome opponent
        +roll_damage()
        +add_modifier(amount, label)
        +get_labelled_modifiers() Array
        +calculate_total() int
    }

    class Hex {
        <<static helpers>>
        +APOTHEM = 1.0
        +RADIUS = 1.155
        +distance(a, b)$ float
        +neighbour_slots(centre)$ Array
        +corners(radius)$ Array
        +ring_mesh(inner, outer)$ ArrayMesh
    }

    class MatchRequest {
        <<static>>
        +SpeciesData player_species$
        +int opponent_count$
        +set_choices(species, opponents)$
        +clear()$
    }

    Actor <|-- Player
    Actor <|-- SimpleAI
    Actor --> SpeciesData : species
    Actor --> EconData : wallet

    Lander --> BiomeData : biome_data
    Lander "1" o-- "0..1" BuildingInstance : building
    Lander "1" o-- "0..*" UnitInstance : units
    Lander "1" o-- "0..1" WebInstance : web
    Lander ..> Hex : shape and spacing

    UnitInstance --> UnitData : unit_data
    UnitInstance --> Actor : owner_actor
    BuildingInstance --> BuildingData : building_data
    BuildingInstance --> Actor : owner_actor
    WebInstance --> Actor : owner_actor

    Action --> ActionType : type
    Action --> BuildingFate : building_fate
    Action --> Actor : actor
    Action --> Lander : source / target
    Action --> UnitInstance : units

    Contest "1" --> "2" Lander : attacker / defender
    Contest --> UnitInstance : selected units
    Contest --> CombatOutcome : last_outcomes
    CombatOutcome --> UnitInstance : unit
    CombatOutcome --> CombatOutcome : opponent
```

Notes:

* `PLACE_BUILDING` is only the free command tower at the end of setup. Everything else is bought
  with `PURCHASE`, on `target_lander`.
* *System* actions are made with `Action.create_system()` and can't be requested by an actor.
* A lander has **no owner field**. `get_owner_actor()` works it out: the building's owner, otherwise the
  first unit's owner, otherwise `null` (neutral).
* **Hex landers.** Every lander is the same hexagon, pointy along +Z, and never rotates.
  `Hex.distance` is the face-to-face measure: two landers face to face are exactly 2.0 apart, they
  overlap below that, and they're *connected* up to 2.5.
* **One move per turn.** `UnitInstance.has_moved` is set by `MOVE_UNITS` (unless an ability makes the
  move free) and cleared at the owner's `COLLECT_UPKEEP`. Fighting doesn't count as a move.
* `CombatOutcome` keeps a label for each modifier (e.g. `[2, "Castle Tower"]`) so the battle dialog can
  say where it came from, and `opponent` (the outcome it was paired against) so kill reactions know
  who died. The enums are `Outcome {DEAD, ALIVE}` and
  `Reason {COMBAT_LOST, COMBAT_WON, ABILITY_SAVED, ABILITY_LOST, ABILITY_WON, NO_COMBAT}`.
* `MatchRequest` carries the menu choices (section 5). It's static, so it survives the scene change
  and "Play again".

---

## 4. Managers and actors

```mermaid
classDiagram
    direction LR

    class GameRoot {
        <<Node3D>>
        +Array~SpeciesData~ game_species
        +ACTOR_COLORS
        +root_setup_finished() signal
        -_add_player()
        -_add_ai(name) ×opponent_count
        -_add_actor(actor, species)
    }

    class ActionManager {
        +action_resolving(action) signal
        +action_resolved(action) signal
        +action_rejected(action, reason) signal
        +request_action(action)
        +MAX_ACTIONS_PER_CHAIN
        -Array~Action~ _queue
        -_validate(action) String
        -_execute(action)
    }

    class TurnManager {
        +game_state_changed(state) signal
        +game_phase_changed(phase) signal
        +turn_order_generated() signal
        +active_actor_changed(actor) signal
        +season_order_generated() signal
        +season_changed(index) signal
        +actor_eliminated(actor) signal
        +game_over(winner) signal
        +GameState game_state
        +Phase game_phase
        +Array~Actor~ turn_order
        +Actor active_actor
        +int round_number
        +int season_index
        +register_actor(actor)
        +start()
        +progress_phase()
        +begin_main_loop()
        +eliminate_actor(actor)
        +get_winner() Actor
    }

    class LanderManager {
        +lander_spawned(lander) signal
        +landers_crashed(a, b, speed) signal
        +float connected_lander_distance = 2.5
        +float board_half_size = 20
        +spawn_random_lander(pos) Lander
        +spawn_biome_lander(action) Lander
        +peek_next_biome(actor) BiomeData
        +spawn_next_lander_for(actor, pos) Lander
        +get_setup_landers_of(actor) Array
        +get_placement_problem(pos) String
        +is_inside_board(pos) bool
        +get_connected_landers(lander) Array
        +get_landers_in_hex_range(pos, distance) Array
        +get_landers_within(pos, radius) Array
        +get_landers_owned_by(actor) Array
        +move_units(action)
        +run_upkeep(actor)
        +refresh_unit_moves(actor)
        +age_webs_of(actor)
        +remove_assets_of(actor)
        +spawn_protected_lander(pos, owner, count) (tests)
    }

    class GravitySystem {
        +board_settled() signal
        +float gravity_range
        +float strength
        +float neighbour_share
        +float clustered_share_scale
        +float dock_speed
        +float dock_braking
        +float settled_mass_scale
        +float snap_touch_gap
        +float max_snap_distance
        +is_settled() bool
        +predict_settle_position(spot) Vector3
        +get_pull_preview(spot) Dictionary
    }

    class CombatManager {
        +combat_started(contest) signal
        +combat_updated(contest) signal
        +combat_resolved(outcomes) signal
        +combat_ended(contest) signal
        +MAX_ROUNDS = 12
        +Contest contest
        +max_units(side) int
        +start_combat(action)
        +select_unit(unit)
        +deselect_unit(unit)
        +set_actor_ready(actor, is_ready)
        +resolve_combat()
        +retreat()
        +is_in_progress() bool
    }

    class PlayerController {
        <<Node3D>>
        +action_requested(action) signal
        +lander_selected(lander) signal
        +lander_view_requested(lander) signal
        +movement_ui_requested(from, to) signal
        +ControllerState state
        +get_markers() BoardMarkers
        +focus_camera_on(point)
        +apply_game_state(state)
        +apply_game_phase(phase)
        +enter_combat()
        +exit_combat()
    }

    class PlacementPreview {
        <<Node3D>>
        +show_placement(spot, valid, settle, pulls, connects, tint, caption, problem)
        +show_drag(from, to, color)
        +show_hover(lander)
    }

    class BoardMarkers {
        <<Node3D>>
        +show_selection(lander)
        +add_arrow(key, from, to, color, label, seconds)
        +remove_arrow(key)
    }

    class UiManager {
        <<Control>>
        +action_requested(action) signal
        +setup_biome_selected(biome) signal
        +all_setup_biomes_placed() signal
        +camera_focus_requested(point) signal
        +alert(text)
        +show_lander_panel(lander)
        +show_combat(contest)
        +show_game_over(winner)
    }

    class SelectorManager {
        +Lander selected_lander
        +Array~UnitInstance~ selected_units
        +select_lander(lander)
    }

    GameRoot *-- ActionManager
    GameRoot *-- TurnManager
    GameRoot *-- LanderManager
    GameRoot *-- GravitySystem
    GameRoot *-- CombatManager
    GameRoot *-- MatchSettings
    GameRoot *-- Player : instantiates player.tscn
    GameRoot *-- "1..3" SimpleAI : creates (free-for-all)
    GameRoot ..> MatchRequest : reads the menu choices
    GameRoot ..> AbilitySystem : begin_match(actors)
    Actor <|-- Player
    Actor <|-- SimpleAI
    Actor --> ActionManager : action_requested

    ActionManager --> LanderManager
    ActionManager --> TurnManager
    ActionManager --> CombatManager
    ActionManager ..> AbilitySystem : check_move, move_spends_movement
    CombatManager ..> AbilitySystem : add_combat_modifiers, after_combat_round
    CombatManager --> MatchSettings
    GravitySystem --> LanderManager
    SimpleAI --> GravitySystem : waits for board_settled
    LanderManager "1" o-- "0..*" Lander

    Player *-- PlayerController
    Player *-- UiManager
    Player *-- SelectorManager
    PlayerController *-- PlacementPreview
    PlayerController *-- BoardMarkers
```

The managers only *execute*. All rule checks live in `ActionManager._validate()` (plus the abilities'
`check_move`), and the managers' methods are called from `ActionManager._execute()`. `EconManager` is an
empty placeholder and isn't shown. `Draw3D` is a debug drawing helper that `GameRoot` hands to the
`Player`.

**GravitySystem in short:** a new lander pulls (and is pulled by) landers within `gravity_range` for
`pull_duration`. Its speed is capped by its gap to the nearest lander (docking), its pull ends when it
touches another, settled landers are heavier, and landers already in a cluster barely feel the pull.
When everything stops, each lander that moved and touches another slides into the nearest free
face-to-face slot (snapping), then `board_settled` fires. Four invisible walls stand at
`board_half_size`.

---

## 5. Screens, scene tree and signal wiring

**Screens.** The project starts on the start screen (`run/main_scene`). The tests load `main.tscn`
directly, so `MatchRequest` is empty and the defaults apply (a random race, `opponent_count` AIs).

```mermaid
flowchart LR
    Start["StartScreen<br/>start_screen.tscn<br/>Play / Quit"] -- Play --> Setup["MatchSetupScreen<br/>race cards (or Random)<br/>1 / 2 / 3 AIs"]
    Setup -- Back --> Start
    Setup -- "Start match:<br/>MatchRequest.set_choices()" --> Game["main.tscn<br/>GameRoot reads MatchRequest"]
    Game -- "Game over panel:<br/>Play again (same choices)" --> Game
    Game -- "Game over panel:<br/>Main menu" --> Start
    Start -- Quit --> Exit(["quit"])
```

**Signal wiring in the game scene.** Solid arrows are signal connections, labelled with the signal
name. Dotted arrows are direct calls. `GameRoot._add_actor()` wires every actor the same way, and each
actor connects its own manager signals in its `bind_*()` methods.

```mermaid
flowchart LR
    subgraph PlayerNode["Player (player.tscn)"]
        direction TB
        PC[PlayerController<br/>+ PlacementPreview, BoardMarkers]
        UI[UiManager + panels]
        SM[SelectorManager]
        P((Player))
        PC -- action_requested --> P
        UI -- "action_requested<br/>(every button is an Action)" --> P
        PC -- lander_selected --> SM
        PC -- "lander_view_requested<br/>movement_ui_requested" --> UI
        UI -- "setup_biome_selected<br/>all_setup_biomes_placed" --> PC
        UI -- camera_focus_requested --> PC
    end

    AI(("SimpleAI ×1-3"))
    AM[ActionManager]
    TM[TurnManager]
    LM[LanderManager]
    GS[GravitySystem]
    CM[CombatManager]
    AS[[AbilitySystem]]
    GR[GameRoot]

    P -- "action_requested<br/>(actor stamped)" --> AM
    AI -- "action_requested<br/>(actor stamped)" --> AM

    AM -.->|"_execute: spawn, move_units, run_upkeep,<br/>lander.build / buy_unit, webs"| LM
    AM -.->|"_execute: progress_phase, begin_main_loop,<br/>eliminate_actor"| TM
    AM -.->|"_execute: start_combat, select_unit,<br/>set_actor_ready, resolve_combat"| CM
    AM -.->|"check_move, move_spends_movement"| AS
    CM -.->|"add_combat_modifiers,<br/>after_combat_round"| AS

    LM -- "lander_spawned, landers_crashed" --> GS
    GS -- board_settled --> AI

    AM -- "action_resolved" --> P
    AM -- "action_resolved" --> AI
    AM -- "action_resolving<br/>(who owned a lander before a move)" --> P
    TM -- "game_phase_changed" --> P
    TM -- "game_phase_changed<br/>(→ _take_phase on its turn)" --> AI
    CM -- "combat_started<br/>(every battle: arrows)" --> P
    CM -- "combat_started<br/>(its own battles)" --> AI

    TM -- "game_state_changed, turn_order_generated,<br/>active_actor_changed, season_*,<br/>actor_eliminated, game_over (HUD)" --> P
    CM -- "combat_updated, combat_resolved,<br/>combat_ended (HUD)" --> P
    GR -- root_setup_finished --> TM
    GR -.->|"begin_setup() on every actor"| AI
```

Every actor listens to the same signals; the Player adds HUD-only ones, and listens to *every*
battle (not just its own) so the board can show who is attacking whom.

---

## 6. HUD and board markers

`UiManager` builds the HUD in code (`view/hud/`, styled by `HudTheme`). Every panel's
`action_requested` is connected up to `UiManager.action_requested`, so every button press leaves
the HUD as an `Action` (the Player stamps itself on it). The root ignores the mouse, so clicks on
empty screen reach the board.

```mermaid
flowchart TB
    UI[UiManager]
    UI --> TopBar["TopBar<br/>you · race (hover: traits) · wallet (hover: where income comes from)<br/>round · phases · next step"]
    UI --> PhaseHint["PhaseHint<br/>what to do now · why something was refused · alerts"]
    UI --> PlayersList["PlayersList<br/>colour · race · landers · units · out of the game"]
    UI --> LanderInspector["LanderInspector<br/>owner · upkeep · building + abilities · units (moved) · web · shop"]
    UI --> EventLog["EventLog<br/>what everyone did · ability notes"]
    UI --> SetupPanel["SetupPanel<br/>starting biomes · command tower"]
    UI --> MoveDialog["MoveDialog<br/>pick units (moved ones greyed) · capture / raze"]
    UI --> BattleDialog["BattleDialog<br/>rounds · dice with ability modifiers · Fight / Retreat / Move in"]
    UI --> GameOverPanel["GameOverPanel<br/>Victory / Defeat · Main menu · Keep looking · Play again"]
    LanderInspector --> ShopButton
    LanderInspector --> WebButtons["Spin a web here / Tear down the web"]
```

| Panel | Sends |
|---|---|
| `TopBar` next-step button | `PROGRESS_TURN` (End buying / End turn) |
| `SetupPanel` biome button | `setup_biome_selected` → the controller places on click (`PLACE_BIOME`) |
| `ShopButton` in the inspector | `PURCHASE` on that lander |
| Inspector web buttons | `ENWEB` (Spin a web here), `RAZE_WEB` (Tear down the web) |
| `MoveDialog` | `MOVE_UNITS` (with `building_fate` CAPTURE / RAZE for undefended enemy buildings) |
| `BattleDialog` | `SELECT` / `DESELECT_COMBAT_UNIT`, `DECLARE` / `WITHDRAW_COMBAT_READY`, `RETREAT_COMBAT` |

**On the board** (owned by the `PlayerController`):

| Node | Shows |
|---|---|
| `PlacementPreview` | The hex ghost tinted and labelled with the next lander's biome, where gravity will pull and snap it, the landers pulling on it and the ones it will connect to (the hex connection range); a drag ribbon while moving or attacking; a hover ring |
| `BoardMarkers` | A pulsing white ring on the lander in the side panel; an arrow from attacker to defender for every battle until it ends ("UNDER ATTACK!" when it's yours); short arrows for other players' moves ("Captured!" / "Razed!") |
| `Lander` itself | Its owner ring and label (unit count, owner, web turns left), and a web drawn over it while webbed |

---

## 7. The Action pipeline

Every change to the game state takes this route, whether a player, the AI or the game itself asked
for it.

```mermaid
flowchart TB
    Req["Actor.request_action(action)<br/>stamps the actor"] --> Q[("ActionManager queue")]
    Sys["Action.create_system(type)<br/>follow-ups the game queues itself"] --> Q
    Q --> V{"_validate(action)<br/>returns a reason or ''<br/>(abilities: check_move)"}
    V -- "reason" --> Rej["action_rejected(action, reason)"]
    V -- "ok" --> Pre["action_resolving(action)<br/>listeners may action.cancel(reason)"]
    Pre -- "cancelled" --> Rej
    Pre --> Ex["_execute(action)<br/>calls the managers"]
    Ex --> Post["action_resolved(action)<br/>state is already updated"]
    Ex -. "may queue follow-ups" .-> Q
    Post -. "listeners (AI)<br/>may request more" .-> Q
```

**What `_validate` checks**

| Action | Allowed when |
|---|---|
| `PLACE_BIOME` | Setup; the actor has placed fewer than `starting_biome_count`; the spot is inside the walls and clear |
| `PLACE_BUILDING` | Setup; it's the actor's command tower; the lander is one the actor placed in setup and has no building; the actor has no tower yet |
| `FINISH_SETUP` | System only; setup; every actor has a command tower |
| `PLACE_LANDER` | Main loop; actor's turn; `DUSTCLOUD_COLLAPSE`; the spot is inside the walls and clear |
| `PURCHASE` | Actor's turn; `BUYING`; actor owns the lander; the lander offers it (its building trains that unit type, or one of the actor's `can_build` units there can build it); affordable; room for a unit / no building yet; a unique building only once |
| `ENWEB` | Actor's turn; `BUYING`; the actor's race has `EnwebAbility`; the target isn't theirs, has no web, and is connected to a lander they own; affordable |
| `MOVE_UNITS` | Actor's turn; `COMBAT`; no combat running; landers connected; the actor's own units, on the source, none moved yet this turn; every ability's `check_move` agrees (Mountain Shy, webs); no enemy units on the target; room; an undefended enemy building needs `building_fate` CAPTURE or RAZE (a command tower can only be razed) |
| `RAZE_WEB` | Actor's turn; `COMBAT`; no combat running; the target has someone else's web; one of the actor's units on it that hasn't moved this turn (it spends its move) |
| `ATTACK` | Actor's turn; `COMBAT`; no combat running; landers connected; both have units (no defenders: move in instead); attacker owns its side, enemy on the other |
| `PROGRESS_TURN` | Main loop; actor's turn; not an admin phase; not `DUSTCLOUD_COLLAPSE` (that ends by placing a lander); no combat running. A system `PROGRESS_TURN` skips these checks |
| `SELECT` / `DESELECT_COMBAT_UNIT` | Combat choosing units; actor takes part; its own unit on its side's lander; within the unit limit |
| `DECLARE_COMBAT_READY` | Combat choosing units; actor takes part; at least one unit selected (if it has any) |
| `WITHDRAW_COMBAT_READY` | Combat choosing units; actor takes part |
| `RETREAT_COMBAT` | Combat choosing units; the actor is the attacker |
| `COLLECT_UPKEEP`, `RESOLVE_COMBAT`, `ELIMINATE_ACTOR` | System only |

**Follow-ups the game queues itself**

| After | Queued |
|---|---|
| `PLACE_BUILDING` (the command tower), once every actor has one | `FINISH_SETUP` |
| `FINISH_SETUP` or `PROGRESS_TURN` into `UPKEEP` | `COLLECT_UPKEEP` for the active actor: their units can move again, their webs age (and wear off), they get `upkeep_gold` (3) plus each owned lander's upkeep (biome + building); then system `PROGRESS_TURN` |
| `PROGRESS_TURN` into `CLEANUP` | system `PROGRESS_TURN` |
| `PLACE_LANDER` | system `PROGRESS_TURN` (placing the lander is the whole phase) |
| `MOVE_UNITS` that razes a command tower | `ELIMINATE_ACTOR` for its owner: their units, buildings and webs are removed and they leave the turn order. When one actor is left the game ends (`TurnManager.game_over`); with more left, play goes on |
| `DECLARE_COMBAT_READY` when both sides are ready | `RESOLVE_COMBAT`. If both sides still have units afterwards, the next round starts (survivors stay selected); otherwise the battle ends (`combat_ended`) |

---

## 8. Playthrough: menus, setup and two rounds

This traces a short game through the real code paths: the human `Player` and the default two
`SimpleAI`s (free-for-all). The turn order is shuffled at start; here the Player is assumed to go
first, and each AI plays its turn by itself when its turn comes. The diagrams show "SimpleAI" once;
every AI does the same.

**Phases each turn:** `UPKEEP → DUSTCLOUD_COLLAPSE → BUYING → COMBAT → CLEANUP`.
`UPKEEP` and `CLEANUP` are *admin phases*: the game passes through them with system actions.
After `CLEANUP` the next actor's `UPKEEP` starts. When play wraps back to the first actor, the round
number goes up and the season advances.

**Reading these diagrams:** every arrow into `ActionManager` is queued. "resolve" marks the moment the
queue gets to that action. Anything requested while an action is resolving waits its turn, so a long
chain runs one action at a time, in order. The AI paces itself: before each step it waits
`step_delay` and for `board_settled`.

### 8a. Menus, boot and setup

```mermaid
sequenceDiagram
    autonumber
    actor U as User
    participant MS as Start / MatchSetup screens
    participant GR as GameRoot
    participant UI as UiManager / panels
    participant PC as PlayerController
    participant P as Player
    participant AM as ActionManager
    participant TM as TurnManager
    participant LM as LanderManager
    participant GS as GravitySystem
    participant AI as SimpleAI (each)

    U->>MS: Play, pick a race and the number of AIs, Start match
    MS->>MS: MatchRequest.set_choices(species, opponents)
    MS->>GR: change_scene_to_file(main.tscn) → GameRoot._ready()
    GR->>GR: MatchRequest.opponent_count → MatchSettings.opponent_count
    GR->>P: _add_actor(Player, chosen species): colour, wallet, bind managers
    GR->>AI: _add_ai("SimpleAI", "SimpleAI 2", ...): random species, the same wiring
    GR->>GR: AbilitySystem.begin_match(actors) registers rules and race abilities
    GR-->>TM: root_setup_finished → start(): turn order, seasons, SETUP
    TM-->>P: turn_order_generated, active_actor_changed,<br/>season_order_generated, game_state_changed(SETUP)
    P->>UI: TopBar, PlayersList and SetupPanel show
    GR->>AI: begin_setup() → _take_setup(): paced steps

    par the AIs set up
        AI->>AM: PLACE_BIOME ×4, a cluster away from every lander already down
        AI->>AM: PLACE_BUILDING (command tower on its best-connected starting lander)
    and the Player sets up
        loop for each starting biome (4)
            U->>UI: pick a biome
            UI-->>PC: setup_biome_selected(biome_data)
            U->>PC: click the ground (the ghost shows the biome and where it will settle)
            PC-->>P: action_requested(PLACE_BIOME)
            P->>AM: request_action
            Note over AM: resolve PLACE_BIOME: setup, fewer than 4 placed, inside the walls, clear
            AM->>LM: spawn_biome_lander(action) (remembers who placed it)
            LM-->>GS: lander_spawned → pull, dock, snap face to face → board_settled
        end
        UI-->>PC: all_setup_biomes_placed (now placing the command tower)
        U->>PC: click one of your landers
        PC-->>P: action_requested(PLACE_BUILDING, command_tower)
        P->>AM: request_action
        Note over AM: resolve PLACE_BUILDING: your setup lander, no tower yet
    end

    Note over AM: once every actor has a command tower: resolve FINISH_SETUP
    AM->>TM: begin_main_loop()
    TM-->>P: game_state_changed(MAIN_LOOP), game_phase_changed(UPKEEP)
    Note over AM: resolve COLLECT_UPKEEP(Player): units refreshed, webs aged,<br/>+3 gold, + each owned lander's upkeep
    Note over AM: resolve PROGRESS_TURN (system) → DUSTCLOUD_COLLAPSE
```

### 8b. Round 1 (season 1)

```mermaid
sequenceDiagram
    autonumber
    actor U as User
    participant UI as UiManager / panels
    participant PC as PlayerController
    participant P as Player
    participant AM as ActionManager
    participant TM as TurnManager
    participant LM as LanderManager
    participant L as Lander
    participant AI as SimpleAI (each)

    rect rgba(80, 140, 255, 0.12)
    Note over U,AI: Player's turn: DUSTCLOUD_COLLAPSE
    TM-->>P: game_phase_changed → hint names the next biome (LanderManager.peek_next_biome)
    U->>PC: click a free spot (the ghost shows the biome, the pull and the snapped spot)
    PC-->>P: action_requested(PLACE_LANDER)
    P->>AM: request_action
    Note over AM: resolve PLACE_LANDER: your turn, right phase, inside the walls, clear
    AM->>LM: spawn_next_lander_for(Player, position) (the biome the preview showed)
    Note over AM: resolve PROGRESS_TURN (system) → BUYING
    end

    rect rgba(80, 200, 120, 0.12)
    Note over U,AI: Player's turn: BUYING
    U->>UI: click the command-tower lander, then a ShopButton in the LanderInspector
    UI-->>P: action_requested(PURCHASE, target_lander, UnitData)
    P->>AM: request_action
    Note over AM: resolve PURCHASE: owned lander offers it, affordable, not full
    AM->>L: wallet.subtract(cost), then buy_unit(action)
    AM-->>P: action_resolved(PURCHASE) → EventLog line, inspector and TopBar refresh
    opt an Ettercap player
        U->>UI: Spin a web here (on a lander next to yours)
        UI-->>P: action_requested(ENWEB, target_lander)
        Note over AM: resolve ENWEB → lander.set_web(WebInstance)
    end
    U->>UI: press End buying → PROGRESS_TURN → COMBAT
    end

    rect rgba(255, 170, 60, 0.12)
    Note over U,AI: Player's turn: COMBAT (move units)
    U->>PC: drag from your lander to a connected lander
    PC-->>UI: movement_ui_requested → MoveDialog.open() (units that moved are greyed)
    U->>UI: choose units, press Move
    UI-->>P: action_requested(MOVE_UNITS)
    P->>AM: request_action
    Note over AM: resolve MOVE_UNITS: connected, your unmoved units,<br/>abilities' check_move, target not hostile, room
    AM->>AM: has_moved = true (unless move_spends_movement says free)
    AM->>LM: move_units(action)
    U->>UI: press End turn
    UI-->>P: action_requested(PROGRESS_TURN)
    P->>AM: request_action
    end

    rect rgba(160, 160, 160, 0.15)
    Note over U,AI: One queued chain per AI turn, no more input needed
    Note over AM: resolve PROGRESS_TURN → CLEANUP → system PROGRESS_TURN → next actor's UPKEEP
    TM-->>P: active_actor_changed(SimpleAI), then game_phase_changed(UPKEEP)
    Note over AM: resolve COLLECT_UPKEEP(SimpleAI), then system PROGRESS_TURN → DUSTCLOUD_COLLAPSE
    TM-->>AI: _take_phase(DUSTCLOUD_COLLAPSE)
    AI->>AM: PLACE_LANDER next to a lander with spare units, heading for the nearest enemy
    TM-->>AI: _take_phase(BUYING)
    AI->>AM: PURCHASE units where the strongest are trained, at most one building,<br/>ENWEB on the strongest enemy force (Ettercap), then PROGRESS_TURN
    TM-->>AI: _take_phase(COMBAT)
    opt a weaker enemy neighbour (up to 2 attacks)
        AI->>AM: ATTACK → battle rounds (the Player defends through the BattleDialog)
    end
    AI->>AM: RAZE_WEB where it's stuck, then MOVE_UNITS: one spare unit into each<br/>empty neighbour (richest first), the rest to the frontier, then PROGRESS_TURN
    AM-->>P: action_resolved(MOVE_UNITS) → BoardMarkers: short arrow, alert if it took your lander
    Note over AM: the next AI plays the same way, then the round wraps
    TM-->>P: season_changed(1), active_actor_changed(Player), game_phase_changed(UPKEEP)
    end
```

### 8c. Round 2 (season 2)

```mermaid
sequenceDiagram
    autonumber
    actor U as User
    participant UI as UiManager / panels
    participant PC as PlayerController
    participant P as Player
    participant AM as ActionManager
    participant L as Lander
    participant CM as CombatManager
    participant AS as AbilitySystem
    participant C as Contest
    participant AI as SimpleAI (defender)

    rect rgba(80, 140, 255, 0.12)
    Note over U,AI: Player's turn: DUSTCLOUD_COLLAPSE and BUYING
    U->>PC: click a free spot → PLACE_LANDER → BUYING
    U->>UI: ShopButton (Build Castle Tower) on a lander with your builder units
    UI-->>P: action_requested(PURCHASE, target_lander, BuildingData)
    Note over AM: resolve PURCHASE → wallet.subtract(cost), lander.build(action)
    U->>UI: End buying → COMBAT
    end

    rect rgba(255, 90, 60, 0.12)
    Note over U,AI: Player's turn: COMBAT (attack an AI lander)
    U->>PC: drag from your lander to a connected AI lander
    PC-->>P: action_requested(ATTACK, source_lander, target_lander)
    P->>AM: request_action
    Note over AM: resolve ATTACK: your turn, COMBAT phase, connected, enemies
    AM->>CM: start_combat(action)
    CM->>C: Contest.new(attacker = source, defender = target)
    CM-->>P: combat_started → BoardMarkers arrow, BattleDialog.open()
    CM-->>AI: combat_started → _enter_combat
    AI->>AM: SELECT_COMBAT_UNIT ×(up to max), then DECLARE_COMBAT_READY

    loop for each unit the Player picks
        U->>UI: toggle a unit in the BattleDialog
        UI-->>P: action_requested(SELECT_COMBAT_UNIT)
        Note over AM: resolve: your own unit, on your lander, within the limit
    end

    U->>UI: press Fight
    UI-->>P: action_requested(DECLARE_COMBAT_READY)
    Note over AM: resolve: both ready, so RESOLVE_COMBAT is queued, then resolved
    AM->>CM: resolve_combat()
    CM->>CM: roll each unit's dice (CombatOutcome.roll_damage)
    CM->>AS: add_combat_modifiers(outcome, contest, side) for every unit
    AS-->>CM: e.g. +2 Castle Tower, +2 Combined Arms, +1 Lurkers, -1 Web
    CM->>CM: pair highest with highest (a tie goes to the defender), set opponents
    CM->>L: remove_units(dead) on both landers
    CM->>AS: after_combat_round(contest, outcomes)
    AS-->>C: last_notes, e.g. Pack Call: a Halfbreed joins an Alpha Werewolf that killed
    CM-->>P: combat_resolved(outcomes) → BattleDialog shows each pairing's dice and modifiers
    alt both sides still have units
        CM->>CM: next round: survivors stay selected, ready flags reset
        U->>UI: Fight again (or Retreat)
    else a side is wiped out (or retreat / stalemate)
        CM-->>P: combat_ended(contest) → arrow removed, result, Move in (if you won)
    end
    U->>UI: Close (or Move in → MoveDialog), then End turn
    end

    rect rgba(160, 160, 160, 0.15)
    Note over U,AI: CLEANUP → each AI plays its turn → round 3, season 3 → the Player's UPKEEP
    end
```

### What changed in the game state

| Moment | State changes (all through hooked setters) |
|---|---|
| Menus | `MatchRequest.player_species`, `MatchRequest.opponent_count` |
| Boot | Each actor: `species`, `color`, `wallet` (10 of each resource); `AbilitySystem` registers what's in play |
| Setup | Each actor: 4 biome landers (pulled and snapped together); a command tower `BuildingInstance` on one (now owned). No starting units. `game_state`: SETUP → MAIN_LOOP; first upkeep paid |
| R1 Dustcloud | +1 neutral lander of the previewed biome; the next one is rolled |
| R1 Buying | `wallet` −unit cost; `Lander.units` +1 `UnitInstance`; (Ettercap) `Lander.web` set |
| R1 Combat | `Lander.units` moved to the neighbour, which becomes Player-owned; the moved units' `has_moved` = true |
| R1 → R2 | `active_actor` Player → each AI → Player; each AI's upkeep, purchases and moves; `round_number` 2; `season_index` 1; the Player's upkeep clears `has_moved` and ages webs |
| R2 Buying | `wallet` −building cost; `Lander.building` = new `BuildingInstance` |
| R2 Combat | `CombatManager.contest` created; `Contest.units` / `ready` per side filled; each `CombatOutcome`'s rolls, labelled modifiers, opponent, total and reason set; dead units removed; Pack Call may add a unit; `Contest.last_notes` filled |

---

## 9. Who built what

The project has two authors: **you** (391 commits, March 2025 to April 2026) and **Claude** (49
commits, 8 to 9 November 2026, every one asked for by you; commits with a `Co-Authored-By: Claude`
line). You made the game and its first working version; Claude restructured it and built the later
features you asked for on top.

```mermaid
timeline
    title BsOW, commit history
    section You
        Mar 2025 : Godot project, world plane, camera gimbal : Blender imports and materials : raycast placement
        Jun - Jul 2025 : Terrain tiles that pull together (the first gravity) : game master, player and player controller : buildings on tiles
        Aug - Sep 2025 : Race, unit and building resources : lander info panel and shop buttons : buying units, moving, combat states
        Oct - Nov 2025 : A basic AI : AI starting landers
        Dec 2025 - Feb 2026 : Prototype rebuild - ActionManager, LanderManager, UiManager : biome resources, building shop : CombatManager, MatchSettings
        Mar - Apr 2026 : Combat outcome and combat UI : TurnManager, turn order and seasons : movement lines, market and wallet UI, automatic upkeep
    section Claude
        8 Nov 2026 : Accessor refactor and the AbilitySystem hook : one Action pipeline, rule checks, SimpleAI : Godot 4.7
        9 Nov 2026 : Physics gravity, hex board, walls : new HUD, multi-round battles, capture or raze : races, economy, one move per turn : abilities, free-for-all, menus, board markers : tests and docs
```

```mermaid
flowchart LR
    subgraph You["You"]
        direction TB
        Y1["The game: landers, races, dust cloud,<br/>seasons, gravity, buildings and units"]
        Y2["Art and assets: Blender meshes,<br/>materials, 198 textures, icons"]
        Y3["First versions of the architecture:<br/>managers, data resources, actors,<br/>camera gimbal, UI panels"]
        Y4["Direction: what to build next,<br/>play-testing, bug reports, design calls"]
    end

    subgraph Both["Overlap: you built it, Claude reworked it"]
        direction TB
        O1["ActionManager → one queued pipeline<br/>with every rule check"]
        O2["TurnManager (phases, seasons, turn order)<br/>→ batched signals, knock-outs"]
        O3["CombatManager and CombatOutcome<br/>→ multi-round battles, ability modifiers"]
        O4["Your gravity pull → physics gravity,<br/>docking, hex snapping"]
        O5["Landers and terrain → hexagons,<br/>owner rings, webs"]
        O6["Your UI panels → HUD built in code"]
        O7["Your basic AI → SimpleAI"]
        O8["Your plan that every value can be<br/>intercepted → the AbilitySystem and abilities"]
    end

    subgraph Claude["Claude"]
        direction TB
        C1["Accessor refactor and conventions"]
        C2["New content: Moon Den, Web Spire,<br/>Alpha Werewolf, Venom Spitter<br/>(placeholder meshes)"]
        C3["Abilities, menus, board markers,<br/>walls, economy numbers"]
        C4["Tests: smoke, free-for-all, menus<br/>and these docs"]
    end

    Y3 --> Both
    Y1 --> Both
    Y4 -. "asked for" .-> Claude
    Both --> Claude
```

**The numbers**

| | You | Claude |
|---|---|---|
| Commits | 391 | 49 (4 of them merges into `prototype`) |
| When | Mar 2025 – Apr 2026 (14 months) | 8 – 9 Nov 2026 (2 days) |
| Non-script files added (scenes, resources, art) | 239, including 198 textures | 20: ability `.tres` files, the new race content, menu and test scenes |
| Script lines, by last edit (`git blame`) | 719 of 9,673 | 8,954 of 9,673 |
| Scripts with lines from both of us | 28 of 60 | 28 of 60 |

The `git blame` line counts understate your part. Claude's first refactor renamed, moved and
re-typed almost every script, so a line you wrote and Claude re-indented now counts as Claude's.
The structure underneath (the managers, the data resources, Actor and Player, the turn and combat
flow) is yours: the refactor kept it and changed how values are read and written.

**How the work differs**

| | You | Claude |
|---|---|---|
| Starting point | An empty Godot project | A working prototype (yours) |
| Decided | What the game is, its rules and races, what to build next, how it should feel | How to build each request, the numbers (costs, gravity tuning), small rule fixes it flagged to you (e.g. the Mountain Shy exception) |
| Made | Art, assets, scenes, the first version of every core system | Restructuring, the rules engine, AI behaviour, new systems on request, tests, docs |
| Checked by | Playing it | The headless tests and screenshots, then your play-testing |

