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


func sync_shot_to_server(timestamp: float, shot_position: Vector3, shot_basis: Basis):
	_sync_shot_to_server.rpc_id(1, timestamp, shot_position, shot_basis)


func sync_shot_to_player(
	peer_id: int, player_name: String, timestamp: float, shot_position: Vector3, shot_basis: Basis
):
	_sync_shot_to_player.rpc_id(peer_id, player_name, timestamp, shot_position, shot_basis)


func sync_hit_to_server(player_name: String, attacker_name: String, damage: int):
	_sync_hit_to_server.rpc_id(1, player_name, attacker_name, damage)


@rpc("call_remote", "any_peer", "unreliable")
func _sync_shot_to_server(t: float, p: Vector3, b: Basis):
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

	user.player.shoot_synchronizer.server_sync_shot_to_other_players(t, p, b)


@rpc("call_remote", "authority", "reliable")
func _sync_shot_to_player(n: String, t: float, p: Vector3, b: Basis):
	var player: Player = _multiplayer_connection.map.get_player_by_name(n)

	if player == null:
		return

	assert(player.shoot_synchronizer != null, "shoot_synchronizer is null")

	player.shoot_synchronizer.client_sync_shot(t, p, b)


@rpc("call_remote", "any_peer", "reliable")
func _sync_hit_to_server(n: String, a: String, d: int):
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

	var player: Player = _multiplayer_connection.map.get_player_by_name(n)

	if player == null:
		return

	assert(player.shoot_synchronizer != null, "shoot_synchronizer is null")
	
	var attacker: Player = _multiplayer_connection.map.get_player_by_name(a)

	if attacker == null:
		return

	player.stats_synchronizer.server_hurt(attacker, d)
