# This script extends CharacterBody3D and represents a player in the multiplayer game.
extends CharacterBody3D

# Define the class name for the script.
class_name Player

# Reference to the multiplayer connection component.
var multiplayer_connection: MultiplayerConnection = null

# The ID of the multiplayer connection.
var peer_id: int = 0

var player_client_authority_controller: PlayerClientAuthorityController = null

var network_view_synchronizer: NetworkViewSynchronizer = null

# Reference to the camera and head nodes.
@onready var camera: Camera3D = %Camera3D
@onready var head: Node3D = %Head


# Called when the node is added to the scene for the first time.
func _ready():
	# Add the player to the "players" group.
	add_to_group("players")

	player_client_authority_controller = get_node_or_null("PlayerClientAuthorityController")

	network_view_synchronizer = get_node_or_null("NetworkViewSynchronizer")

	# Check if the player is on the server side.
	if multiplayer_connection.is_server():
		# Don't handle input on the server side.
		set_process_input(false)
	else:
		# Check if the player is the local client's own player instance.
		if multiplayer_connection.is_own_player(self):
			# Use this camera on the client side.
			camera.current = true
		else:
			# Disable input processing for other clients' player instances.
			set_process_input(false)
