extends Node

class_name MultiplayerConnection

## Signal indicating if a client connected or not
signal client_connected(connected: bool)

## Signal to indicate that the initialization is done. Used for the child components
signal init_done

## The physics ticks rate for the client
@export var client_physics_ticks_per_second: int = 60

## The physics ticks rate for the server
@export var server_physics_ticks_per_second: int = 10

## The modes a connection can be in
enum MODE { SERVER, CLIENT }

## A list of the components attached to this component
var component_list: ComponentList = ComponentList.new()

## The client's player character
var client_player: Player = null

# The current mode of this instance
var _mode: MODE = MODE.CLIENT

# Boolean indicating if the client already called the init
var _client_init_done: bool = false

# Dict containing all user connected to the server
var _server_users: Dictionary = {}


func _init_common(fps: int) -> bool:
	# Set the current multiplayer's api path to this path to optimize multiplayer packets
	multiplayer.object_configuration_add(null, get_path())

	GodotLogger.info("Setting the game's physics ticks per second to %d" % fps)
	Engine.set_physics_ticks_per_second(fps)

	return true


func _client_init() -> bool:
	if _client_init_done:
		GodotLogger.info("Client init already done, no need to do it again")
		return true

	_mode = MODE.CLIENT

	GodotLogger.info("Running game as client instance")

	if not _init_common(client_physics_ticks_per_second):
		GodotLogger.error("Failed to init common connection part")
		return false

	_client_init_done = true

	# Let the others know you're done initializing
	init_done.emit()

	return true


## Client start function to be called after the inherited class client start
func _client_start():
	if not multiplayer.connected_to_server.is_connected(_on_client_connection_succeeded):
		multiplayer.connected_to_server.connect(_on_client_connection_succeeded)

	if not multiplayer.connection_failed.is_connected(_on_client_connection_failed):
		multiplayer.connection_failed.connect(_on_client_connection_failed)

	if not multiplayer.server_disconnected.is_connected(_on_client_server_disconnected):
		multiplayer.server_disconnected.connect(_on_client_server_disconnected)


func _client_cleanup():
	multiplayer.multiplayer_peer = null

	if multiplayer.connected_to_server.is_connected(_on_client_connection_succeeded):
		multiplayer.connected_to_server.disconnect(_on_client_connection_succeeded)

	if multiplayer.connection_failed.is_connected(_on_client_connection_failed):
		multiplayer.connection_failed.disconnect(_on_client_connection_failed)

	if multiplayer.server_disconnected.is_connected(_on_client_server_disconnected):
		multiplayer.server_disconnected.disconnect(_on_client_server_disconnected)


func _server_init() -> bool:
	_mode = MODE.SERVER

	GodotLogger.info("Running game as server instance")

	if not _init_common(server_physics_ticks_per_second):
		GodotLogger.error("Failed to init common connection part")
		return false

	# Let the others know you're done initializing
	init_done.emit()

	return true


func _server_start():
	if not multiplayer.peer_connected.is_connected(_on_server_peer_connected):
		multiplayer.peer_connected.connect(_on_server_peer_connected)

	if not multiplayer.peer_disconnected.is_connected(_on_server_peer_disconnected):
		multiplayer.peer_disconnected.connect(_on_server_peer_disconnected)


func server_get_tls_options(cert_path: String, key_path: String) -> TLSOptions:
	if not FileAccess.file_exists(cert_path):
		GodotLogger.error("Certificate=[%s] does not exist" % cert_path)
		return null

	if not FileAccess.file_exists(key_path):
		GodotLogger.error("Key=[%s] does not exist" % key_path)
		return null

	var cert_file = FileAccess.open(cert_path, FileAccess.READ)
	if cert_file == null:
		GodotLogger.error("Failed to open server certificate %s" % cert_path)
		return null

	var key_file = FileAccess.open(key_path, FileAccess.READ)
	if key_file == null:
		GodotLogger.error("Failed to open server key %s" % key_path)
		return null

	var cert_string = cert_file.get_as_text()
	var key_string = key_file.get_as_text()

	var cert = X509Certificate.new()

	var error = cert.load_from_string(cert_string)
	if error != OK:
		GodotLogger.error("Failed to load certificate")
		return null

	var key = CryptoKey.new()

	error = key.load_from_string(key_string)
	if error != OK:
		GodotLogger.error("Failed to load key")
		return null

	return TLSOptions.server(key, cert)


## Check if the current instance is running as server or client
func is_server() -> bool:
	return _mode == MODE.SERVER


## Check if the given player is your own player
func is_own_player(player: Player) -> bool:
	return client_player == player


## Get the user by its id
## To be called on server-side
func get_user_by_id(id: int) -> User:
	assert(is_server(), "This function should only be called on the server side")

	return _server_users.get(id)


## Checks if a user is logged in by it's id
func is_user_logged_in(id: int) -> bool:
	assert(is_server(), "This function should only be called on the server side")

	return _server_users[id].logged_in


func _on_server_peer_connected(id: int):
	GodotLogger.info("Peer connected %d" % id)

	_server_users[id] = User.new()


func _on_server_peer_disconnected(id: int):
	GodotLogger.info("Peer disconnected %d" % id)

	_server_users.erase(id)


func _on_client_connection_succeeded():
	GodotLogger.info("Connection succeeded")
	client_connected.emit(true)


func _on_client_connection_failed():
	GodotLogger.warn("Connection failed")
	client_connected.emit(false)

	_client_cleanup()


func _on_client_server_disconnected():
	GodotLogger.info("Server disconnected")
	client_connected.emit(false)

	_client_cleanup()


class User:
	extends RefCounted
	var username: String = ""
	var logged_in: bool = false
	var connected_time: float = Time.get_unix_time_from_system()
	var player: Player = null
