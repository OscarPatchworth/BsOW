# BsOW
Dev a digital version of a game for a friend and lols

## Layout

| Folder | What lives there |
|---|---|
| `data/` | Authored `Resource` definitions (`*Data`) and their `.tres` files, plus `MatchSettings` |
| `logic/classes/` | Runtime game objects: `Action`, `Actor`/`Player`/`SimpleAI`, `Lander`, `UnitInstance`, `Contest`, ... |
| `logic/managers_and_systems/` | Managers (`TurnManager`, `ActionManager`, ...), `GameRoot` wiring, and the `AbilitySystem` autoload |
| `view/` | HUD panels, buttons and the camera rig |
| `scenes/` | `player.tscn`, `lander.tscn`, building/unit meshes, reusable UI templates |
| `tests/` | Headless smoke test |

Naming and accessor rules: see [CONVENTIONS.md](CONVENTIONS.md).
Class diagrams and a two-round data-flow walkthrough: see [docs/diagrams.md](docs/diagrams.md).

## AbilitySystem hook

All gameplay state is read and written through `get_x()` / `set_x()` accessors that call
`AbilitySystem.resolve_get()` / `resolve_set()` (`logic/managers_and_systems/ability_system.gd`).
Today these return the original value unchanged; abilities will plug in there.

## Smoke test

```
godot --headless --path . res://tests/smoke_test.tscn
```

Plays through setup, a full turn (place lander, buy, move, attack) and a round wrap with upkeep.
Exit code 0 means every check passed.
