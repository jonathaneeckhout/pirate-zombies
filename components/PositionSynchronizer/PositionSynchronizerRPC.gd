extends Node

class_name PositionSynchronizerRPC

const COMPONENT_NAME = "PositionSynchronizerRPC"

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


func sync_position(
	peer_id: int,
	player_name: String,
	timestamp: float,
	pos: Vector3,
	rotation_y: float,
	head_rotation_x: float
):
	_sync_position.rpc_id(peer_id, player_name, timestamp, pos, rotation_y, head_rotation_x)


@rpc("call_remote", "authority", "unreliable")
func _sync_position(n: String, t: float, p: Vector3, r: float, h: float):
	var player: Player = _multiplayer_connection.map.get_player_by_name(n)

	if player == null:
		return

	assert(player.position_synchronizer != null, "position_synchronizer is null")

	player.position_synchronizer.client_sync_position(t, p, r, h)
