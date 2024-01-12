extends Node

class_name PlayerSpawnerSynchronizer

const COMPONENT_NAME = "PlayerSpawnerSynchronizer"

## Signal indicating that a player needs to be added to the server instance
signal server_player_added(username: String, peer_id: int)

## Signal indicating that a player needs to be removed from the server instance
signal server_player_removed(username: String)

## Signal indicating that a player needs to be added to the client instance
signal client_player_added(player_name: String, pos: Vector3, own_player: bool)

## Signal indicating that a player needs to be removed from the client instance
signal client_player_removed(player_name: String)

@export var user_authenticator: UserAuthenticator = null

var _multiplayer_connection: MultiplayerConnection = null


func _ready():
	_multiplayer_connection = get_parent()

	# Register yourself with your parent
	_multiplayer_connection.component_list.register_component(COMPONENT_NAME, self)

	# Wait until the multiplayer connection is initialized
	await _multiplayer_connection.init_done

	if _multiplayer_connection.is_server():
		# Connect to the login signal, this is the trigger to emit the signal to add the player to the server instance
		user_authenticator.server_player_logged_in.connect(_on_server_player_logged_in)

		# Connect to the disconnect signal, this is the trigger to emit the signal to remove the player from the server instance
		multiplayer.peer_disconnected.connect(_on_server_peer_disconnected)
	else:
		pass


func _on_server_player_logged_in(peer_id: int, username: String):
	GodotLogger.info("User=[%s], should be added to the server instance" % username)
	server_player_added.emit(username, peer_id)


func _on_server_peer_disconnected(id: int):
	# Fetch the user linked to this peer id
	var user: MultiplayerConnection.User = _multiplayer_connection.get_user_by_id(id)
	if user == null:
		return

	GodotLogger.info("User=[%s], should be removed from the server instance" % user.username)

	# Broadcast the signal to remove this user
	server_player_removed.emit(user.username)
