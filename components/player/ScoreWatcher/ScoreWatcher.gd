extends Node

class_name ScoreWatcher

# Reference to the parent node (assumed to be a Player node).
var _player: Player = null

@export var stats_synchronizer: StatsSynchronizer = null


func _ready():
	# Get the player; make sure this component is a child of the player's object.
	_player = get_parent()

	assert(
		_player.multiplayer_connection.map.round_synchronizer != null,
		"Can not get the round synchronizer"
	)

	if not _player.multiplayer_connection.is_server():
		queue_free()
		return

	stats_synchronizer.died.connect(_on_died)


func _on_died(killer_name: String):
	_player.multiplayer_connection.map.round_synchronizer.add_score(killer_name, _player.name)
