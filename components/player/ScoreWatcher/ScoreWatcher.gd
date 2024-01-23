extends Node

class_name ScoreWatcher

# Reference to the parent node (assumed to be a Player node).
var _player: Player = null

@export var stats_synchronizer: StatsSynchronizer = null


func _ready():
	# Get the player; make sure this component is a child of the player's object.
	_player = get_parent()

	if not _player.multiplayer_connection.is_server():
		queue_free()
		return
