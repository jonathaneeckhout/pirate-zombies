extends Node

class_name ShootSynchronizerRPC

const COMPONENT_NAME = "ShootSynchronizerRPC"

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


func sync_start_shooting_to_server(timestamp: float, shot_position: Vector3, shot_basis: Basis):
	_sync_start_shooting_to_server.rpc_id(1, timestamp, shot_position, shot_basis)


@rpc("call_remote", "any_peer", "unreliable")
func _sync_start_shooting_to_server(t: float, p: Vector3, b: Basis):
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

	assert(user.player.shoot_synchronizer != null, "shoot_synchronizer is null")

	user.player.shoot_synchronizer.sync_start_shooting_to_other_players(t, p, b)
