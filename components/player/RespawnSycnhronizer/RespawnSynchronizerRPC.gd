extends Node

class_name RespawnSynchronizerRPC

const COMPONENT_NAME = "RespawnSynchronizerRPC"

# Reference to the MultiplayerConnection parent node.
var _multiplayer_connection: MultiplayerConnection = null


# Called when the node enters the scene tree for the first time.
func _ready():
	# Get the MultiplayerConnection parent node.
	_multiplayer_connection = get_parent()

	# Register the component with the parent MultiplayerConnection.
	_multiplayer_connection.component_list.register_component(COMPONENT_NAME, self)

	# Wait until the multiplayer connection is initialized.
	await _multiplayer_connection.init_done


func sync_respawn_position(peer_id: int, player_name: String, pos: Vector3):
	_sync_respawn_position.rpc_id(peer_id, player_name, pos)


func sync_respawning(peer_id: int, player_name: String):
	_sync_respawning.rpc_id(peer_id, player_name)


func sync_respawned(peer_id: int, player_name: String):
	_sync_respawned.rpc_id(peer_id, player_name)


@rpc("call_remote", "authority", "reliable")
func _sync_respawn_position(n: String, p: Vector3):
	var player: Player = _multiplayer_connection.map.get_player_by_name(n)

	if player == null:
		return

	assert(player.respawn_synchronizer != null, "respawn_synchronizer is null")

	player.respawn_synchronizer.client_sync_respawn_position(p)


@rpc("call_remote", "authority", "reliable")
func _sync_respawning(n: String):
	var player: Player = _multiplayer_connection.map.get_player_by_name(n)

	if player == null:
		return

	assert(player.respawn_synchronizer != null, "respawn_synchronizer is null")

	player.respawn_synchronizer.client_sync_respawning()


@rpc("call_remote", "authority", "reliable")
func _sync_respawned(n: String):
	var player: Player = _multiplayer_connection.map.get_player_by_name(n)

	if player == null:
		return

	assert(player.respawn_synchronizer != null, "respawn_synchronizer is null")

	player.respawn_synchronizer.client_sync_respawned()
