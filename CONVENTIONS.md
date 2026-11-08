# BsOW code conventions

These rules exist so that names tell you *what kind of thing* you are holding, and so
that every piece of gameplay state can be intercepted by the `AbilitySystem`.

## 1. Accessors (getters / setters)

Gameplay state is private and read/written through accessors.

```gdscript
var _hit_points: int = 1                     # private backing field

func get_hit_points() -> int:
	return AbilitySystem.resolve_get(self, &"hit_points", _hit_points)

func set_hit_points(value: int) -> void:
	_hit_points = AbilitySystem.resolve_set(self, &"hit_points", _hit_points, value)
```

* Backing field: `_snake_case`. Accessors: `get_x()` / `set_x(value)`.
* The `&"name"` passed to the AbilitySystem is the accessor name without `get_`/`set_`.
* Booleans use a question-style getter: `is_x()`, `has_x()`, `can_x()` (setter is still `set_x()`).
  GDScript forbids a variable and a function sharing a name, so a public bool export such as
  `can_spawn` gets a slightly longer getter (`can_spawn_units()`); the AbilitySystem key stays `&"can_spawn"`.
* Per-side values in combat take a `side` argument (`contest.get_units(side)`) instead of
  attacker/defender copies. `side` is typed `int` and holds a `Contest.Side` value.
* Collections: `get_units()`, `add_unit()`, `remove_unit()`, `clear_units()`.
  Add/remove build a new array and write it through `set_units()`, so there is only one write path.
* Inside a class, prefer the accessor over the field too. Use the raw `_field` only inside the
  accessor itself (or when deliberately bypassing abilities, with a comment saying why).
* **Hooked** (goes through `AbilitySystem`): gameplay values in `data/` resources and in
  `logic/` model classes and managers (units, landers, wallets, contests, turn/phase state, combat limits).
* **Not hooked** (plain accessor or private field): node references, injected dependencies,
  and view-only state in `view/`.
* `@export` variables in `data/` resources are the *authored base values*. They keep public names
  so the inspector and `.tres` files work, but code reads them through their getter.

## 2. Names that mean one thing

| Suffix / word | Means | Example |
|---|---|---|
| `*Data` | An authored `Resource` template, shared by everything that uses it | `UnitData`, `BuildingData`, `BiomeData` |
| `*Instance` | A runtime object created from a `*Data` | `UnitInstance`, `BuildingInstance` |
| `unit` / `building` | A runtime instance variable | `var unit: UnitInstance` |
| `unit_data` / `building_data` / `biome_data` | A `*Data` variable | `var unit_data: UnitData` |
| `*_type` | **Only** an enum value, never a resource | `UnitData.UnitType`, `Action.Type` |
| `action` | An `Action` request object | `func request_action(action: Action)` |
| `owner_actor` | The `Actor` that owns something (`owner` is taken by `Node`) | `lander.get_owner_actor()` |
| `player` | The local `Player` a UI/controller belongs to | `bind_player(player)` |
| `attacker` / `defender` | The two sides of a `Contest` (not invading/contested) | `contest.get_attacker_units()` |
| `source_lander` / `target_lander` | Where an action comes from / goes to | `action.get_source_lander()` |
| `display_name` | Text shown to players (`name` is taken by `Node`) | `unit_data.get_display_name()` |

Write words out in full: `remove` not `rmv`, `button` not `btn`, `ability` not `ablt`,
`lander` not `lnd`, `owner` not `ownr`, `color` (American spelling, matching Godot).

## 3. Files, classes, scenes

* Files and folders: `snake_case` (`unit_instance.gd`, `selected_combat_units_display.tscn`).
* `class_name`: `PascalCase`, same words as the file (`unit_instance.gd` -> `UnitInstance`).
* Every manager has its own `class_name` (`TurnManager`, `LanderManager`, ...) so references are typed.
* Constants and enum values: `UPPER_SNAKE_CASE`. Enum types: `PascalCase`.
* Node names in scenes stay `PascalCase` (Godot default); `find_child()` looks them up by that name.

## 4. Signals and methods

* Events: past tense — `biome_placed`, `game_phase_changed`, `combat_started`.
* Requests travelling up towards the `ActionManager`: one `action_requested(action: Action)` signal.
  Other UI requests use `<thing>_requested` (`lander_view_requested`).
* Pure pass-through of a child's signal: connect signal to signal
  (`child.action_requested.connect(action_requested.emit)`) instead of writing a `fwd_` function.
* Signal handlers: `_on_<source>_<signal>()` (`_on_turn_manager_game_phase_changed`).
* Dependency injection: `bind_<thing>(thing)`, called before the node enters the tree when possible.
* Methods a parent calls on a child: imperative verbs (`refresh()`, `show_combat(contest)`).

## 5. Changing the game state: Actions

* Every change to the game state is an `Action` resolved by the `ActionManager`. Nothing else
  changes landers, wallets, turns or combat on its own initiative.
* Actors call `request_action(action)`, which stamps the actor and emits `action_requested`.
  The game's own steps (upkeep, finishing setup, resolving combat, skipping admin phases) are
  *system* actions made with `Action.create_system()`, which actors can't request.
* Rules go in `ActionManager._validate()` (return a reason string, `""` when allowed). The changes
  go in `_execute()`, which calls the managers. Managers don't check rules.
* Requests made while an action is resolving are queued, not run immediately. A follow-up step is
  queued (`_queue_system_action`), never called directly.
* To react to what happened, listen to `action_resolved` (or override `Actor._action_resolved`).
  To stop or change something before it happens, listen to `action_resolving` and call
  `action.cancel(reason)`.
* Player and AI are wired the same way (`GameRoot._add_actor`). An AI acts in `_take_phase(phase)`;
  the Player acts through its UI. Both end their phases with `PROGRESS_TURN`.

## 6. Script layout

Use the order in `script_templates/Node/project_default.gd` (it appears in Godot's
*New Script* dialog): signals, enums, constants, exports, public state, private state,
`@onready`, built-ins, public API, accessors, signal handlers, private helpers.
