# match_request.gd
class_name MatchRequest
extends RefCounted

## What the menus asked for, handed to the game scene (GameRoot reads it when the match starts).
## Static, so it survives the scene change and "Play again" (reloading the game scene) replays
## the same match. When nothing was chosen (e.g. the tests load main.tscn directly), the game
## uses its own defaults: a random race and MatchSettings.opponent_count AIs.

const MIN_OPPONENTS: int = 1
## Limited by the actor colour palette (GameRoot.ACTOR_COLORS has one colour per seat).
const MAX_OPPONENTS: int = 3

## The player's race, or null for a random one.
static var player_species: SpeciesData
## How many AI opponents, or 0 for MatchSettings' default.
static var opponent_count: int = 0


static func set_choices(species: SpeciesData, opponents: int) -> void:
	player_species = species
	opponent_count = clampi(opponents, MIN_OPPONENTS, MAX_OPPONENTS)


static func clear() -> void:
	player_species = null
	opponent_count = 0
