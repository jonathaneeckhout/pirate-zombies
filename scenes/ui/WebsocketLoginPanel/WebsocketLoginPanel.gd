extends Control

class_name WebsocketLoginPanel

## Signal to indicate that the current instance should run as a client
signal run_as_server

## Signal to indicate that the current instance should run as a server
signal run_as_client


# Called when the node enters the scene tree for the first time.
func _ready():
	# Connect to the signals of the buttons
	%RunAsServerButton.pressed.connect(_on_run_as_server_button_pressed)
	%RunAsClientButton.pressed.connect(_on_run_as_client_button_pressed)


func _on_run_as_server_button_pressed():
	run_as_server.emit()


func _on_run_as_client_button_pressed():
	run_as_client.emit()
