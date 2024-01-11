extends Node

class_name MultiplayerConnection

## Signal indicating if a client connected or not
signal client_connected(connected: bool)

## Time of the delay between clock sync calls on the client side
@export var client_clock_sync_time: float = 0.5

## The modes a connection can be in
enum MODE { SERVER, CLIENT }

# The current mode of this instance
var _mode: MODE = MODE.CLIENT

## Node that groups rpcs used for the clock syncing
var clock_rpc: ClockRPC = null

# Boolean indicating if the client already called the init
var _client_init_done: bool = false

# Timer used to call the clock syncs
var _client_clock_sync_timer: Timer = null

# Dict containing all user connected to the server
var _server_users: Dictionary = {}


func _init_common() -> bool:
	# Set the current multiplayer's api path to this path to optimize multiplayer packets
	multiplayer.object_configuration_add(null, get_path())

	clock_rpc = ClockRPC.new()
	# This short name is done to optimization the network traffic
	clock_rpc.name = "C"
	add_child(clock_rpc)

	return true


func client_init() -> bool:
	if _client_init_done:
		GodotLogger.info("Client init already done, no need to do it again")
		return true

	_mode = MODE.CLIENT

	if not _init_common():
		GodotLogger.error("Failed to init common connection part")
		return false

	_client_clock_sync_timer = Timer.new()
	_client_clock_sync_timer.name = "ClientClockSyncTimer"
	_client_clock_sync_timer.wait_time = client_clock_sync_time
	_client_clock_sync_timer.timeout.connect(_on_client_clock_sync_timer_timeout)
	add_child(_client_clock_sync_timer)

	_client_init_done = true

	return true


## Client start function to be called after the inherited class client start
func client_start():
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


func init_server() -> bool:
	_mode = MODE.SERVER

	if not _init_common():
		GodotLogger.error("Failed to init common connection part")
		return false

	return true


func server_start():
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


func _start_sync_clock():
	GodotLogger.info("Starting sync clock")
	clock_rpc.fetch_server_time.rpc_id(1, Time.get_unix_time_from_system())
	_client_clock_sync_timer.start()


func _stop_sync_clock():
	GodotLogger.info("Stopping sync clock")
	_client_clock_sync_timer.stop()


## Check if the current instance is running as server or client
func is_server() -> bool:
	return _mode == MODE.SERVER


## Check if the given player is your own player
func is_own_player(player: Player) -> bool:
	# You can never be your own player on the server instance
	if is_server():
		return false

	if player == null:
		return false

	# If the player's id matches the id of the connection you know that you're facing your own player node
	return player.peer_id == multiplayer.get_unique_id()


func _on_server_peer_connected(id: int):
	GodotLogger.info("Peer connected %d" % id)

	_server_users[id] = User.new()


func _on_server_peer_disconnected(id: int):
	GodotLogger.info("Peer disconnected %d" % id)

	_server_users.erase(id)


func _on_client_connection_succeeded():
	GodotLogger.info("Connection succeeded")
	client_connected.emit(true)

	_start_sync_clock()


func _on_client_connection_failed():
	GodotLogger.warn("Connection failed")
	client_connected.emit(false)

	_client_cleanup()


func _on_client_server_disconnected():
	GodotLogger.info("Server disconnected")
	client_connected.emit(false)

	_stop_sync_clock()

	_client_cleanup()


func _on_client_clock_sync_timer_timeout():
	# If the connection is still up, call the get latency rpc
	if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		clock_rpc.get_latency.rpc_id(1, Time.get_unix_time_from_system())


class User:
	extends Object
	var username: String = ""
	var logged_in: bool = false
	var connected_time: float = Time.get_unix_time_from_system()
	var player: Player = null
