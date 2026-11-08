# BsOW
Dev a digital version of a game for a friend and lols

## Layout

| Folder | What lives there |
|---|---|
| `data/` | Authored `Resource` definitions (`*Data`) and their `.tres` files, plus `MatchSettings` |
| `logic/classes/` | Runtime game objects: `Action`, `Actor`/`Player`/`SimpleAI`, `Lander`, `UnitInstance`, `Contest`, ... |
| `logic/managers_and_systems/` | Managers (`TurnManager`, `ActionManager`, ...), `GameRoot` wiring, and the `AbilitySystem` autoload |
| `view/hud/` | The HUD, built in code and styled by `HudTheme` (top bar, inspector, battle and move dialogs, log, ...) |
| `view/world/` | World-space hints (`PlacementPreview`) |
| `view/camera/` | The camera rig (WASD pan, Q/E rotate left/right, wheel zoom, middle-drag orbit) |
| `scenes/` | `player.tscn`, `lander.tscn`, building/unit meshes, reusable UI templates |
| `tests/` | Headless smoke test |

Naming and accessor rules: see [CONVENTIONS.md](CONVENTIONS.md).
Class diagrams and a two-round data-flow walkthrough: see [docs/diagrams.md](docs/diagrams.md).

## Action pipeline

Every game-state change is an `Action` sent to `ActionManager.request_action()`. Actions are queued
and resolved one at a time:

```
validate -> action_resolving (listeners may cancel) -> execute -> action_resolved
```

The Player (through its UI) and the AI (in code) both play through this pipeline. The game uses it
too, with system actions for upkeep, finishing setup, resolving combat and skipping admin phases.
`action_resolved` is the event stream that triggered and delayed abilities will listen to.

## Rules in brief

* **Winning:** every player has a command tower (the Base). Units moved onto an enemy lander with
  no defenders can capture or raze its building, but command towers can only be razed, and razing
  one knocks its owner out. The last player standing wins.
* **Races:** each race has a basic builder unit (trained at the Base or a Castle Tower), a race
  building, and an advanced unit that only its race building trains:

  | Race | Builder | Race building | Advanced unit |
  |---|---|---|---|
  | Lycanthrope | Lycanth Halfbreed | Moon Den | Alpha Werewolf (2d6) |
  | Ettercap | Ettercap spawn | Web Spire | Venom Spitter (1d10) |

* **Building:** only units with `can_build` can put a building on a lander that has none, and only
  the buildings in their `buildables` list. A building trains only the unit types in its
  `spawnable_unit_types`.
* **Battles** last several rounds, until a side is wiped out or the attacker retreats.

## Gravity

When a lander is placed, the `GravitySystem` turns it into a short-lived gravity well: it and every
lander within `gravity_range` attract each other (inverse square), so close-but-not-touching landers
pull together and connect. Landers are physics bodies (Jolt), so they slide and can crash
(`LanderManager.landers_crashed`). `board_settled` fires once everything has stopped; the AI and the
tests wait for it. The placement preview shows where a lander will end up.

## AbilitySystem hook

All gameplay state is read and written through `get_x()` / `set_x()` accessors that call
`AbilitySystem.resolve_get()` / `resolve_set()` (`logic/managers_and_systems/ability_system.gd`).
Today these return the original value unchanged; abilities will plug in there.

## Smoke test

```
godot --headless --path . res://tests/smoke_test.tscn
```

Plays through setup, a full player turn (place lander, buy, move, attack), the AI playing its own
turn in a prepared spot (it places, buys, attacks and claims a lander by itself), and a round wrap
with upkeep. It also checks that the rules reject out-of-turn and out-of-phase actions.
Exit code 0 means every check passed.
