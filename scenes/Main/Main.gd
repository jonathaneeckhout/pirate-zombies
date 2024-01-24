extends Node3D

@export var config: ConfigResource = null

## The prefix used for every log line on the client
@export var client_logging_prefix: String = "Client:"

## The prefix used for every log line on the client
@export var server_logging_prefix: String = "Server:"

## The map scene used for this project
@export var map_scene: Resource = null

@onready var _websocket_multiplayer_connection: WebsocketMultiplayerConnection = $WMC

@onready var _websocket_login_panel: WebsocketLoginPanel = $UI/WebsocketLoginPanel

@onready var _client_login_panel: ClientLoginPanel = $UI/ClientLoginPanel

var _map: Map = null


# Called when the node enters the scene tree for the first time.
func _ready():
	_websocket_login_panel.run_as_server.connect(_on_run_as_server)
	_websocket_login_panel.run_as_client.connect(_on_run_as_client)

	_client_login_panel.joine_game_pressed.connect(_on_join_game_pressed)

	if config.mode == ConfigResource.MODE.DEPLOYMENT:
		if "--server" in OS.get_cmdline_args():
			_start_server()
		else:
			_start_client()


func _start_server():
	GodotLogger._prefix = server_logging_prefix

	# Set the window's title
	get_window().title = "Godot multiplayer (Server)"

	# Hide the login panel
	_websocket_login_panel.hide()

	if not _websocket_multiplayer_connection.websocket_server_init():
		GodotLogger.error("Failed to init websocket server")

		# Show the login_panel again
		_websocket_login_panel.show()

		return

	# Add the map
	_map = map_scene.instantiate()
	_map.name = "Map"
	_map.multiplayer_connection = _websocket_multiplayer_connection
	add_child(_map)

	# Init the map
	_map.map_init()

	if not _websocket_multiplayer_connection.websocket_server_start(
		config.server_port,
		config.server_bind_address,
		config.use_tls,
		config.certh_path,
		config.key_path
	):
		GodotLogger.error("Failed to start websocket server")

		# Show the login_panel again
		_websocket_login_panel.show()

		return


func _start_client():
	GodotLogger._prefix = client_logging_prefix

	# Set the window's title
	get_window().title = "Godot multiplayer (Client)"

	# Hide the login panel
	_websocket_login_panel.hide()

	if not _websocket_multiplayer_connection.websocket_client_init():
		GodotLogger.error("Failed to init websocket client")

		# Show the login_panel again
		_websocket_login_panel.show()

		return

	GodotLogger.info("Successfully authenticated to the server")

	if not _websocket_multiplayer_connection.websocket_client_start(config.server_address):
		GodotLogger.error("Failed to start websocket client")

		# Show the login_panel again
		_websocket_login_panel.show()

		return

	# Wait until you're connected
	var connected: bool = await _websocket_multiplayer_connection.client_connected
	if not connected:
		GodotLogger.warn("Failed to connect to server")

		_websocket_multiplayer_connection.websocket_client_disconnect()

		# Show the ui again  so that the player can try again
		_websocket_login_panel.show()

		return

	GodotLogger.info("Successfully connected to the server")

	# Add the map
	_map = map_scene.instantiate()
	_map.name = "Map"
	_map.multiplayer_connection = _websocket_multiplayer_connection
	add_child(_map)

	# Init the map
	_map.map_init()

	_client_login_panel.show()


func _login_to_server(username: String, password: String):
	_client_login_panel.hide()

	var user_authenticator: UserAuthenticator = (
		_websocket_multiplayer_connection
		. component_list
		. get_component(UserAuthenticator.COMPONENT_NAME)
	)

	user_authenticator.authenticate(username, password)

	var response: bool = await user_authenticator.client_authenticated
	if not response:
		GodotLogger.warn("Failed to authenticate to server")

		_websocket_multiplayer_connection.websocket_client_disconnect()

		# Show the ui again  so that the player can try again
		_client_login_panel.show()

		return


func _on_run_as_server():
	_start_server()


func _on_run_as_client():
	_start_client()


func _on_join_game_pressed(username: String, password: String):
	_login_to_server(username, password)
