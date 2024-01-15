# This script extends Node3D, serving as a component to control mouse input.
extends Node3D

# Exported variable to set the key for grabbing and releasing the mouse.
@export var grab_mouse_key: String = "grab_mouse"

# Reference to the parent node (assumed to be a Player node).
var _player: Player = null

# Called when the node is added to the scene for the first time.
func _ready():
	# Get the parent node (assumed to be a Player node).
	_player = get_parent()

	# Ensure that the player's multiplayer connection is not null.
	assert(_player.multiplayer_connection != null, "Player's multiplayer connection is null")

	# Check if the player is a client and owns its player instance.
	if (
		not _player.multiplayer_connection.is_server()
		and _player.multiplayer_connection.is_own_player(_player)
	):
		# Disable the mouse from the view by capturing it.
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		# If not a client or not owning the player instance, disable input processing and free the node.
		set_process_input(false)
		queue_free()

# Called every frame. Handles mouse input events.
func _input(event):
	# Check if the grab_mouse_key is pressed.
	if event.is_action_pressed(grab_mouse_key):
		# Toggle between visible and captured mouse modes.
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
