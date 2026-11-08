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
        +int ai_starting_troops
        +int starting_biome_count
        +int starting_resource_amount
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
        +bind_turn_manager(m)
        +bind_lander_manager(m)
        +bind_combat_manager(m)
        #_enter_combat(contest)*
    }

    class Player {
        +action_requested(action) signal
        +combat_selection_requested(actor, thing, is_selected) signal
        +bind_draw_3d(d)
        +bind_match_settings(s)
    }

    class SimpleAI {
        +combat_unit_selected(unit) signal
        +combat_unit_deselected(unit) signal
        +combat_ready(actor) signal
        +combat_not_ready(actor) signal
    }

    class Lander {
        <<RigidBody3D>>
        +building_built(action) signal
        +unit_bought(action) signal
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
    }

    class ActionType {
        <<enumeration>>
        MOVE_UNITS
        ATTACK
        PURCHASE
        PLACE_LANDER
        PLACE_BUILDING
        BUY_UNIT
        PROGRESS_TURN
        PLACE_BIOME
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
        +build_approved(action) signal
        +unit_purchase_approved(action) signal
        +biome_placement_approved(action) signal
        +turn_progress_approved() signal
        +request_action(action)
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
        +finish_setup()
    }

    class LanderManager {
        +building_built(action) signal
        +unit_bought(action) signal
        +units_moved(action) signal
        +upkeep_completed() signal
        +Array~Lander~ landers
        +spawn_random_lander(pos) Lander
        +spawn_biome_lander(action) Lander
        +spawn_protected_lander(pos, owner, count)
        +get_connected_landers(lander) Array
        +get_landers_owned_by(actor) Array
        +build(action)
        +buy_unit(action)
        +move_units(action)
        +run_upkeep(actor)
    }

    class CombatManager {
        +combat_started(contest) signal
        +combat_updated(contest) signal
        +combat_resolved(outcomes) signal
        +Contest contest
        +max_units(side) int
        +max_abilities(side) int
        +start_combat(action)
        +request_selection(actor, thing, is_selected)
        +select_unit(unit)
        +deselect_unit(unit)
        +set_actor_ready(actor)
        +set_actor_not_ready(actor)
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

    ActionManager --> LanderManager
    ActionManager --> TurnManager
    ActionManager --> CombatManager
    CombatManager --> MatchSettings
    LanderManager "1" o-- "0..*" Lander

    Player *-- PlayerController
    Player *-- UiManager
    Player *-- SelectorManager
```

`EconManager` and `GravitySystem` exist as empty placeholders and aren't shown. `Draw3D` is a debug
drawing helper that `GameRoot` hands to the `Player`.

---

## 4. Scene tree and signal wiring

Solid arrows are signal connections, labelled with the signal name. `GameRoot._ready()` makes every
cross-object connection; `Player` connects its own children.

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
        UI -- "combat_unit_selected / deselected<br/>combat_ready / not_ready" --> P
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
    L[Lander]

    P -- "action_requested<br/>(actor stamped)" --> AM
    P -- combat_selection_requested --> CM

    AM -- build_approved --> LM
    AM -- build_approved --> GR
    AM -- unit_purchase_approved --> LM
    AM -- biome_placement_approved --> LM
    AM -- turn_progress_approved --> TM
    AM -- "biome_placement_approved<br/>build_approved" --> P
    AM -.->|"direct calls:<br/>spawn_random_lander, move_units"| LM
    AM -.->|"direct call:<br/>start_combat"| CM
    AM -.->|"direct calls (PURCHASE):<br/>wallet.subtract, lander.build / buy_unit"| L

    L -- "building_built<br/>unit_bought" --> LM
    LM -- "building_built<br/>unit_bought<br/>units_moved" --> P

    TM -- "game_state_changed<br/>game_phase_changed<br/>turn_order_generated<br/>active_actor_changed<br/>season_order_generated<br/>season_changed" --> P
    TM -- game_phase_changed --> GR
    GR -.->|"UPKEEP: run_upkeep(active actor)"| LM
    GR -.->|"first build in SETUP: finish_setup()"| TM
    GR -- root_setup_finished --> TM

    CM -- combat_started --> P
    CM -- combat_started --> AI
    CM -- "combat_updated<br/>combat_resolved" --> P
    AI -- "combat_unit_selected / deselected<br/>combat_ready / not_ready" --> CM
```

---

## 5. UI panels

`UiManager` owns the HUD. Each panel's `action_requested` is connected signal-to-signal up to
`UiManager.action_requested`, so every button press leaves the UI as an `Action`.

```mermaid
flowchart TB
    UI[UiManager]
    UI --> SetupPanel
    UI --> TurnPanel
    UI --> PlayersPanel
    UI --> SeasonsPanel
    UI --> WalletPanel
    UI --> PurchasePanel
    UI --> MovementPanel
    UI --> LanderPanel
    UI --> CombatPanel

    LanderPanel --> BuildingControl
    LanderPanel --> UnitControl
    LanderPanel --> LanderControl
    BuildingControl --> BuildingDetailsState
    BuildingControl --> BuildingShopState --> BuildingShopButton
    UnitControl --> UnitDetailsState
    UnitControl --> UnitShopState --> UnitShopButton
    LanderControl --> ConnectedLanderButton
    LanderControl --> UnitLanderButton

    CombatPanel --> OwnUnits["CombatUnitsPanel (own)"]
    CombatPanel --> OppUnits["CombatUnitsPanel (opponent)"]
    OwnUnits --> SelectedCombatUnitsDisplay
    OppUnits --> SelectedCombatUnitsDisplay
    CombatPanel --> SelectUnitsPanel --> SelectUnitButton
    CombatPanel --> SelectAbilityPanel
    CombatPanel --> AttackAbilityPanel
    CombatPanel --> DefendAbilityPanel
    CombatPanel --> FightButton

    SetupPanel -.->|"uses"| ListBox
    PurchasePanel -.->|"uses"| ListBox
    MovementPanel -.->|"uses"| ListBox
```

| Panel | Emits | Action / signal |
|---|---|---|
| `SetupPanel` | biome picked from the list | `setup_biome_selected` → controller waits for a click on the ground |
| `TurnPanel` | *Next* pressed | `PROGRESS_TURN` |
| `PurchasePanel` | market item pressed | `PURCHASE` (purchasable = `UnitData` or `BuildingData`) |
| `MovementPanel` | *Move* pressed | `MOVE_UNITS` |
| `BuildingShopButton` / `UnitShopButton` | shop item pressed | `PLACE_BUILDING` / `BUY_UNIT` |
| `CombatPanel` | unit chosen, *Fight* pressed | `combat_unit_selected`, `combat_ready` |

---

## 6. The Action pipeline

Every player request takes the same route. The controller and UI never set the actor; `Player` stamps
it, so the `ActionManager` always knows who asked.

```mermaid
flowchart LR
    Input["Mouse click /<br/>button press"] --> Create["Action.create(TYPE)<br/>+ set_* fields"]
    Create --> Emit["PlayerController or UiManager<br/>action_requested"]
    Emit --> Stamp["Player._on_child_action_requested<br/>action.set_actor(self)"]
    Stamp --> AM{"ActionManager.request_action<br/>match type"}

    AM -- PLACE_BIOME --> B1["valid placement?"] --> B2["biome_placement_approved<br/>→ LanderManager.spawn_biome_lander"]
    AM -- PLACE_BUILDING --> C1["lander has no building?"] --> C2["build_approved<br/>→ LanderManager.build → Lander.build"]
    AM -- PLACE_LANDER --> D1["valid placement?"] --> D2["spawn_random_lander<br/>+ turn_progress_approved"]
    AM -- PURCHASE --> E1["wallet.can_afford?"] --> E2["wallet.subtract<br/>Lander.build / Lander.buy_unit"]
    AM -- BUY_UNIT --> F1["building can spawn this unit type?"] --> F2["unit_purchase_approved<br/>→ LanderManager.buy_unit"]
    AM -- MOVE_UNITS --> G1["target not hostile?"] --> G2["LanderManager.move_units"]
    AM -- ATTACK --> H1["both sides have units,<br/>enemies, attacker owns units?"] --> H2["CombatManager.start_combat"]
    AM -- PROGRESS_TURN --> I1["not an admin phase?"] --> I2["turn_progress_approved<br/>→ TurnManager.progress_phase"]

    AM -.->|"any check fails"| R["_reject(): prints<br/>'ActionManager · Rejected TYPE · reason'"]
```

---

## 7. Playthrough: setup and two rounds

This traces a short game through the real code paths: one human `Player` and one `SimpleAI`. The turn
order is shuffled at start; here the Player is assumed to go first.

**Phases each turn:** `UPKEEP → DUSTCLOUD_COLLAPSE → BUYING → COMBAT → CLEANUP`.
`UPKEEP` and `CLEANUP` are *admin phases*: `TurnManager` announces them and moves on by itself.
After `CLEANUP` the next actor's `UPKEEP` starts. When play wraps back to the first actor, the round
number goes up and the season advances.

> **Current behaviour worth knowing:** `SimpleAI` only reacts to combat. It has no turn logic, so on
> its turn the human presses *Next* until play returns to them. Also, the very first main-loop turn
> starts at `DUSTCLOUD_COLLAPSE`: `finish_setup()` progresses out of the initial `UPKEEP` without
> announcing it, so no upkeep is paid on turn 1.

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
    GR->>P: instantiate player.tscn, set species + starting wallet, bind managers
    GR->>TM: register_actor(Player)
    GR->>AI: new SimpleAI, set species + wallet, bind managers
    GR->>LM: spawn_protected_lander(pos, AI, ai_starting_troops) ×N
    LM->>L: add_units(garrison of base_footsoldier units)
    GR->>TM: register_actor(AI)
    GR-->>TM: root_setup_finished → start()

    TM-->>P: turn_order_generated, active_actor_changed(Player)
    P->>UI: PlayersPanel shows turn order
    TM-->>P: season_order_generated
    P->>UI: SeasonsPanel shows seasons
    TM-->>P: game_state_changed(SETUP)
    P->>PC: state = SETUP
    P->>UI: SetupPanel lists starting biomes

    loop for each starting biome (starting_biome_count = 4)
        U->>UI: pick a biome
        UI-->>PC: setup_biome_selected(biome_data)
        U->>PC: click the ground
        PC-->>P: action_requested(PLACE_BIOME, position, biome_data)
        P->>P: action.set_actor(self)
        P-->>AM: action_requested → request_action
        AM-->>LM: biome_placement_approved → spawn_biome_lander
        AM-->>P: biome_placement_approved
        P->>UI: SetupPanel removes that biome
    end
    UI-->>PC: all_setup_biomes_placed (now placing the command tower)

    U->>PC: click one of your landers
    PC-->>P: action_requested(PLACE_BUILDING, target_lander, command_tower)
    P-->>AM: request_action
    AM-->>LM: build_approved → build(action)
    LM->>L: build(action) → BuildingInstance.new(command_tower, Player)
    L-->>P: building_built (through LanderManager)
    AM-->>GR: build_approved (still SETUP) → finish_setup()
    Note over TM: waits one frame
    TM-->>P: game_state_changed(MAIN_LOOP)
    P->>UI: SetupPanel hides, TurnPanel + WalletPanel show
    TM->>TM: progress_phase(): UPKEEP → DUSTCLOUD_COLLAPSE
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
    participant W as Player wallet (EconData)
    participant GR as GameRoot

    rect rgba(80, 140, 255, 0.12)
    Note over U,GR: Player's turn: DUSTCLOUD_COLLAPSE
    TM-->>P: game_phase_changed(DUSTCLOUD_COLLAPSE)
    P->>PC: state = COLLAPSING_DUSTCLOUD (draws a placement preview)
    U->>PC: click a free spot
    PC-->>P: action_requested(PLACE_LANDER, position)
    P-->>AM: request_action
    AM->>LM: spawn_random_lander(position)
    AM-->>TM: turn_progress_approved → progress_phase()
    Note right of TM: placing the lander ends the phase by itself
    end

    rect rgba(80, 200, 120, 0.12)
    Note over U,GR: Player's turn: BUYING
    TM-->>P: game_phase_changed(BUYING)
    P->>UI: PurchasePanel.open_market() lists landers with something to buy
    U->>UI: pick the command-tower lander, then a unit
    UI-->>P: action_requested(PURCHASE, source_lander, purchasable = UnitData)
    P-->>AM: request_action
    AM->>W: can_afford(unit cost)? → subtract(cost)
    W-->>UI: amounts_changed → WalletPanel.refresh()
    AM->>L: buy_unit(action)
    L->>L: add_units([UnitInstance.new(unit_data, Player)]) → set_units()
    L-->>P: unit_bought (through LanderManager) → refresh LanderPanel
    U->>UI: press Next
    UI-->>P: action_requested(PROGRESS_TURN)
    P-->>AM: request_action
    AM-->>TM: turn_progress_approved → progress_phase()
    end

    rect rgba(255, 170, 60, 0.12)
    Note over U,GR: Player's turn: COMBAT (move units)
    TM-->>P: game_phase_changed(COMBAT)
    P->>PC: state = MOVEMENT
    P->>UI: PurchasePanel hides
    U->>PC: drag from your lander to the connected new lander
    PC-->>UI: movement_ui_requested(from, to) → MovementPanel.open()
    U->>UI: choose units, press Move
    UI-->>P: action_requested(MOVE_UNITS, source, target, units)
    P-->>AM: request_action (target is neutral or yours)
    AM->>LM: move_units(action)
    LM->>L: source.remove_units / target.add_units
    LM-->>P: units_moved → UiManager.on_units_moved()
    U->>UI: press Next
    UI-->>P: action_requested(PROGRESS_TURN)
    P-->>AM: request_action
    AM-->>TM: turn_progress_approved → progress_phase()
    end

    rect rgba(160, 160, 160, 0.15)
    Note over U,GR: Hand-over: CLEANUP → AI's UPKEEP (both admin phases, automatic)
    TM-->>P: game_phase_changed(CLEANUP)
    TM->>TM: progress_phase(): wraps to UPKEEP, next actor
    TM-->>P: active_actor_changed(SimpleAI)
    P->>PC: is_active_player = false
    TM-->>GR: game_phase_changed(UPKEEP)
    GR->>LM: run_upkeep(SimpleAI): AI wallet += upkeep of each AI-owned lander
    TM->>TM: progress_phase(): UPKEEP → DUSTCLOUD_COLLAPSE
    end

    rect rgba(220, 80, 80, 0.10)
    Note over U,GR: SimpleAI's turn (no AI turn logic yet)
    loop DUSTCLOUD_COLLAPSE → BUYING → COMBAT → CLEANUP
        U->>UI: press Next
        UI-->>P: action_requested(PROGRESS_TURN)
        P-->>AM: request_action
        AM-->>TM: turn_progress_approved → progress_phase()
    end
    TM->>TM: wrap: round_number 1 → 2, season_index + 1
    TM-->>P: season_changed(1) → SeasonsPanel highlights the next season
    TM-->>P: active_actor_changed(Player)
    TM-->>GR: game_phase_changed(UPKEEP)
    GR->>LM: run_upkeep(Player)
    LM->>W: add(lander.get_upkeep()) for every Player-owned lander
    W-->>UI: amounts_changed → WalletPanel.refresh()
    TM->>TM: progress_phase(): UPKEEP → DUSTCLOUD_COLLAPSE
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
    participant TM as TurnManager
    participant L as Lander
    participant CM as CombatManager
    participant C as Contest
    participant AI as SimpleAI

    rect rgba(80, 140, 255, 0.12)
    Note over U,AI: Player's turn: DUSTCLOUD_COLLAPSE
    U->>PC: click a free spot
    PC-->>P: action_requested(PLACE_LANDER)
    P-->>AM: request_action → spawn lander, progress_phase()
    end

    rect rgba(80, 200, 120, 0.12)
    Note over U,AI: Player's turn: BUYING (a building this time)
    U->>UI: pick a lander, then a building
    UI-->>P: action_requested(PURCHASE, purchasable = BuildingData)
    P-->>AM: request_action
    AM->>AM: wallet.can_afford? and lander has no building?
    AM->>L: wallet.subtract(cost), then build(action)
    L->>L: BuildingInstance.new(building_data, Player), refresh_mesh()
    U->>UI: press Next → PROGRESS_TURN → progress_phase()
    end

    rect rgba(255, 90, 60, 0.12)
    Note over U,AI: Player's turn: COMBAT (attack an AI lander)
    U->>PC: drag from your lander to a connected AI lander
    PC-->>P: action_requested(ATTACK, source_lander, target_lander)
    P-->>AM: request_action
    AM->>AM: both landers have units, they're enemies, and the Player owns the attackers?
    AM->>CM: start_combat(action)
    CM->>C: Contest.new(attacker = source, defender = target)
    CM-->>P: combat_started(contest)
    P->>P: set_combat_side(ATTACKER), _enter_combat
    P->>UI: show_combat(contest) → CombatPanel.open()
    P->>PC: enter_combat() (state = COMBAT)
    CM-->>AI: combat_started(contest)
    AI->>AI: set_combat_side(DEFENDER), _enter_combat
    loop up to get_max_units(DEFENDER) times
        AI-->>CM: combat_unit_selected(random unit) → select_unit
        CM->>C: add_unit(DEFENDER, unit)
    end
    AI-->>CM: combat_ready(AI) → set_actor_ready → contest.set_ready(DEFENDER, true)

    loop for each unit the Player picks (up to get_max_units(ATTACKER))
        U->>UI: pick a unit in SelectUnitsPanel
        UI-->>P: combat_unit_selected(unit)
        P-->>CM: combat_selection_requested(Player, unit, true) → request_selection
        CM->>C: add_unit(ATTACKER, unit)
        CM-->>P: combat_updated(contest) → CombatPanel.refresh()
    end

    U->>UI: press Fight
    UI-->>P: combat_ready
    P-->>CM: combat_selection_requested(Player, true, true) → set_actor_ready
    CM->>C: set_ready(ATTACKER, true) → are_both_sides_ready() is true
    Note over CM: _run_damage_phase()
    CM->>CM: CombatOutcome.new(unit).roll_damage() for each selected unit,<br/>using unit.get_damage(): dice_count d dice_sides + modifier
    CM->>CM: sort each side highest first, then pair them up.<br/>Higher total wins, a tie goes to the defender.<br/>set_reason(COMBAT_WON / COMBAT_LOST) sets ALIVE / DEAD
    CM-->>P: combat_resolved(outcomes)
    P->>UI: show_combat_outcome → slots show each roll total
    P->>PC: exit_combat() (back to MOVEMENT)
    CM->>L: remove_units(dead) on the attacker and defender landers
    Note over CM: phase = CLEANUP
    U->>UI: Exit combat, then press Next → progress_phase()
    end

    rect rgba(160, 160, 160, 0.15)
    Note over U,AI: CLEANUP → AI UPKEEP → AI's turn (user presses Next ×4) → round 3, season 3
    end
```

### What changed in the game state

| Moment | State changes (all through hooked setters) |
|---|---|
| Boot | `Actor.species`, `Actor.wallet` (10 of each resource), AI garrison units on its landers |
| Setup | 4 biome landers placed; command tower `BuildingInstance` on one of them, so the Player owns it. `game_state`: SETUP → MAIN_LOOP |
| R1 Dustcloud | +1 neutral lander |
| R1 Buying | `wallet` −unit cost; `Lander.units` +1 `UnitInstance` |
| R1 Combat | `Lander.units` moved from the source lander to the target. The target becomes Player-owned because its units belong to the Player |
| R1 → R2 | `active_actor` Player → AI → Player; `round_number` 2; `season_index` 1; AI then Player `wallet` += biome upkeep |
| R2 Buying | `wallet` −building cost; `Lander.building` = new `BuildingInstance` |
| R2 Combat | `CombatManager.contest` created; `Contest.units` / `ready` per side filled; `CombatOutcome` totals and reasons set; dead units removed from both landers |
