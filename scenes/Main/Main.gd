extends Node3D

## The prefix used for every log line on the client
@export var client_logging_prefix: String = "Client:"

## The prefix used for every log line on the client
@export var server_logging_prefix: String = "Server:"

@onready
var _websocket_multiplayer_connection: WebsocketMultiplayerConnection = $WebsocketMultiplayerConnection

@onready var _websocket_login_panel: WebsocketLoginPanel = $UI/WebsocketLoginPanel


# Called when the node enters the scene tree for the first time.
func _ready():
	_websocket_login_panel.run_as_server.connect(_on_run_as_server)
	_websocket_login_panel.run_as_client.connect(_on_run_as_client)


func _start_server(server_port: int, server_bind_address: String):
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

	if not _websocket_multiplayer_connection.websocket_server_start(
		server_port, server_bind_address, false, "", ""
	):
		GodotLogger.error("Failed to start websocket server")

		# Show the login_panel again
		_websocket_login_panel.show()

		return


func _start_client(server_address: String, username: String, password: String):
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

	if not _websocket_multiplayer_connection.websocket_client_start(server_address):
		GodotLogger.error("Failed to start websocket client")

		# Show the login_panel again
		_websocket_login_panel.show()

		return


func _on_run_as_server(server_port: int, server_bind_address: String):
	_start_server(server_port, server_bind_address)


func _on_run_as_client(server_address: String, username: String, password: String):
	_start_client(server_address, username, password)
