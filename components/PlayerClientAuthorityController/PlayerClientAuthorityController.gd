extends Node3D

## This component takes care of the controls of the player. This component will only take affect on the player's own character.
class_name PlayerClientAuthorityController

## The component used for the multiplayer functionality
@export var multiplayer_connection: MultiplayerConnection = null

## The gravity that will be used for the player
@export var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

## The movement speed of the player
@export var movement_speed: float = 10.0

## the jump speed of the player
@export var jump_speed: float = 10.0

## The mouse sensivity of the player
@export var mouse_sensivity: float = 0.4

## Key being used to jump
@export var jump_key: String = "jump"

## Key being used to move up
@export var up_key: String = "up"

## Key being used to move down
@export var down_key: String = "down"

## Key being used to move left
@export var left_key: String = "left"

## Key being used to jump
@export var right_key: String = "right"

# This serves as the parent node on which the component will take effect.
var _player: Player = null

# The timestamp of the last received sync message from the server
var _last_sync_timestamp: float = 0.0


# Called when the node enters the scene tree for the first time.
func _ready():
	# Get the player, make sure this component is a child of the player's object
	_player = get_parent()

	# Server-side code
	if multiplayer_connection.is_server():
		# Don't handle input on server-side
		set_process_input(false)

		# No need to run the physics process
		set_physics_process(false)

	# Client-side code
	else:
		# This component is only needed for your own player on the client-side, thus it can be deleted for the other players
		if not multiplayer_connection.is_own_player(_player):
			set_process_input(false)
			set_physics_process(false)
			queue_free()
			return


func _input(event):
	if event is InputEventMouseMotion:
		# Rotate the player around your axis
		_player.rotate_y(deg_to_rad(-event.relative.x * mouse_sensivity))

		# Look up and down
		_player.head.rotate_x(deg_to_rad(-event.relative.y * mouse_sensivity))

		# Make sure to not look too far
		_player.head.rotation.x = clamp(_player.head.rotation.x, deg_to_rad(-89), deg_to_rad(89))


func _physics_process(delta):
	# Apply gravity of the player is not on the floor (airtime)
	if not _player.is_on_floor():
		_player.velocity.y -= gravity * delta

	# Only allow the player to jump when on the floor
	if Input.is_action_just_pressed(jump_key) and _player.is_on_floor():
		_player.velocity.y = jump_speed

	# Only allow the movement of direction when on the ground
	if _player.is_on_floor():
		# Get the input direction from the player's input
		var input_dir = Input.get_vector(left_key, right_key, up_key, down_key)

		# Calculate the direction compared to the current player's transform basis
		var direction = (
			(_player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		)

		# If input is detected, apply it to the velocity
		if direction:
			_player.velocity.x = direction.x * movement_speed
			_player.velocity.z = direction.z * movement_speed
		# If not slow down
		else:
			_player.velocity.x = move_toward(_player.velocity.x, 0, movement_speed) * delta
			_player.velocity.z = move_toward(_player.velocity.z, 0, movement_speed) * delta

	_player.move_and_slide()

	# Sync your position to the server
	# Connection.sync_rpc.playercontroller_sync_position.rpc_id(
	# 	1, Connection.clock, _player.position, _player.rotation.y, _player.head.rotation.x
	# )


## This function stores the latest received sync information for this entity. This information is later used to smoothly inter or extrapolate the position of the entity.
func server_sync_position(timestamp: float, pos: Vector3, rot: float, head: float):
	# Ignore older syncs
	if timestamp < _last_sync_timestamp:
		return

	_last_sync_timestamp = timestamp

	# Update the player's values
	_player.position = pos
	_player.rotation.y = rot
	_player.head.rotation.x = head
