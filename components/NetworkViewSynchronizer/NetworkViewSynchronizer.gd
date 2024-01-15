# This script extends Node3D and manages the synchronization of players in the network view.
extends Node3D

# Define the class name for the script.
class_name NetworkViewSynchronizer

# The component name for registration in the multiplayer connection's component list.
const COMPONENT_NAME = "NetworkViewSynchronizer"

# Signal emitted when a player is added to the network view.
signal player_added(player_name: String, pos: Vector3)

# Signal emitted when a player is removed from the network view.
signal player_removed(player_name: String)

# Array to store players currently in view.
var players_in_view: Array[Player] = []

# Reference to the NetworkViewArea.
@onready var _network_view_area: Area3D = $NetworkViewArea

# Reference to the parent Player node.
var _player: Player = null

# Reference to the NetworkViewSynchronizerRPC component for RPC calls.
var _network_view_synchronizer_rpc: NetworkViewSynchronizerRPC = null


# Called when the node enters the scene tree for the first time.
func _ready():
	# Get the parent Player node.
	_player = get_parent()

	assert(_player.multiplayer_connection != null, "Player's multiplayer connection is null")

	# Get the NetworkViewSynchronizerRPC component.
	_network_view_synchronizer_rpc = _player.multiplayer_connection.component_list.get_component(
		NetworkViewSynchronizerRPC.COMPONENT_NAME
	)

	assert(
		_network_view_synchronizer_rpc != null, "Failed to get NetworkViewSynchronizerRPC component"
	)

	# Server-side code.
	if _player.multiplayer_connection.is_server():
		# Connect signals for body entering and exiting the network view area.
		_network_view_area.body_entered.connect(_on_body_network_view_area_body_entered)
		_network_view_area.body_exited.connect(_on_body_network_view_area_body_exited)

	# Client-side code.
	elif _player.multiplayer_connection.is_own_player(_player):
		# Wait until the connection is ready to synchronize stats.
		if not multiplayer.has_multiplayer_peer():
			await multiplayer.connected_to_server

		# Wait an additional frame so others can get set.
		await get_tree().process_frame

		# Some entities take a bit to get added to the tree, do not update them until then.
		if not is_inside_tree():
			await tree_entered

		# Synchronize bodies in view.
		_network_view_synchronizer_rpc.sync_bodies_in_view()


# Client-side function to add a player to the network view.
func client_add_player(player_name: String, pos: Vector3):
	player_added.emit(player_name, pos)


# Client-side function to remove a player from the network view.
func client_remove_player(player_name: String):
	player_removed.emit(player_name)


# Synchronize players currently in view.
func sync_players_in_view():
	for player in players_in_view:
		_network_view_synchronizer_rpc.add_player(
			_player.peer_id, _player.name, player.name, player.position
		)

		player_added.emit(player.name, player.position)


# Called when a body enters the network view area.
func _on_body_network_view_area_body_entered(body: Node3D):
	if not body.is_in_group("players"):
		return

	# Don't handle the player.
	if body == _player:
		return

	if not players_in_view.has(body):
		_network_view_synchronizer_rpc.add_player(
			_player.peer_id, _player.name, body.name, body.position
		)

		player_added.emit(body.name, body.position)
		players_in_view.append(body)


# Called when a body exits the network view area.
func _on_body_network_view_area_body_exited(body: Node3D):
	if not body.is_in_group("players"):
		return

	# Don't handle the player.
	if body == _player:
		return

	if players_in_view.has(body):
		if _player.peer_id in multiplayer.get_peers():
			player_removed.emit(body.name)

			_network_view_synchronizer_rpc.remove_player(_player.peer_id, _player.name, body.name)

		players_in_view.erase(body)
