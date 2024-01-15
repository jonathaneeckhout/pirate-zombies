extends CharacterBody3D

class_name Player

## The component used for the multiplayer functionality
var multiplayer_connection: MultiplayerConnection = null

## The id of the multiplayer connection
var peer_id: int = 0

@onready var camera: Camera3D = %Camera3D
@onready var head: Node3D = %Head


func _ready():
	# Add the player to the players group
	add_to_group("players")

	if multiplayer_connection.is_server():
		# Don't handle input on the server side
		set_process_input(false)
	else:
		if multiplayer_connection.is_own_player(self):
			# Use this camera on the client side
			camera.current = true
		else:
			set_process_input(false)
