extends Node

class_name RoundSynchronizer

signal round_won_by(player_name: String)

@export var round_time: float = 300.0

var round_timer: Timer = null

var scores: Dictionary = {}

var _map: Map = null

var _player_spawn_synchronizer: PlayerSpawnerSynchronizer = null


# Called when the node enters the scene tree for the first time.
func _ready():
	_map = get_parent()

	# Ensure the player has a multiplayer connection
	assert(_map.multiplayer_connection != null, "Map's multiplayer connection is null")

	_player_spawn_synchronizer = (_map.multiplayer_connection.component_list.get_component(
		PlayerSpawnerSynchronizer.COMPONENT_NAME
	))

	assert(_player_spawn_synchronizer != null, "Failed to get PlayerSpawnerSynchronizer component")

	round_timer = Timer.new()
	round_timer.name = "RoundTimer"

	if _map.multiplayer_connection.is_server():
		round_timer.autostart = true
		round_timer.wait_time = round_time
	else:
		round_timer.autostart = false

	round_timer.timeout.connect(_on_round_timer_timeout)
	add_child(round_timer)

	# Server-side logic
	if _map.multiplayer_connection.is_server():
		_player_spawn_synchronizer.server_player_added.connect(_on_server_player_added)
		_player_spawn_synchronizer.server_player_removed.connect(_on_server_player_removed)


func add_kill(player_name: String):
	if not scores.has(player_name):
		return

	scores[player_name]["kills"] += 1


func add_death(player_name: String):
	if not scores.has(player_name):
		return

	scores[player_name]["deaths"] += 1


func _get_winner() -> String:
	var winner: String = ""
	var highest_kills: int = 0
	for player_name in scores:
		if scores[player_name]["kills"] > highest_kills:
			winner = player_name
			highest_kills = scores[player_name]["kills"]

	return winner


func _on_round_timer_timeout():
	var winner: String = _get_winner()

	round_won_by.emit(winner)

	# Reset the scores
	for player_name in scores:
		scores[player_name]["kills"] = 0
		scores[player_name]["deaths"] = 0


func _on_server_player_added(username: String, _peer_id: int):
	scores[username] = {"kills": 0, "deaths": 0}


func _on_server_player_removed(username: String):
	scores.erase(username)
