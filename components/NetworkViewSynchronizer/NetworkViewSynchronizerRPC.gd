extends Node

# Define the class name for the script.
class_name NetworkViewSynchronizerRPC

# The component name for registration in the multiplayer connection's component list.
const COMPONENT_NAME = "NetworkViewSynchronizerRPC"

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


func add_player(peer_id: int, player_name: String, target_player_name: String, pos: Vector3):
	_add_player.rpc_id(peer_id, player_name, target_player_name, pos)


func remove_player(peer_id: int, player_name: String, target_player_name: String):
	_remove_player.rpc_id(peer_id, player_name, target_player_name)


func sync_bodies_in_view():
	_sync_bodies_in_view.rpc_id(1)


@rpc("call_remote", "authority", "reliable")
func _add_player(n: String, u: String, p: Vector3):
	var player: Player = _multiplayer_connection.map.get_player_by_name(n)

	if player == null:
		return

	assert(player.network_view_synchronizer != null, "network_view_synchronizer is null")

	player.network_view_synchronizer.client_add_player(u, p)


@rpc(
	"call_remote",
	"authority",
	"reliable",
)
func _remove_player(n: String, u: String):
	var player: Player = _multiplayer_connection.map.get_player_by_name(n)

	if player == null:
		return

	assert(player.network_view_synchronizer != null, "network_view_synchronizer is null")

	player.network_view_synchronizer.client_remove_player(u)


@rpc("call_remote", "any_peer", "reliable")
func _sync_bodies_in_view():
	assert(_multiplayer_connection.is_server(), "This call can only run on the server")

	var id = multiplayer.get_remote_sender_id()

	var user: MultiplayerConnection.User = _multiplayer_connection.get_user_by_id(id)
	if user == null:
		return

	if not user.logged_in:
		return

	if user.player == null:
		return

	assert(user.player.network_view_synchronizer != null, "network_view_synchronizer is null")

	user.player.network_view_synchronizer.sync_players_in_view()
