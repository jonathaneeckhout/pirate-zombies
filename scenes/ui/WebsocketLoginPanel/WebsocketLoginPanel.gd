extends Control

class_name WebsocketLoginPanel

## Signal to indicate that the current instance should run as a client
signal run_as_server(server_port: int, server_bind_address: String)

## Signal to indicate that the current instance should run as a server
signal run_as_client(server_address: String, username: String, password: String)

## Random names which will be used when the username is empty and no account verification is needed
const RANDOM_PLAYER_NAMES = [
	"Alpha",
	"Bravo",
	"Charlie",
	"Delta",
	"Echo",
	"Foxtrot",
	"Golf",
	"Hotel",
	"India",
	"Juliet",
	"Kilo",
	"Lima",
	"Mike",
	"November",
	"Oscar",
	"Papa",
	"Quebec",
	"Romeo",
	"Sierra",
	"Tango",
	"Uniform",
	"Victor",
	"Whiskey",
	"X-ray",
	"Yankee",
	"Zulu"
]

## Whether or not to run this panel in debug mode or not
@export var debug: bool = true

## The default port used for the server. Set to 0 if you dont want to use this default value.
@export var default_server_port: int = 9080

## The default bind address used for the server. Set to "" (empty string) if you dont want to use this default value.
@export var default_server_bind_address: String = "*"

## The default address used for the client to connect to the server. Set to "" (empty string) if you dont want to use this default value.
@export var default_server_address: String = "ws://localhost:9080"

## The default username used for the client to login to the server. Only valid if debug is set to true. Set to "" (empty string) if you dont want to use this default value.
@export var default_debug_username: String = ""

## The default username used for the client to login to the server. Only valid if debug is set to true. Set to "" (empty string) if you dont want to use this default value.
@export var default_debug_password: String = ""


# Called when the node enters the scene tree for the first time.
func _ready():
	# Connect to the signals of the buttons
	%RunAsServerButton.pressed.connect(_on_run_as_server_button_pressed)
	%RunAsClientButton.pressed.connect(_on_run_as_client_button_pressed)

	_fill_in_default_values()


func _fill_in_default_values():
	GodotLogger.info("Filling the default values for the login panel")

	if default_server_port > 0:
		%ServerPort.text = str(default_server_port)

	if default_server_bind_address != "":
		%ServerBindAddress.text = default_server_bind_address

	if default_server_address != "":
		%ServerAddress.text = default_server_address

	if debug and default_debug_username != "":
		%Username.text = default_debug_username

	if debug and default_debug_password != "":
		%Password.text = default_debug_password


func get_username() -> String:
	var username: String = %Username.text

	# Generate a name if the username is empty
	if username.is_empty():
		username = RANDOM_PLAYER_NAMES.pick_random()

	return username


func get_password() -> String:
	return %Password.text


func get_server_address() -> String:
	return %ServerAddress.text


func _on_run_as_server_button_pressed():
	run_as_server.emit(int(%ServerPort.text), %ServerBindAddress.text)


func _on_run_as_client_button_pressed():
	run_as_client.emit(%ServerAddress.text, get_username(), get_password())
