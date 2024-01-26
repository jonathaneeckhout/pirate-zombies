extends Node

class_name ChatRPC

const COMPONENT_NAME = "ChatRPC"

signal message_received(from: String, message: String)

# Reference to the MultiplayerConnection parent node.
var _multiplayer_connection: MultiplayerConnection = null


# Called when the node enters the scene tree for the first time.
func _ready():
	# Get the MultiplayerConnection parent node.
	_multiplayer_connection = get_parent()

	# Register the component with the parent MultiplayerConnection.
	_multiplayer_connection.component_list.register_component(COMPONENT_NAME, self)

	# Wait until the multiplayer connection is initialized.
	await _multiplayer_connection.init_done


func send_message(from: String, message: String):
	_send_message.rpc(from, message)


@rpc("call_local", "any_peer", "reliable")
func _send_message(from: String, message: String):
	message_received.emit(from, message)
