# This script extends Node and represents a component for synchronizing player positions on the server.
extends Node

# Define the class name for the script.
class_name PlayerClientAuthorityControllerRPC

# The component name for registration in the multiplayer connection's component list.
const COMPONENT_NAME = "PlayerClientAuthorityControllerRPC"

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


# RPC function to sync the position from the client to the server.
func sync_position(timestamp: float, pos: Vector3, rotation_y: float, head_rotation_x: float):
	_sync_position.rpc_id(1, timestamp, pos, rotation_y, head_rotation_x)


# RPC function to sync the position from the client to the server.
@rpc("call_remote", "any_peer", "unreliable")
func _sync_position(t: float, p: Vector3, r: float, h: float):
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

	# Ensure the user's player has a valid player_client_authority_controller.
	assert(
		user.player.player_client_authority_controller != null,
		"player_client_authority_controller is null"
	)

	# Call the server_sync_position function on the player's player_client_authority_controller.
	user.player.player_client_authority_controller.server_sync_position(t, p, r, h)
