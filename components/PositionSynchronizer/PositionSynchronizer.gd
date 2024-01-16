extends Node3D

class_name PositionSynchronizer

## Constants for interpolation
const INTERPOLATION_OFFSET: float = 0.05
## Constants for interpolation
const INTERPOLATION_INDEX: float = 2

## Reference to the NetworkViewSynchronizer component
@export var network_view_synchronizer: NetworkViewSynchronizer

# Reference to the parent node (assumed to be a Player node).
var _player: Player = null

# Reference to the ClockSynchronizer component for timestamp synchronization.
var _clock_synchronizer: ClockSynchronizer = null

# Reference to the PositionSynchronizerRPC component.
var _position_synchronizer_rpc: PositionSynchronizerRPC = null

# Buffer which keeps track of all the sync information received from the server
var _server_buffer: Array[Dictionary] = []

# The timestamp of the last received sync message from the server
var _last_sync_timestamp: float = 0.0


func _ready():
	# Get the player; make sure this component is a child of the player's object.
	_player = get_parent()

	# Ensure the player has a multiplayer connection
	assert(_player.multiplayer_connection != null, "Player's multiplayer connection is null")

	# Get the ClockSynchronizer component.
	_clock_synchronizer = _player.multiplayer_connection.component_list.get_component(
		ClockSynchronizer.COMPONENT_NAME
	)

	# Ensure the ClockSynchronizer component is present
	assert(_clock_synchronizer != null, "Failed to get ClockSynchronizer component")

	# Get the PositionSynchronizerRPC component.
	_position_synchronizer_rpc = _player.multiplayer_connection.component_list.get_component(
		PositionSynchronizerRPC.COMPONENT_NAME
	)

	# Ensure the PositionSynchronizerRPC component is present
	assert(_position_synchronizer_rpc != null, "Failed to get PositionSynchronizerRPC component")


func _physics_process(_delta):
	# Handle server-side code
	if _player.multiplayer_connection.is_server():
		var timestamp: float = Time.get_unix_time_from_system()

		# Sync your position to every entity that is watching you
		for player in network_view_synchronizer.players_in_view:
			_position_synchronizer_rpc.sync_position(
				_player.peer_id,
				player.name,
				timestamp,
				player.position,
				player.rotation.y,
				player.head.rotation.x
			)
	# Handle client-side code
	else:
		# Calculate the position for the client
		_calculate_position()


func _calculate_position():
	# Calculate the time the player will actually see the entity
	var render_time = _clock_synchronizer.client_clock - INTERPOLATION_OFFSET

	# Remove older messages out of the interpolation range
	while (
		_server_buffer.size() > 2 and render_time > _server_buffer[INTERPOLATION_INDEX]["timestamp"]
	):
		_server_buffer.remove_at(0)

	# If you have enough recent sync messages, interpolate to get smooth movement visualization
	if _server_buffer.size() > INTERPOLATION_INDEX:
		var interpolation_factor = _calculate_interpolation_factor(render_time)
		_player.position = _interpolate(interpolation_factor, "position")
		_player.rotation = _interpolate(interpolation_factor, "rotation")
		_player.head.rotation = _interpolate(interpolation_factor, "head")

	# If you don't have enough recent sync messages, extrapolate to get smooth movement visualization
	elif (
		_server_buffer.size() > INTERPOLATION_INDEX - 1
		and render_time > _server_buffer[INTERPOLATION_INDEX - 1]["timestamp"]
	):
		var extrapolation_factor = _calculate_extrapolation_factor(render_time)
		_player.position = _extrapolate(extrapolation_factor, "position")
		_player.rotation = _extrapolate(extrapolation_factor, "rotation")
		_player.head.rotation = _extrapolate(extrapolation_factor, "head")


func _calculate_interpolation_factor(render_time: float) -> float:
	var interpolation_factor = (
		float(render_time - _server_buffer[INTERPOLATION_INDEX - 1]["timestamp"])
		/ float(
			(
				_server_buffer[INTERPOLATION_INDEX]["timestamp"]
				- _server_buffer[INTERPOLATION_INDEX - 1]["timestamp"]
			)
		)
	)

	return interpolation_factor


func _interpolate(interpolation_factor: float, parameter: String) -> Vector3:
	return _server_buffer[INTERPOLATION_INDEX - 1][parameter].lerp(
		_server_buffer[INTERPOLATION_INDEX][parameter], interpolation_factor
	)


func _calculate_extrapolation_factor(render_time: float) -> float:
	var extrapolation_factor = (
		float(render_time - _server_buffer[INTERPOLATION_INDEX - 2]["timestamp"])
		/ float(
			(
				_server_buffer[INTERPOLATION_INDEX - 1]["timestamp"]
				- _server_buffer[INTERPOLATION_INDEX - 2]["timestamp"]
			)
		)
	)

	return extrapolation_factor


func _extrapolate(extrapolation_factor: float, parameter: String) -> Vector3:
	return _server_buffer[INTERPOLATION_INDEX - 2][parameter].lerp(
		_server_buffer[INTERPOLATION_INDEX - 1][parameter], extrapolation_factor
	)


## This function stores the latest received sync information for this entity. This information is later used to smoothly inter or extrapolate the position of the entity.
func client_sync_position(timestamp: float, pos: Vector3, rot: float, head: float):
	# Ignore older syncs
	if timestamp < _last_sync_timestamp:
		return

	_last_sync_timestamp = timestamp
	_server_buffer.append(
		{
			"timestamp": timestamp,
			"position": pos,
			"rotation": Vector3(0, rot, 0),
			"head": Vector3(head, 0, 0)
		}
	)
