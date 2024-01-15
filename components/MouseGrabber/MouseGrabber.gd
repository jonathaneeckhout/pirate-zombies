extends Node3D

@export var grab_mouse_key: String = "grab_mouse"

# This serves as the parent node on which the component will take effect.
var _player: Player = null


func _ready():
	_player = get_parent()

	assert(_player.multiplayer_connection != null, "Player's multiplayer connection is null")

	if (
		not _player.multiplayer_connection.is_server()
		and _player.multiplayer_connection.is_own_player(_player)
	):
		# Disable the mouse from the view
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		set_process_input(false)
		queue_free()


func _input(event):
	if event.is_action_pressed(grab_mouse_key):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
