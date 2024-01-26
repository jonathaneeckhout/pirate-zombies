# This script extends Node3D and represents a client-side player controller with authority.
extends Node3D

## Define the class name for the script.
class_name PlayerClientAuthorityController

## The component name for registration in the multiplayer connection's component list.
const COMPONENT_NAME = "PlayerClientAuthorityController"

@export var stats_synchronizer: StatsSynchronizer = null

@export var ui: UICanvas = null

## Gravity used for the player.
@export var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

## Movement speed of the player.
@export var movement_speed: float = 7.0

## Jump speed of the player.
@export var jump_speed: float = 5.0

## Mouse sensitivity of the player.
@export var mouse_sensitivity: float = 0.4

## Key for jumping.
@export var jump_key: String = "jump"

## Key for moving up.
@export var up_key: String = "up"

## Key for moving down.
@export var down_key: String = "down"

## Key for moving left.
@export var left_key: String = "left"

## Key for moving right.
@export var right_key: String = "right"

# Reference to the parent node (assumed to be a Player node).
var _player: Player = null

# Reference to the ClockSynchronizer component for timestamp synchronization.
var _clock_synchronizer: ClockSynchronizer = null

var _player_client_authority_controller_rpc: PlayerClientAuthorityControllerRPC = null

# The timestamp of the last received sync message from the server.
var _last_sync_timestamp: float = 0.0


# Called when the node enters the scene tree for the first time.
func _ready():
	# Get the player; make sure this component is a child of the player's object.
	_player = get_parent()

	assert(_player.multiplayer_connection != null, "Player's multiplayer connection is null")

	# Get the ClockSynchronizer component.
	_clock_synchronizer = _player.multiplayer_connection.component_list.get_component(
		ClockSynchronizer.COMPONENT_NAME
	)

	assert(_clock_synchronizer != null, "Failed to get ClockSynchronizer component")

	_player_client_authority_controller_rpc = (
		_player
		. multiplayer_connection
		. component_list
		. get_component(PlayerClientAuthorityControllerRPC.COMPONENT_NAME)
	)

	assert(
		_player_client_authority_controller_rpc != null,
		"Failed to get PlayerClientAuthorityControllerRPC component"
	)

	# Server-side code.
	if _player.multiplayer_connection.is_server():
		# Don't handle input or run physics process on the server-side.
		set_process_input(false)
		set_physics_process(false)
		return

	# Client-side code.
	else:
		# This component is only needed for the client's own player.
		# Delete it for other players.
		if not _player.multiplayer_connection.is_own_player(_player):
			set_process_input(false)
			set_physics_process(false)
			queue_free()
			return


# Handles mouse motion input to rotate the player and look up and down.
func _input(event):
	# Don't handle input if dead
	if stats_synchronizer.is_dead():
		return

	if event is InputEventMouseMotion:
		# Rotate the player around the axis.
		_player.rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))

		# Look up and down.
		_player.head.rotate_x(deg_to_rad(-event.relative.y * mouse_sensitivity))

		# Ensure not to look too far.
		_player.head.rotation.x = clamp(_player.head.rotation.x, deg_to_rad(-89), deg_to_rad(89))


# Handles physics processing to apply gravity, jump, and movement.
func _physics_process(delta):
	if ui != null and ui.active:
		return

	# Don't move around if dead
	if stats_synchronizer.is_dead():
		return

	# Apply gravity if the player is not on the floor (in air).
	if not _player.is_on_floor():
		_player.velocity.y -= gravity * delta

	# Allow the player to jump only when on the floor.
	if Input.is_action_just_pressed(jump_key) and _player.is_on_floor():
		_player.velocity.y = jump_speed

	# Allow movement only when on the ground.
	if _player.is_on_floor():
		# Get the input direction from the player's input.
		var input_dir = Input.get_vector(left_key, right_key, up_key, down_key)

		# Calculate the direction compared to the current player's transform basis.
		var direction = (
			(_player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		)

		# If input is detected, apply it to the velocity.
		if direction:
			_player.velocity.x = direction.x * movement_speed
			_player.velocity.z = direction.z * movement_speed
		# If not, slow down.
		else:
			_player.velocity.x = move_toward(_player.velocity.x, 0, movement_speed) * delta
			_player.velocity.z = move_toward(_player.velocity.z, 0, movement_speed) * delta

	# Move and slide the player.
	_player.move_and_slide()

	# Sync the position to the server.
	_player_client_authority_controller_rpc.sync_position(
		_clock_synchronizer.client_clock,
		_player.position,
		_player.rotation.y,
		_player.head.rotation.x
	)


# Stores the latest received sync information for this entity.
# This information is later used to smoothly interpolate or extrapolate the position of the entity.
func server_sync_position(timestamp: float, pos: Vector3, rot: float, head: float):
	# Ignore older syncs.
	if timestamp < _last_sync_timestamp:
		return

	_last_sync_timestamp = timestamp

	# Update the player's values.
	_player.position = pos
	_player.rotation.y = rot
	_player.head.rotation.x = head
