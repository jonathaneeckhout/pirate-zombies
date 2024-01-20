extends Node3D

class_name ShootSynchronizer

signal shoot

## The projectile used for this weapon
@export var projectile_scene: Resource = null

## Marker to indicate the location of where the projectiles will be fired
@export var barrel_exit: BarrelExit = null

## The ray that will be used for hitscan
@export var hit_ray: RayCast3D = null

## The delay between two shots
@export var shoot_delay: float = 0.25

## Key used to trigger the shot
@export var shoot_key: String = "shoot"

## Whether the projectile should instant hit or not (thus have fly time or not)
@export var instant_hit: bool = false

# Reference to the parent node (assumed to be a Player node).
var _player: Player = null

# Reference to the ClockSynchronizer component for timestamp synchronization.
var _clock_synchronizer: ClockSynchronizer = null

var _shoot_synchronizer_rpc: ShootSynchronizerRPC = null

# Timer used to track the time between shots
var _delay_timer: Timer = null

# Bool checking if this instance is your own player
var _own_player: bool = false

var _server_buffer: Array[Dictionary] = []

var _shooting: bool = false


func _ready():
	# Get the player; make sure this component is a child of the player's object.
	_player = get_parent()

	# Ensure the player has a multiplayer connection
	assert(_player.multiplayer_connection != null, "Player's multiplayer connection is null")

	# Get the ClockSynchronizer component.
	_clock_synchronizer = _player.multiplayer_connection.component_list.get_component(
		ClockSynchronizer.COMPONENT_NAME
	)

	assert(_clock_synchronizer != null, "Failed to get ClockSynchronizer component")

	_shoot_synchronizer_rpc = (_player.multiplayer_connection.component_list.get_component(
		ShootSynchronizerRPC.COMPONENT_NAME
	))

	assert(_shoot_synchronizer_rpc != null, "Failed to get ShootSynchronizerRPC component")

	_own_player = _player.multiplayer_connection.is_own_player(_player)

	_delay_timer = Timer.new()
	_delay_timer.name = "DelayTimer"
	_delay_timer.wait_time = shoot_delay
	_delay_timer.one_shot = true
	_delay_timer.autostart = false
	add_child(_delay_timer)

	# Don't handle the physics on the server
	if _player.multiplayer_connection.is_server():
		set_physics_process(false)


func _physics_process(_delta):
	if _own_player:
		_handle_own_player()
	else:
		_check_server_buffer()


func _handle_own_player():
	if Input.is_action_just_pressed(shoot_key):
		_shooting = true
	elif Input.is_action_just_released(shoot_key):
		_shooting = false

	if not _shooting:
		return

	if not _delay_timer.is_stopped():
		return

	# Start the delay timer
	_delay_timer.start(shoot_delay)

	_shoot_synchronizer_rpc.sync_shot_to_server(
		_clock_synchronizer.client_clock, barrel_exit.position, barrel_exit.basis
	)

	shoot.emit()

	print("pang")


func _check_server_buffer():
	# Loop backwards
	for i in range(_server_buffer.size() - 1, -1, -1):
		var entry = _server_buffer[i]
		# Check when the projectile should be shot
		if entry["timestamp"] <= _clock_synchronizer.client_clock:
			# fire_projectile(entry["position"], entry["basis"], false)

			shoot.emit()

			# Remove the entry
			_server_buffer.remove_at(i)


# func fire_projectile(
# 	projectile_position: Vector3, projectile_transform_basis: Basis, original: bool
# ):
# 	# Play the shoot animation
# 	weapon_animationplayer.play("shoot")

# 	# If no scene is assigned, don't try to create a new instance
# 	if not projectile_scene:
# 		return

# 	if _current_projectile != null:
# 		# Emit the signal to be used for other components
# 		single_projectile_released.emit(_current_projectile)

# 		# This mean that the current projectile should be released
# 		_current_projectile.queue_free()

# 		# Set this value to null so that clicking shoot the next time will shoot again.
# 		_current_projectile = null

# 		return

# 	var pos: Vector3 = projectile_position

# 	if instant_hit:
# 		# Force the update to scan the area
# 		hit_ray.force_raycast_update()

# 		# If you're not hitting anything, don't do anything
# 		if not hit_ray.is_colliding():
# 			return

# 		pos = hit_ray.get_collision_point()

# 	# Create the projectile
# 	var projectile: Projectile = projectile_scene.instantiate()
# 	projectile.position = pos
# 	projectile.transform.basis = projectile_transform_basis
# 	projectile.original = original
# 	projectile.persistent = single_projectile
# 	projectile.instant_hit = instant_hit
# 	Connection.map.projectiles.add_child(projectile)

# 	# If this variable is null means that the projectile is not fired. Thus assigning it to this variable
# 	if single_projectile:
# 		_current_projectile = projectile

# 		# Emit the signal to be used for other components
# 		single_projectile_shot.emit(projectile)


# Called on server-side
func server_sync_shot_to_other_players(timestamp: float, shot_position: Vector3, shot_basis: Basis):
	for other_player in _player.network_view_synchronizer.players_in_view:
		_shoot_synchronizer_rpc.sync_shot_to_player(
			other_player.peer_id, _player.name, timestamp, shot_position, shot_basis
		)


# Called on client-side
func client_sync_shot(
	timestamp: float, projectile_position: Vector3, projectile_transform_basis: Basis
):
	_server_buffer.append(
		{
			"timestamp": timestamp,
			"position": projectile_position,
			"basis": projectile_transform_basis
		}
	)