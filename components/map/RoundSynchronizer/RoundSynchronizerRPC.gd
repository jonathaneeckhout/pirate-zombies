extends Node

class_name RoundSynchronizerRPC

const COMPONENT_NAME = "RoundSynchronizerRPC"

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


func client_sync_scores():
	_client_sync_scores.rpc_id(1)


func server_sync_response(peer_id: int, data: Dictionary):
	_server_sync_response.rpc_id(peer_id, data)


@rpc("call_remote", "any_peer", "reliable")
func _client_sync_scores():
	# Ensure this call is only run on the server.
	assert(_multiplayer_connection.is_server(), "This call can only run on the server")

	# Get the sender's ID.
	var id = multiplayer.get_remote_sender_id()

	# Get the user associated with the sender's ID.
	var user: MultiplayerConnection.User = _multiplayer_connection.get_user_by_id(id)
	if user == null:
		return

	# Ignore the call if the user is not logged in.
	if not user.logged_in:
		return

	# Ignore the call if the user's player is not initialized.
	if user.player == null:
		return

	server_sync_response(user.player.peer_id, _multiplayer_connection.map.round_synchronizer.scores)


@rpc("call_remote", "authority", "reliable")
func _server_sync_response(d: Dictionary):
	_multiplayer_connection.map.round_synchronizer.client_sync_response(d)
