# gravity_system.gd
class_name GravitySystem
extends Node

## Lander gravity. When a lander is placed it becomes a gravity well for a short time: it and
## every lander within gravity_range attract each other (inverse square, flat on the board).
## The new lander gets the full pull; existing landers get neighbour_share of it, so they
## shift towards it too. Landers are physics bodies, so they slide, bump and crash into each
## other. A lander's pull ends when its time runs out or when it crashes into another lander.
##
## Docking: a moving lander's speed is capped by how close it is to the nearest other lander
## (dock_speed + dock_braking × gap, up to max_speed), so it builds momentum crossing open
## ground but eases in when it gets close: a lander dropped right next to a cluster nudges
## up against it instead of slamming into it. Landers at rest are settled_mass_scale times
## heavier than ones being pulled, so a bump barely shoves a settled cluster.
##
## board_settled fires once no pull is active and every lander has stopped moving. Actors and
## tests wait for it before reading positions (connections can change while landers move).

signal board_settled()

## Landers further apart than this don't attract.
@export var gravity_range: float = 6.0
## Pull = strength / distance², as an acceleration on the new lander.
@export var strength: float = 120.0
## Caps the pull at close range so landers bump rather than slam into each other.
@export var max_acceleration: float = 12.0
## Fraction of the pull existing landers feel towards the new one.
@export_range(0.0, 1.0) var neighbour_share: float = 0.3
## An existing lander already touching others (part of a cluster) feels only this fraction of
## its neighbour_share, so a new lander doesn't drag it out of its cluster. Loose ones drift.
@export_range(0.0, 1.0) var clustered_share_scale: float = 0.1
## How long (seconds) a new lander pulls.
@export var pull_duration: float = 2.2
## Below this speed a lander counts as at rest.
@export var rest_speed: float = 0.08
## Low friction so landers can glide on the floor; their damping slows them down.
@export_range(0.0, 1.0) var lander_friction: float = 0.05
## Top speed of a lander in contact range of another (it can always touch, just gently).
@export var dock_speed: float = 0.5
## Extra speed allowed per unit of gap to the nearest lander.
@export var dock_braking: float = 1.6
## Speed limit on open ground.
@export var max_speed: float = 6.0
## Settled landers are this much heavier than a lander being pulled (harder to shove).
@export var settled_mass_scale: float = 4.0

## Closer than this (centre to centre) landers are touching and stop pulling each other.
const CONTACT_DISTANCE: float = LanderManager.MIN_DISTANCE_BETWEEN_LANDERS + 0.05
const PREDICTION_STEP: float = 1.0 / 30.0
## Edge gap below which a pulled lander counts as docked and its pull ends.
const DOCKED_GAP: float = 0.06

var _lander_manager: LanderManager
## Active pulls: Lander -> seconds left.
var _pulls := {}
var _is_settled: bool = true
var _lander_material := PhysicsMaterial.new()


#region Public API
func bind_lander_manager(lander_manager: LanderManager) -> void:
	_lander_manager = lander_manager
	_lander_material.friction = lander_friction
	_lander_material.bounce = 0.05
	lander_manager.lander_spawned.connect(_on_lander_manager_lander_spawned)
	lander_manager.landers_crashed.connect(_on_lander_manager_landers_crashed)


func is_settled() -> bool:
	return _is_settled


## Where a lander placed at `spot` would roughly end up: the new lander slides under the same
## pull with the other landers held still. Collisions are approximated by stopping at contact.
## Returns `spot` itself when nothing is in range.
func predict_settle_position(spot: Vector3) -> Vector3:
	var position := Vector3(spot.x, 0, spot.z)
	var velocity := Vector3.ZERO
	var others := _lander_manager.get_landers_within(position, gravity_range * 1.5)
	var time := 0.0
	var damping := Lander.LINEAR_DAMP
	while time < pull_duration + 2.0:
		var acceleration := Vector3.ZERO
		if time < pull_duration:
			for other in others:
				acceleration += _pull_on(position, other.get_board_position())
		velocity += acceleration * PREDICTION_STEP
		velocity *= maxf(0.0, 1.0 - damping * PREDICTION_STEP)
		var gap := INF
		for other in others:
			gap = minf(gap, other.get_board_position().distance_to(position) - LanderManager.MIN_DISTANCE_BETWEEN_LANDERS)
		var limit := minf(dock_speed + dock_braking * maxf(gap, 0.0), max_speed)
		if velocity.length() > limit:
			velocity = velocity.normalized() * limit
		var next := position + velocity * PREDICTION_STEP
		for other in others:
			var other_position := other.get_board_position()
			if next.distance_to(other_position) < LanderManager.MIN_DISTANCE_BETWEEN_LANDERS:
				# Would touch this lander: it stops against it.
				var away := (position - other_position)
				away.y = 0
				if away.length() < 0.01:
					return position
				return other_position + away.normalized() * LanderManager.MIN_DISTANCE_BETWEEN_LANDERS
		position = next
		time += PREDICTION_STEP
		if time > pull_duration and velocity.length() < rest_speed:
			break
	return position


## Landers within gravity range of `spot`, and how strongly each would pull (0..1), for previews.
func get_pull_preview(spot: Vector3) -> Dictionary:
	var preview := {}
	for other in _lander_manager.get_landers_within(spot, gravity_range):
		preview[other] = clampf(_pull_on(Vector3(spot.x, 0, spot.z), other.get_board_position()).length()
			/ max_acceleration, 0.0, 1.0)
	return preview
#endregion


#region Built-ins
func _physics_process(delta: float) -> void:
	if _lander_manager == null:
		return
	for lander: Lander in _pulls.keys():
		if not is_instance_valid(lander):
			_pulls.erase(lander)
			continue
		_pulls[lander] -= delta
		# Its time is up, or it has docked against another lander (pulling on would just lean on it).
		if _pulls[lander] <= 0.0 or _gap_to_nearest(lander.get_board_position(), lander) < DOCKED_GAP:
			_end_pull(lander)
			continue
		_apply_pull(lander)
	if not _is_settled:
		_limit_speeds()

	if not _is_settled and _pulls.is_empty() and _all_landers_at_rest():
		_is_settled = true
		board_settled.emit()
#endregion


#region Signal handlers
func _on_lander_manager_lander_spawned(lander: Lander) -> void:
	lander.physics_material_override = _lander_material
	lander.mass = 1.0
	_pulls[lander] = pull_duration
	_is_settled = false


## A crash ends the pull of whichever lander was pulling (like the original gravity).
func _on_lander_manager_landers_crashed(first: Lander, second: Lander, _impact_speed: float) -> void:
	_end_pull(first)
	_end_pull(second)
#endregion


#region Private
func _end_pull(lander: Lander) -> void:
	_pulls.erase(lander)
	if is_instance_valid(lander):
		lander.mass = settled_mass_scale


## Docking: cap each moving lander's flat speed by its gap to the nearest other lander.
func _limit_speeds() -> void:
	for lander in _lander_manager.get_landers():
		var velocity := lander.linear_velocity
		var flat := Vector2(velocity.x, velocity.z)
		if flat.length() <= dock_speed:
			continue
		var limit := minf(dock_speed + dock_braking * _gap_to_nearest(lander.get_board_position(), lander), max_speed)
		if flat.length() > limit:
			flat = flat.normalized() * limit
			lander.linear_velocity = Vector3(flat.x, velocity.y, flat.y)


## Edge-to-edge distance from `position` to the nearest lander other than `ignore` (and
## `also_ignore`).
func _gap_to_nearest(position: Vector3, ignore: Lander = null, also_ignore: Lander = null) -> float:
	var nearest := INF
	for other in _lander_manager.get_landers_within(position, gravity_range * 1.5, ignore):
		if other != also_ignore:
			nearest = minf(nearest, other.get_board_position().distance_to(position))
	return maxf(0.0, nearest - LanderManager.MIN_DISTANCE_BETWEEN_LANDERS)


func _apply_pull(source: Lander) -> void:
	var source_position := source.get_board_position()
	for other in _lander_manager.get_landers_within(source_position, gravity_range, source):
		var acceleration := _pull_on(source_position, other.get_board_position())
		if acceleration == Vector3.ZERO:
			continue
		source.apply_central_force(acceleration * source.mass)
		var share := neighbour_share
		if _gap_to_nearest(other.get_board_position(), other, source) < 0.15:
			share *= clustered_share_scale
		other.apply_central_force(-acceleration * share * other.mass)
		source.sleeping = false
		other.sleeping = false


## The acceleration a lander at `from` feels towards a lander at `to` (zero when touching).
func _pull_on(from: Vector3, to: Vector3) -> Vector3:
	var offset := to - from
	offset.y = 0
	var distance := offset.length()
	if distance <= CONTACT_DISTANCE or distance > gravity_range:
		return Vector3.ZERO
	return offset / distance * minf(strength / (distance * distance), max_acceleration)


func _all_landers_at_rest() -> bool:
	for lander in _lander_manager.get_landers():
		var velocity := lander.linear_velocity
		velocity.y = 0
		if velocity.length() > rest_speed:
			return false
	return true
#endregion
