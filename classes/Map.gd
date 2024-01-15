extends Node

class_name Map

@export var multiplayer_connection: MultiplayerConnection = null

## The scene used for this map
@export var player_scene: Resource = null

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

	# # Client-side logic
	# else:
	# 	# Listen to the signal for your player to be added
	# 	Connection.player_rpc.client_player_added.connect(_on_client_player_added)

	return true


func _on_server_player_added(username: String, peer_id: int):
	# Fetch the user from the connection list
	var user: MultiplayerConnection.User = multiplayer_connection.get_user_by_id(peer_id)
	if user == null:
		GodotLogger.warn("Could not find user with id=%d" % peer_id)
		return

	var new_player: Player = player_scene.instantiate()
	new_player.name = username
	new_player.peer_id = peer_id
	new_player.position.y = 10.0

	GodotLogger.info("Adding player=[%s] with id=[%d] to the map" % [new_player.name, peer_id])

	# Add the player to the world
	players.add_child(new_player)

	user.player = new_player


func _on_server_player_removed(username: String):
	# Try to get the player with the given username
	var player: Player = players.get_node_or_null(username)
	if player == null:
		return

	GodotLogger.info("Removing player=[%s] from the map" % username)

	# Make sure this player isn't updated anymore
	player.set_physics_process(false)

	# Queue the player for deletions
	player.queue_free()
