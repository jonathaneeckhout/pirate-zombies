extends Node

class_name RespawnSynchronizer

signal respawning
signal respawned

@export var stats_synchronizer: StatsSynchronizer = null

## Reference to the NetworkViewSynchronizer component
@export var network_view_synchronizer: NetworkViewSynchronizer

@export var respawn_time: float = 5.0

# Reference to the parent node (assumed to be a Player node).
var _player: Player = null

var _respawn_synchronizer_rpc: RespawnSynchronizerRPC = null

var _respawning: bool = false


# Called when the node enters the scene tree for the first time.
func _ready():
	# Get the player; make sure this component is a child of the player's object.
	_player = get_parent()

	# Ensure the player has a multiplayer connection
	assert(_player.multiplayer_connection != null, "Player's multiplayer connection is null")

	# This component should only run on the server-side
	if not _player.multiplayer_connection.is_server():
		set_process_input(false)
		set_physics_process(false)
		return

	_respawn_synchronizer_rpc = (_player.multiplayer_connection.component_list.get_component(
		RespawnSynchronizerRPC.COMPONENT_NAME
	))

	assert(_respawn_synchronizer_rpc != null, "Failed to get RespawnSynchronizerRPC component")

	stats_synchronizer.died.connect(_on_died)


func client_sync_respawn_position(pos: Vector3):
	# Update the player's values.
	_player.position = pos


func client_sync_respawning():
	_player.hide()
	respawning.emit()


func client_sync_respawned():
	_player.show()
	respawned.emit()


func _handle_respawn():
	if _respawning:
		return

	_respawning = true

	respawning.emit()

	# Sync the new hp to the owner of this component
	_respawn_synchronizer_rpc.sync_respawning(_player.peer_id, _player.name)

	# And to everyone looking at this owner
	for player in network_view_synchronizer.players_in_view:
		_respawn_synchronizer_rpc.sync_respawning(player.peer_id, _player.name)

	await get_tree().create_timer(respawn_time).timeout

	stats_synchronizer.server_reset_hp()
	_player.position = _player.multiplayer_connection.map.get_random_spawn_location()

	# Sync the new hp to the owner of this component
	_respawn_synchronizer_rpc.sync_respawn_position(_player.peer_id, _player.name, _player.position)

	# And to everyone looking at this owner
	for player in network_view_synchronizer.players_in_view:
		_respawn_synchronizer_rpc.sync_respawn_position(
			player.peer_id, _player.name, _player.position
		)

	_respawning = false

	respawned.emit()

	# Sync the new hp to the owner of this component
	_respawn_synchronizer_rpc.sync_respawned(_player.peer_id, _player.name)

	# And to everyone looking at this owner
	for player in network_view_synchronizer.players_in_view:
		_respawn_synchronizer_rpc.sync_respawned(player.peer_id, _player.name)


func _on_died():
	_handle_respawn()
