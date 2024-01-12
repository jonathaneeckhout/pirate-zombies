extends Node

class_name Map

@export var multiplayer_connection: MultiplayerConnection = null

## Node grouping all the players
var players: Node3D = null

## Node grouping all the projectiles
var projectiles: Node3D = null


func _ready():
	# Create the players node
	players = Node3D.new()
	players.name = "Players"
	add_child(players)

	# Create the projectiles node
	projectiles = Node3D.new()
	projectiles.name = "Projectiles"
	add_child(projectiles)


func map_init() -> bool:
	# Server-side logic
	if multiplayer_connection.is_server():
		var player_spawn_synchronizer: PlayerSpawnerSynchronizer = (
			multiplayer_connection
			. component_list
			. get_component(PlayerSpawnerSynchronizer.COMPONENT_NAME)
		)

		assert(
			player_spawn_synchronizer != null, "Failed to get PlayerSpawnerSynchronizer component"
		)

		player_spawn_synchronizer.server_player_added.connect(_on_server_player_added)
		player_spawn_synchronizer.server_player_removed.connect(_on_server_player_removed)

	# 	# Connect to the login signal to know when a new player has joined
	# 	Connection.player_rpc.server_player_logged_in.connect(_on_server_player_logged_in)
	# 	multiplayer.peer_disconnected.connect(_on_server_peer_disconnected)

	# # Client-side logic
	# else:
	# 	# Listen to the signal for your player to be added
	# 	Connection.player_rpc.client_player_added.connect(_on_client_player_added)

	return true


func _on_server_player_added(username: String, peer_id: int):
	pass


func _on_server_player_removed(username: String):
	pass
