extends Node

class_name StatsSynchronizerRPC

const COMPONENT_NAME = "StatsSynchronizerRPC"

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


func sync_stats(player_name: String):
	_sync_stats.rpc_id(1, player_name)


func sync_response(peer_id: int, player_name: String, data: Dictionary):
	_sync_response.rpc_id(peer_id, player_name, data)


func sync_hurt(peer_id: int, player_name: String, timestamp: float, health: int, damage: int):
	_sync_hurt.rpc_id(peer_id, player_name, timestamp, health, damage)


#Called by client, runs on server
@rpc("call_remote", "any_peer", "reliable")
func _sync_stats(n: String):
	assert(_multiplayer_connection.is_server(), "This call can only run on the server")

	var id = multiplayer.get_remote_sender_id()

	# Only allow logged in players
	if not _multiplayer_connection.is_user_logged_in(id):
		return

	var player: Player = _multiplayer_connection.map.get_player_by_name(n)

	if player == null:
		return

	player.stats_synchronizer.server_sync_stats(id)


@rpc("call_remote", "authority", "reliable")
func _sync_response(n: String, d: Dictionary):
	var player: Player = _multiplayer_connection.map.get_player_by_name(n)

	if player == null:
		return

	player.stats_synchronizer.client_sync_response(d)


@rpc("call_remote", "authority", "reliable")
func _sync_hurt(n: String, t: float, h: int, d: int):
	var player: Player = _multiplayer_connection.map.get_player_by_name(n)

	if player == null:
		return

	player.stats_synchronizer.client_sync_hurt(t, h, d)
