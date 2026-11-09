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

* **Players:** you against two AIs (`MatchSettings.opponent_count`), free-for-all: everyone
  plays for themselves and the last one standing wins.
* **Setup:** everyone, the AIs included, places their starting biome landers and then builds their
  command tower on one of them. Nobody starts with units. The game begins once every player has
  a command tower.
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
* **Movement:** each unit moves one lander per turn (it can move again after its owner's next
  upkeep). Fighting doesn't count as a move, so attackers can still move in after a win.
* **Battles** last several rounds, until a side is wiped out or the attacker retreats.
* **SimpleAI** is greedy: it spreads its spare units one per empty neighbour to hold as many
  landers (and their upkeep) as it can, best-yielding first, and drops new landers where it
  can claim them straight away.
* **Economy:** at each upkeep every player gets 3 gold, plus what their landers produce. Each
  biome yields 2 resource points: Plains 2 food, Forest 2 wood, Mountain 1 mineral and 1 stone,
  Badlands 2 gold. Buildings can add their own yield (`BuildingData.upkeep`); the Base adds 2
  food. Basic units cost 2 gold and 1 food; advanced units lean on food (Alpha Werewolf 3 gold
  3 food, Venom Spitter 2 gold 2 food 2 mineral).
* **The board** is the 40 × 40 floor, with invisible walls at its edge. Landers can't be placed
  with any part outside it.

## Gravity

Landers are hexagons, all lined up the same way (`logic/classes/hex.gd`). Spacing and connections
use the face-to-face hex distance: face to face is 2.0 apart, and a gap of up to 0.5 still counts
as connected.

When a lander is placed, the `GravitySystem` turns it into a short-lived gravity well: it and every
lander within `gravity_range` attract each other (inverse square), so close-but-not-touching landers
pull together and connect. Landers are physics bodies (Jolt), so they slide and can crash
(`LanderManager.landers_crashed`).

* **Docking:** a moving lander's speed is capped by its gap to the nearest lander, so it can
  build up speed over open ground but eases in up close, and its pull ends as soon as it touches
  another. Settled landers are heavier, and landers already in a cluster barely feel the pull, so
  a new lander doesn't shove or drag a cluster apart. Loose landers still drift toward it.
* **Snapping:** once everything stops, each lander that moved and is touching another slides into
  the nearest free face-to-face spot next to it.

`board_settled` fires once everything has stopped and snapped; the AI and the tests wait for it.
The placement preview shows where a lander will end up, snap included.

## Abilities

An ability is a small Resource script (`data/abilities/`, extends `Ability`) saved as a `.tres` and
attached where it belongs: a race (`SpeciesData.abilities`), a kind of unit (`UnitData.abilities`),
a building (`BuildingData.abilities`) or the whole match (`MatchSettings.rule_abilities`). The
`AbilitySystem` autoload finds the abilities that apply to a unit (its race, its unit type, the
building and any web on its lander, and the match rules) and asks them at the moments that matter:

* `modify_roll`: bonuses and penalties on a battle roll (shown in the battle dialog by name).
* `check_move` / `move_spends_movement`: whether a unit may move somewhere, and whether that
  uses up its one move this turn.
* `on_defeated_opponent`: react when a unit kills the unit it faced.
* `modify_value`: change any value read through an accessor. All gameplay state is read and
  written through `get_x()` / `set_x()` accessors that call `AbilitySystem.resolve_get()` /
  `resolve_set()`; an ability that lists a property in `value_hooks` gets to change it.

| Ability | Attached to | Effect |
|---|---|---|
| Forest Runners | Lycanthrope | Forest to Forest moves don't use up the unit's move |
| Mountain Shy | Lycanthrope | Can't move onto Mountains (except to take or raze an enemy building there) |
| Pack Call | Alpha Werewolf | Each enemy unit it kills calls a Lycanth Halfbreed to its lander, if there's room |
| Web | Ettercap | Buy a web (1 gold, 2 mineral) on a lander next to yours: non-Ettercaps on it get -1 and can't move off until one spends its move tearing it down; it wears off after 2 of your turns |
| Lurkers | Ettercap | +1 when defending a Mountain lander |
| Castle Tower | Castle Tower | The owner's units fighting on its lander (defending or attacking from it) get +2 |
| Combined Arms | Match rule | Ranged units get +2 when allied melee units fight alongside them |

To add one: write a script extending `Ability` (or reuse one with new exports), make a `.tres`,
and add it to the right `abilities` list. Hover your race in the top bar to see its traits.

## Smoke test

```
godot --headless --path . res://tests/smoke_test.tscn
```

It uses a fixed random seed; set `SMOKE_SEED=n` to try other races and turn orders. It plays one
on one; `res://tests/ffa_test.tscn` checks the default three-player free-for-all (`FFA_SEED=n`).

On the board, the lander in the side panel has a pulsing white ring, and every battle gets an
arrow from attacker to defender (in the attacker's colour) until it ends: "UNDER ATTACK!" and an
alert when it's one of yours. Other players' moves show a short arrow ("Captured!" / "Razed!").

Plays through setup, a full player turn (place lander, buy, move, attack), the AI playing its own
turn in a prepared spot (it places, buys, attacks and claims a lander by itself), and a round wrap
with upkeep. It also checks that the rules reject out-of-turn and out-of-phase actions.
Exit code 0 means every check passed.
