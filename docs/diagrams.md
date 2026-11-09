# BsOW diagrams

Mermaid diagrams of the code on `CluadeRefactor`. GitHub renders them directly; in VS Code, install
the *Markdown Preview Mermaid Support* extension and open the Markdown preview.

**Reading the class diagrams:** every field listed on a `data/` or `logic/` class is read and written
through `get_x()` / `set_x()` (or `is_x()` / `has_x()` / `can_x()`), and those accessors go through
`AbilitySystem.resolve_get()` / `resolve_set()`. The accessors themselves are left out to keep the
diagrams small.

1. [Data resources](#1-data-resources-authored-templates)
2. [Runtime model](#2-runtime-model)
3. [Managers and actors](#3-managers-and-actors)
4. [Scene tree and signal wiring](#4-scene-tree-and-signal-wiring)
5. [UI panels](#5-ui-panels)
6. [The Action pipeline](#6-the-action-pipeline)
7. [Playthrough: setup and two rounds](#7-playthrough-setup-and-two-rounds)

---

## 1. Data resources (authored templates)

`*Data` classes are `Resource`s authored in the inspector and saved as `.tres`. They are shared by every
instance made from them, so an ability that should affect *one* unit hooks `UnitInstance`, not `UnitData`.

```mermaid
classDiagram
    direction LR

    class SpeciesData {
        +String display_name
        +Array~BuildingData~ buildings
        +Array~UnitData~ units
        +Array~BiomeData~ starting_biomes
        +BuildingData command_tower
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
        +PackedScene mesh_scene
        +Texture2D icon
        +bool is_unique
        +bool overrides_unit_capacity
        +int unit_capacity
        +bool can_spawn
        +Array~UnitType~ spawnable_unit_types
        +bool can_upgrade
        +Array~BuildingData~ upgrades
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
        +int opponent_count
        +int starting_biome_count
        +int starting_resource_amount
        +int upkeep_gold
        +Array~BiomeData~ game_biomes
        +int map_size
        +int max_attacker_units
        +int max_defender_units
        +int max_attacker_abilities
        +int max_defender_abilities
    }

    SpeciesData --> BuildingData : buildings, command_tower
    SpeciesData --> UnitData : units
    SpeciesData --> BiomeData : starting_biomes
    UnitData --> UnitData : base (inherits unset fields)
    UnitData --> UnitType
    UnitData --> DamageData : damage
    UnitData --> EconData : cost
    UnitData --> BuildingData : buildables
    BuildingData --> EconData : cost
    BuildingData --> BuildingData : upgrades
    BuildingData ..> UnitType : spawnable_unit_types
    BiomeData --> EconData : upkeep
    MatchSettings --> BiomeData : game_biomes
```

`EconData` plays two roles: a **price or income** (`UnitData.cost`, `BiomeData.upkeep`) and an actor's
**wallet**. `UnitData.base` is an inheritance chain: a `UnitData` that leaves a field empty falls back
to its `base`.

---

## 2. Runtime model

These objects exist while a match is running. `Action`, `Contest`, `CombatOutcome`, `UnitInstance` and
`BuildingInstance` are `RefCounted`: they free themselves when nothing references them.

```mermaid
classDiagram
    direction TB

    class Actor {
        <<Node>>
        +SpeciesData species
        +EconData wallet
        +int combat_side
        +action_requested(action) signal
        +request_action(action)
        +is_active_actor() bool
        +bind_action_manager(m)
        +bind_turn_manager(m)
        +bind_lander_manager(m)
        +bind_combat_manager(m)
        #_take_phase(phase)*
        #_game_phase_changed(phase)*
        #_enter_combat(contest)*
        #_action_resolved(action)*
    }

    class Player {
        +bind_draw_3d(d)
        +bind_match_settings(s)
        #acts through its UI, not _take_phase
    }

    class SimpleAI {
        +MAX_ATTACKS_PER_TURN
        #_take_phase(phase) places, buys, attacks, moves
        #_enter_combat(contest) picks strongest units, readies
        #_action_resolved(action) continues after its fights
        #_action_rejected(action, reason) falls back
    }

    class Lander {
        <<RigidBody3D>>
        +BiomeData biome_data
        +BuildingInstance building
        +Array~UnitInstance~ units
        +int unit_capacity
        +build(action)
        +buy_unit(action)
        +add_units(units)
        +remove_units(units)
        +get_owner_actor() Actor
        +get_upkeep() EconData
        +get_purchasables(actor) Array
        +is_full() bool
    }

    class UnitInstance {
        <<RefCounted>>
        +UnitData unit_data
        +Actor owner_actor
        +int hit_points
        +get_display_name() String
        +get_unit_type() UnitType
        +get_damage() DamageData
        +get_buildables() Array
    }

    class BuildingInstance {
        <<RefCounted>>
        +BuildingData building_data
        +Actor owner_actor
        +int hit_points
        +get_display_name() String
        +can_spawn_units() bool
        +get_spawnable_unit_types() Array
        +get_upgrades() Array
        +refresh_mesh()
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
        +UnitData unit_data
        +BiomeData biome_data
        +Resource purchasable
        +create(type)$ Action
        +create_system(type, actor)$ Action
        +is_system() bool
        +cancel(reason)
        +is_cancelled() bool
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
        FINISH_SETUP (system)
        COLLECT_UPKEEP (system)
        RESOLVE_COMBAT (system)
        ELIMINATE_ACTOR (system)
    }

    class Contest {
        <<RefCounted>>
        +lander(side) Lander
        +units(side) Array~UnitInstance~
        +ready(side) bool
        +get_actor(side) Actor
        +get_side_of(actor) int
        +is_involved(actor) bool
        +add_unit(side, unit)
        +remove_unit(side, unit)
        +are_both_sides_ready() bool
        +int round
        +Result result
        +get_available_units(side) Array
        +begin_next_round()
        +is_over() bool
        +get_opposite_side(side)$ int
    }

    class Side {
        <<enumeration>>
        ATTACKER
        DEFENDER
    }

    class CombatOutcome {
        <<RefCounted>>
        +UnitInstance unit
        +Array~int~ rolls
        +Array~int~ modifiers
        +int total
        +Outcome outcome
        +Reason reason
        +roll_damage()
        +calculate_total() int
    }

    Actor <|-- Player
    Actor <|-- SimpleAI
    Actor --> SpeciesData : species
    Actor --> EconData : wallet

    Lander --> BiomeData : biome_data
    Lander "1" o-- "0..1" BuildingInstance : building
    Lander "1" o-- "0..*" UnitInstance : units

    UnitInstance --> UnitData : unit_data
    UnitInstance --> Actor : owner_actor
    BuildingInstance --> BuildingData : building_data
    BuildingInstance --> Actor : owner_actor

    Action --> ActionType : type
    Action --> Actor : actor
    Action --> Lander : source / target
    Action --> UnitInstance : units

    Contest --> Side : keyed by
    Contest "1" --> "2" Lander : attacker / defender
    Contest --> UnitInstance : selected units
    CombatOutcome --> UnitInstance : unit
```

Notes:

* `PLACE_BUILDING` is only the free command tower at the end of setup. Everything else is bought
  with `PURCHASE`, on `target_lander`.
* *System* actions are made with `Action.create_system()` and can't be requested by an actor.
* A lander has **no owner field**. `get_owner_actor()` works it out: the building's owner, otherwise the
  first unit's owner, otherwise `null` (neutral). Abilities can still override it through the hook.
* `UnitInstance` getters such as `get_damage()` currently pass straight through to `UnitData`, but each
  one is hooked per instance. That's where buffs on a single unit go.
* The `CombatOutcome` enums are `Outcome {DEAD, ALIVE}` and
  `Reason {COMBAT_LOST, COMBAT_WON, ABILITY_SAVED, ABILITY_LOST, ABILITY_WON, NO_COMBAT}`.
  `set_reason()` also sets the matching `outcome`.

---

## 3. Managers and actors

```mermaid
classDiagram
    direction LR

    class GameRoot {
        <<Node3D>>
        +Array~SpeciesData~ game_species
        +root_setup_finished() signal
    }

    class ActionManager {
        +action_resolving(action) signal
        +action_resolved(action) signal
        +action_rejected(action, reason) signal
        +request_action(action)
        +is_resolving() bool
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
        +GameState game_state
        +Phase game_phase
        +Array~Actor~ turn_order
        +Actor active_actor
        +int round_number
        +Array~Season~ seasons
        +int season_index
        +register_actor(actor)
        +start()
        +progress_phase()
        +begin_main_loop()
    }

    class LanderManager {
        +Array~Lander~ landers
        +spawn_random_lander(pos) Lander
        +spawn_biome_lander(action) Lander
        +spawn_next_lander_for(actor, pos) Lander
        +peek_next_biome(actor) BiomeData
        +get_setup_landers_of(actor) Array
        +spawn_protected_lander(pos, owner, count) (tests)
        +lander_spawned(lander) signal
        +landers_crashed(a, b, speed) signal
        +get_connected_landers(lander) Array
        +get_landers_within(pos, radius) Array
        +get_landers_owned_by(actor) Array
        +move_units(action)
        +run_upkeep(actor)
    }

    class GravitySystem {
        +board_settled() signal
        +float gravity_range
        +float strength
        +float neighbour_share
        +is_settled() bool
        +predict_settle_position(spot) Vector3
        +get_pull_preview(spot) Dictionary
    }

    class CombatManager {
        +combat_started(contest) signal
        +combat_updated(contest) signal
        +combat_resolved(outcomes) signal
        +combat_ended(contest) signal
        +MAX_ROUNDS
        +Contest contest
        +max_units(side) int
        +max_abilities(side) int
        +start_combat(action)
        +select_unit(unit)
        +deselect_unit(unit)
        +set_actor_ready(actor, is_ready)
        +resolve_combat()
        +retreat()
        +is_selecting() bool
        +is_in_progress() bool
    }

    class AbilitySystem {
        <<autoload>>
        +resolve_get(target, property, base_value) Variant
        +resolve_set(target, property, current, new_value) Variant
    }

    class Player
    class PlayerController {
        <<Node3D>>
        +action_requested(action) signal
        +lander_selected(lander) signal
        +lander_view_requested(lander) signal
        +movement_ui_requested(from, to) signal
        +ControllerState state
        +apply_game_state(state)
        +apply_game_phase(phase)
        +apply_active_actor(actor)
        +enter_combat()
        +exit_combat()
    }
    class UiManager {
        <<Control>>
        +action_requested(action) signal
        +combat_unit_selected(unit) signal
        +combat_ready() signal
        +setup_biome_selected(biome) signal
        +all_setup_biomes_placed() signal
    }
    class SelectorManager {
        +Lander selected_lander
        +Lander target_lander
        +Array~UnitInstance~ selected_units
        +select_lander(lander)
    }

    GameRoot *-- ActionManager
    GameRoot *-- TurnManager
    GameRoot *-- LanderManager
    GameRoot *-- CombatManager
    GameRoot *-- MatchSettings
    GameRoot *-- Player : instantiates player.tscn
    GameRoot *-- SimpleAI : creates
    Actor <|-- Player
    Actor <|-- SimpleAI
    Actor --> ActionManager : action_requested

    ActionManager --> LanderManager
    ActionManager --> TurnManager
    ActionManager --> CombatManager
    CombatManager --> MatchSettings
    LanderManager "1" o-- "0..*" Lander

    Player *-- PlayerController
    Player *-- UiManager
    Player *-- SelectorManager
```

The managers only *execute*. All rule checks live in `ActionManager._validate()`, and the managers'
methods are called from `ActionManager._execute()`. `EconManager` and `GravitySystem` exist as empty
placeholders and aren't shown. `Draw3D` is a debug
drawing helper that `GameRoot` hands to the `Player`.

---

## 4. Scene tree and signal wiring

Solid arrows are signal connections, labelled with the signal name. Dotted arrows are direct calls.
`GameRoot._add_actor()` wires every actor the same way, and each actor connects its own manager
signals in its `bind_*()` methods.

```mermaid
flowchart LR
    subgraph PlayerNode["Player (player.tscn)"]
        direction TB
        PC[PlayerController]
        UI[UiManager + panels]
        SM[SelectorManager]
        P((Player))
        PC -- action_requested --> P
        UI -- action_requested --> P
        UI -- "combat_unit_selected / deselected<br/>combat_ready / not_ready<br/>(Player turns these into Actions)" --> P
        PC -- lander_selected --> SM
        PC -- "lander_view_requested<br/>movement_ui_requested" --> UI
        UI -- "setup_biome_selected<br/>all_setup_biomes_placed" --> PC
    end

    AI((SimpleAI))
    AM[ActionManager]
    TM[TurnManager]
    LM[LanderManager]
    CM[CombatManager]
    GR[GameRoot]

    P -- "action_requested<br/>(actor stamped)" --> AM
    AI -- "action_requested<br/>(actor stamped)" --> AM

    AM -.->|"_execute: spawn, move_units, run_upkeep,<br/>lander.build / buy_unit, wallet.subtract"| LM
    AM -.->|"_execute: progress_phase, begin_main_loop"| TM
    AM -.->|"_execute: start_combat, select_unit,<br/>set_actor_ready, resolve_combat"| CM

    AM -- "action_resolved" --> P
    AM -- "action_resolved" --> AI
    TM -- "game_phase_changed" --> P
    TM -- "game_phase_changed<br/>(→ _take_phase on its turn)" --> AI
    CM -- combat_started --> P
    CM -- combat_started --> AI

    TM -- "game_state_changed, turn_order_generated,<br/>active_actor_changed, season_*<br/>(HUD only)" --> P
    CM -- "combat_updated, combat_resolved<br/>(HUD only)" --> P
    GR -- root_setup_finished --> TM
```

Compared to before the fixes, the wiring went from about 30 hand-made connections in `GameRoot` to one
per actor (`action_requested`). The signals each actor listens to are the same for the Player and the
AI, apart from the Player's extra HUD-only signals.

---

## 5. HUD

`UiManager` builds the HUD in code (`view/hud/`, styled by `HudTheme`). Every panel's
`action_requested` is connected up to `UiManager.action_requested`, so every button press leaves
the HUD as an `Action` (the Player stamps itself on it). The root ignores the mouse, so clicks on
empty screen reach the board.

```mermaid
flowchart TB
    UI[UiManager]
    UI --> TopBar["TopBar<br/>you · race · wallet (+income) · round · phases · next step"]
    UI --> PhaseHint["PhaseHint<br/>what to do now · why something was refused"]
    UI --> PlayersList["PlayersList<br/>colour · race · landers · units"]
    UI --> LanderInspector["LanderInspector<br/>owner · upkeep · building · units · shop"]
    UI --> EventLog["EventLog<br/>what everyone did"]
    UI --> SetupPanel["SetupPanel<br/>starting biomes · command tower"]
    UI --> MoveDialog["MoveDialog<br/>pick units · capture / raze"]
    UI --> BattleDialog["BattleDialog<br/>rounds · dice · Fight / Retreat / Move in"]
    LanderInspector --> ShopButton
```

| Panel | Sends |
|---|---|
| `TopBar` next-step button | `PROGRESS_TURN` (End buying / End turn) |
| `SetupPanel` biome button | `setup_biome_selected` → the controller places on click (`PLACE_BIOME`) |
| `ShopButton` in the inspector | `PURCHASE` on that lander |
| `MoveDialog` | `MOVE_UNITS` (with `building_fate` CAPTURE / RAZE for undefended enemy buildings) |
| `BattleDialog` | `SELECT` / `DESELECT_COMBAT_UNIT`, `DECLARE` / `WITHDRAW_COMBAT_READY`, `RETREAT_COMBAT` |

On the board, the `PlayerController` handles clicks (select a lander; drag to move or attack;
place landers) and draws the `PlacementPreview`: the ghost lander, where gravity will pull it,
the landers pulling on it and the ones it will connect to.

---

## 6. The Action pipeline

Every change to the game state takes this route, whether a player, the AI or the game itself asked
for it.

```mermaid
flowchart TB
    Req["Actor.request_action(action)<br/>stamps the actor"] --> Q[("ActionManager queue")]
    Sys["Action.create_system(type)<br/>follow-ups the game queues itself"] --> Q
    Q --> V{"_validate(action)<br/>returns a reason or ''"}
    V -- "reason" --> Rej["action_rejected(action, reason)"]
    V -- "ok" --> Pre["action_resolving(action)<br/>listeners may action.cancel(reason)"]
    Pre -- "cancelled" --> Rej
    Pre --> Ex["_execute(action)<br/>calls the managers"]
    Ex --> Post["action_resolved(action)<br/>state is already updated"]
    Ex -. "may queue follow-ups" .-> Q
    Post -. "listeners (AI, abilities)<br/>may request more" .-> Q
```

**What `_validate` checks**

| Action | Allowed when |
|---|---|
| `PLACE_BIOME` | Setup; the actor has placed fewer than `starting_biome_count`; the position is clear |
| `PLACE_BUILDING` | Setup; it's the actor's command tower; the lander is one the actor placed in setup and has no building; the actor has no tower yet |
| `PLACE_LANDER` | Main loop; actor's turn; `DUSTCLOUD_COLLAPSE`; the position is clear |
| `PURCHASE` | Actor's turn; `BUYING`; actor owns the lander; the lander offers it (its building trains that unit type, or one of the actor's `can_build` units there can build it); affordable; room for a unit / no building yet; a unique building only once |
| `MOVE_UNITS` | Actor's turn; `COMBAT`; no combat running; landers connected; actor's own units, on the source; no enemy units on the target; room; an undefended enemy building needs `building_fate` CAPTURE or RAZE (a command tower can only be razed) |
| `ATTACK` | Actor's turn; `COMBAT`; no combat running; landers connected; both have units (no defenders: move in instead); attacker owns its side, enemy on the other |
| `PROGRESS_TURN` | Main loop; actor's turn; not an admin phase; not `DUSTCLOUD_COLLAPSE` (that ends by placing a lander); no combat running. A system `PROGRESS_TURN` skips these checks |
| `SELECT` / `DESELECT_COMBAT_UNIT` | Combat choosing units; actor takes part; its own unit on its side's lander; within the unit limit |
| `DECLARE_COMBAT_READY` | Combat choosing units; actor takes part; at least one unit selected (if it has any) |
| `WITHDRAW_COMBAT_READY` | Combat choosing units; actor takes part |
| `RETREAT_COMBAT` | Combat choosing units; the actor is the attacker |
| `FINISH_SETUP`, `COLLECT_UPKEEP`, `RESOLVE_COMBAT`, `ELIMINATE_ACTOR` | System only |

**Follow-ups the game queues itself**

| After | Queued |
|---|---|
| `PLACE_BUILDING` (the command tower) | `FINISH_SETUP` |
| `FINISH_SETUP` or `PROGRESS_TURN` into `UPKEEP` | `COLLECT_UPKEEP` for the active actor (`upkeep_gold` plus each owned lander's upkeep), then system `PROGRESS_TURN` |
| `PROGRESS_TURN` into `CLEANUP` | system `PROGRESS_TURN` |
| `PLACE_LANDER` | system `PROGRESS_TURN` (placing the lander is the whole phase) |
| `MOVE_UNITS` that razes a command tower | `ELIMINATE_ACTOR` for its owner: their units and buildings are removed, they leave the turn order, and if one actor is left the game ends (`TurnManager.game_over`) |
| `DECLARE_COMBAT_READY` when both sides are ready | `RESOLVE_COMBAT`. If both sides still have units afterwards, the next round starts (survivors stay selected); otherwise the battle ends (`combat_ended`) |

---

## 7. Playthrough: setup and two rounds

This traces a short game through the real code paths: one human `Player` and one `SimpleAI`. The turn
order is shuffled at start; here the Player is assumed to go first. If the AI goes first, it plays its
turn by itself straight after setup.

**Phases each turn:** `UPKEEP → DUSTCLOUD_COLLAPSE → BUYING → COMBAT → CLEANUP`.
`UPKEEP` and `CLEANUP` are *admin phases*: the game passes through them with system actions.
After `CLEANUP` the next actor's `UPKEEP` starts. When play wraps back to the first actor, the round
number goes up and the season advances.

**Reading these diagrams:** every arrow into `ActionManager` is queued. "resolve" marks the moment the
queue gets to that action. Anything requested while an action is resolving waits its turn, so a long
chain (like the AI's whole turn) runs one action at a time, in order.

### 7a. Boot and setup

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
    participant GR as GameRoot
    participant AI as SimpleAI

    Note over GR: main.tscn loads → GameRoot._ready()
    GR->>LM: spawn_random_lander(origin)
    GR->>P: _add_actor(Player): species, wallet, bind managers, action_requested → AM
    GR->>AI: _add_actor(SimpleAI): the same
    GR-->>TM: root_setup_finished → start()
    GR->>AI: begin_setup() → paced steps: PLACE_BIOME ×4 in a cluster away from others,<br/>then PLACE_BUILDING (command tower), the same actions the Player sends below
    Note over TM: one batch, announced in order
    TM-->>P: turn_order_generated, active_actor_changed(Player),<br/>season_order_generated, game_state_changed(SETUP)
    P->>UI: TopBar, PlayersList and SetupPanel show

    loop for each starting biome (starting_biome_count = 4)
        U->>UI: pick a biome
        UI-->>PC: setup_biome_selected(biome_data)
        U->>PC: click the ground
        PC-->>P: action_requested(PLACE_BIOME)
        P->>AM: request_action (actor = Player)
        Note over AM: resolve PLACE_BIOME: setup, position clear
        AM->>LM: spawn_biome_lander(action)
        AM-->>P: action_resolved(PLACE_BIOME) → SetupPanel removes that biome
    end
    UI-->>PC: all_setup_biomes_placed (now placing the command tower)

    U->>PC: click one of your landers
    PC-->>P: action_requested(PLACE_BUILDING, command_tower)
    P->>AM: request_action
    Note over AM: resolve PLACE_BUILDING: setup, command tower, one of your setup landers, no tower yet
    AM->>L: build(action) → BuildingInstance(command_tower, Player)
    AM-->>P: action_resolved(PLACE_BUILDING) → controller leaves setup mode
    Note over AM: resolve FINISH_SETUP (queued once every actor has a command tower)
    AM->>TM: begin_main_loop()
    TM-->>P: game_state_changed(MAIN_LOOP), game_phase_changed(UPKEEP)
    Note over AM: resolve COLLECT_UPKEEP(Player)
    AM->>AM: wallet gold += MatchSettings.upkeep_gold (2)
    AM->>LM: run_upkeep(Player): wallet += upkeep of each owned lander
    Note over AM: resolve PROGRESS_TURN (system)
    AM->>TM: progress_phase() → DUSTCLOUD_COLLAPSE
```

### 7b. Round 1 (season 1)

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
    participant AI as SimpleAI

    rect rgba(80, 140, 255, 0.12)
    Note over U,AI: Player's turn: DUSTCLOUD_COLLAPSE
    TM-->>P: game_phase_changed → controller places with a preview
    U->>PC: click a free spot
    PC-->>P: action_requested(PLACE_LANDER)
    P->>AM: request_action
    Note over AM: resolve PLACE_LANDER: your turn, right phase, clear spot
    AM->>LM: spawn_random_lander(position)
    Note over AM: resolve PROGRESS_TURN (system) → BUYING
    end

    rect rgba(80, 200, 120, 0.12)
    Note over U,AI: Player's turn: BUYING
    TM-->>P: game_phase_changed(BUYING) → hint: click a lander to buy
    U->>UI: click the command-tower lander, then a ShopButton in the LanderInspector
    UI-->>P: action_requested(PURCHASE, target_lander, UnitData)
    P->>AM: request_action
    Note over AM: resolve PURCHASE: owned lander offers it, affordable, not full
    AM->>L: wallet.subtract(cost), then buy_unit(action)
    AM-->>P: action_resolved(PURCHASE) → EventLog line, inspector and TopBar wallet refresh
    U->>UI: press Next
    UI-->>P: action_requested(PROGRESS_TURN)
    P->>AM: request_action → resolve → COMBAT
    end

    rect rgba(255, 170, 60, 0.12)
    Note over U,AI: Player's turn: COMBAT (move units)
    U->>PC: drag from your lander to the connected new lander
    PC-->>UI: movement_ui_requested → MoveDialog.open()
    U->>UI: choose units, press Move
    UI-->>P: action_requested(MOVE_UNITS)
    P->>AM: request_action
    Note over AM: resolve MOVE_UNITS: connected, your units, target not hostile, room
    AM->>LM: move_units(action)
    AM-->>P: action_resolved(MOVE_UNITS) → UiManager.on_units_moved()
    U->>UI: press Next
    UI-->>P: action_requested(PROGRESS_TURN)
    P->>AM: request_action
    end

    rect rgba(160, 160, 160, 0.15)
    Note over U,AI: One queued chain from here, no more input needed
    Note over AM: resolve PROGRESS_TURN (Player) → CLEANUP
    Note over AM: resolve PROGRESS_TURN (system) → wraps to the AI's UPKEEP
    TM-->>P: active_actor_changed(SimpleAI), then game_phase_changed(UPKEEP)
    Note over AM: resolve COLLECT_UPKEEP(SimpleAI)
    Note over AM: resolve PROGRESS_TURN (system) → DUSTCLOUD_COLLAPSE
    TM-->>AI: game_phase_changed → _take_phase(DUSTCLOUD_COLLAPSE)
    AI->>AM: PLACE_LANDER next to its own lander nearest an enemy (queued)
    Note over AM: resolve PLACE_LANDER, then system PROGRESS_TURN → BUYING
    TM-->>AI: _take_phase(BUYING)
    AI->>AM: PURCHASE a spawning building (landers without one) or the best units, then PROGRESS_TURN
    Note over AM: resolve each → COMBAT
    TM-->>AI: _take_phase(COMBAT)
    opt a weaker enemy neighbour (up to 2 attacks)
        AI->>AM: ATTACK
        Note over AM: resolve ATTACK → combat_started → both sides pick and ready<br/>(the Player defends through the combat UI)
        Note over AM: resolve RESOLVE_COMBAT → AI._action_resolved → next step
    end
    AI->>AM: MOVE_UNITS (claim empty neighbours, march spare units towards the enemy), then PROGRESS_TURN
    Note over AM: resolve → CLEANUP, then system PROGRESS_TURN wraps the round
    TM-->>P: season_changed(1), active_actor_changed(Player), game_phase_changed(UPKEEP)
    Note over AM: resolve COLLECT_UPKEEP(Player), then system PROGRESS_TURN → DUSTCLOUD_COLLAPSE
    end
```

### 7c. Round 2 (season 2)

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
    participant C as Contest
    participant AI as SimpleAI

    rect rgba(80, 140, 255, 0.12)
    Note over U,AI: Player's turn: DUSTCLOUD_COLLAPSE
    U->>PC: click a free spot
    PC-->>P: action_requested(PLACE_LANDER)
    P->>AM: request_action → spawn lander, system PROGRESS_TURN → BUYING
    end

    rect rgba(80, 200, 120, 0.12)
    Note over U,AI: Player's turn: BUYING (a building, from the lander panel's shop)
    U->>UI: ShopButton (Build Castle Tower) in the LanderInspector
    UI-->>P: action_requested(PURCHASE, target_lander, BuildingData)
    P->>AM: request_action
    Note over AM: resolve PURCHASE: same checks and cost as the market
    AM->>L: wallet.subtract(cost), then build(action)
    U->>UI: press Next → PROGRESS_TURN → COMBAT
    end

    rect rgba(255, 90, 60, 0.12)
    Note over U,AI: Player's turn: COMBAT (attack an AI lander)
    U->>PC: drag from your lander to a connected AI lander
    PC-->>P: action_requested(ATTACK, source_lander, target_lander)
    P->>AM: request_action
    Note over AM: resolve ATTACK: your turn, COMBAT phase, connected, enemies
    AM->>CM: start_combat(action)
    CM->>C: Contest.new(attacker = source, defender = target)
    CM-->>P: combat_started → _enter_combat → BattleDialog.open() (picks your strongest units)
    CM-->>AI: combat_started → _enter_combat
    AI->>AM: SELECT_COMBAT_UNIT ×(up to max), then DECLARE_COMBAT_READY (queued)
    Note over AM: resolve each AI pick
    AM->>CM: select_unit / set_actor_ready(AI, true)
    CM-->>P: combat_updated → BattleDialog.refresh()

    loop for each unit the Player picks
        U->>UI: toggle a unit in the BattleDialog
        UI-->>P: combat_unit_selected(unit)
        P->>AM: request_action(SELECT_COMBAT_UNIT, units = [unit])
        Note over AM: resolve: your own unit, on your lander, within the limit
        AM->>CM: select_unit(unit) → combat_updated
    end

    U->>UI: press Fight
    UI-->>P: combat_ready
    P->>AM: request_action(DECLARE_COMBAT_READY)
    Note over AM: resolve: set_actor_ready(Player, true). Both ready, so RESOLVE_COMBAT is queued
    Note over AM: resolve RESOLVE_COMBAT (system)
    AM->>CM: resolve_combat()
    CM->>CM: roll each unit's damage (unit.get_damage()),<br/>pair highest with highest, a tie goes to the defender
    CM->>L: remove_units(dead) on both landers
    CM-->>P: combat_resolved(outcomes) → BattleDialog shows each pairing's dice
    alt both sides still have units
        CM->>CM: next round: survivors stay selected, ready flags reset
        U->>UI: Fight! again (or Retreat)
    else a side is wiped out (or retreat / stalemate)
        CM-->>P: combat_ended(contest) → result, Move in (if you won), controller back to MOVEMENT
    end
    U->>UI: Close (or Move in → MoveDialog), then End turn
    end

    rect rgba(160, 160, 160, 0.15)
    Note over U,AI: CLEANUP → the AI plays its turn by itself → round 3, season 3 → player's UPKEEP
    end
```

### What changed in the game state

| Moment | State changes (all through hooked setters) |
|---|---|
| Boot | `Actor.species`, `Actor.wallet` (10 of each resource) |
| Setup | Each actor: 4 biome landers; command tower `BuildingInstance` on one of them (now owned). No starting units. `game_state`: SETUP → MAIN_LOOP; first upkeep paid |
| R1 Dustcloud | +1 neutral lander |
| R1 Buying | `wallet` −unit cost; `Lander.units` +1 `UnitInstance` |
| R1 Combat | `Lander.units` moved to the neighbour, which becomes Player-owned |
| R1 → R2 | `active_actor` Player → AI → Player; AI upkeep, AI purchases (if any); `round_number` 2; `season_index` 1; Player upkeep |
| R2 Buying | `wallet` −building cost; `Lander.building` = new `BuildingInstance` |
| R2 Combat | `CombatManager.contest` created; `Contest.units` / `ready` per side filled; `CombatOutcome` totals and reasons set; dead units removed from both landers |
