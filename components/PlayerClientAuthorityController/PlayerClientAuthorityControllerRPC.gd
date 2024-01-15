extends Node

class_name PlayerClientAuthorityControllerRPC

const COMPONENT_NAME = "PlayerClientAuthorityControllerRPC"

var _multiplayer_connection: MultiplayerConnection = null


# Called when the node enters the scene tree for the first time.
func _ready():
	_multiplayer_connection = get_parent()

	# Register yourself with your parent
	_multiplayer_connection.component_list.register_component(COMPONENT_NAME, self)

	# Wait until the multiplayer connection is initialized
	await _multiplayer_connection.init_done


func sync_position(timestamp: float, pos: Vector3, rotation_y: float, head_rotation_x: float):
	_sync_position.rpc_id(1, timestamp, pos, rotation_y, head_rotation_x)


# RPC function to sync the position from the client to the server.
@rpc("call_remote", "any_peer", "unreliable")
func _sync_position(t: float, p: Vector3, r: float, h: float):
	assert(_multiplayer_connection.is_server(), "This call can only run on the server")

	var id = multiplayer.get_remote_sender_id()

	var user: MultiplayerConnection.User = _multiplayer_connection.get_user_by_id(id)
	if user == null:
		return

	if not user.logged_in:
		return

	if user.player == null:
		return

	assert(
		user.player.player_client_authority_controller != null,
		"player_client_authority_controller is null"
	)

	user.player.player_client_authority_controller.server_sync_position(t, p, r, h)
