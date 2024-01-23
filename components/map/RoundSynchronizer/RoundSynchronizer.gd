extends Node

class_name RoundSynchronizer

signal scores_updated
signal round_won_by(player_name: String)

@export var round_time: float = 300.0

var round_timer: Timer = null

var scores: Dictionary = {}

var _map: Map = null

# Reference to the ClockSynchronizer component for timestamp synchronization.
var _clock_synchronizer: ClockSynchronizer = null

var _player_spawn_synchronizer: PlayerSpawnerSynchronizer = null

var _round_synchronizer_rpc: RoundSynchronizerRPC = null


# Called when the node enters the scene tree for the first time.
func _ready():
	_map = get_parent()

	# Ensure the player has a multiplayer connection
	assert(_map.multiplayer_connection != null, "Map's multiplayer connection is null")

	# Get the ClockSynchronizer component.
	_clock_synchronizer = _map.multiplayer_connection.component_list.get_component(
		ClockSynchronizer.COMPONENT_NAME
	)

	# Ensure the ClockSynchronizer component is present
	assert(_clock_synchronizer != null, "Failed to get ClockSynchronizer component")

	_player_spawn_synchronizer = (_map.multiplayer_connection.component_list.get_component(
		PlayerSpawnerSynchronizer.COMPONENT_NAME
	))

	assert(_player_spawn_synchronizer != null, "Failed to get PlayerSpawnerSynchronizer component")

	_round_synchronizer_rpc = (_map.multiplayer_connection.component_list.get_component(
		RoundSynchronizerRPC.COMPONENT_NAME
	))

	assert(_round_synchronizer_rpc != null, "Failed to get RoundSynchronizerRPC component")

	round_timer = Timer.new()
	round_timer.name = "RoundTimer"
	round_timer.wait_time = round_time

	if _map.multiplayer_connection.is_server():
		round_timer.autostart = true
		round_timer.timeout.connect(_on_server_round_timer_timeout)
	else:
		round_timer.autostart = false
		round_timer.timeout.connect(_on_client_round_timer_timeout)

	add_child(round_timer)

	# Server-side logic
	if _map.multiplayer_connection.is_server():
		_player_spawn_synchronizer.server_player_added.connect(_on_server_player_added)
		_player_spawn_synchronizer.server_player_removed.connect(_on_server_player_removed)

	# Client-side logic
	else:
		#Wait until the connection is ready to synchronize stats
		if not multiplayer.has_multiplayer_peer():
			await multiplayer.connected_to_server

		#Wait an additional frame so others can get set.
		await get_tree().process_frame

		#Some entities take a bit to get added to the tree, do not update them until then.
		if not is_inside_tree():
			await tree_entered

		client_sync_round_clock()


func add_score(player_name_with_kill: String, player_name_with_death: String):
	if not scores.has(player_name_with_kill):
		return

	if not scores.has(player_name_with_death):
		return

	scores[player_name_with_kill]["kills"] += 1
	scores[player_name_with_death]["deaths"] += 1

	scores_updated.emit()


func client_sync_scores():
	_round_synchronizer_rpc.client_sync_scores()


func client_sync_response(data: Dictionary):
	scores = data

	scores_updated.emit()


func client_sync_round_clock():
	_round_synchronizer_rpc.client_sync_round_clock()


func client_sync_round_clock_response(timestamp: float, time_left: float):
	round_timer.stop()

	var diff: float = time_left - (_clock_synchronizer.client_clock - timestamp)

	round_timer.start(diff)


func _get_winner() -> String:
	var winner: String = ""
	var highest_kills: int = 0
	for player_name in scores:
		if scores[player_name]["kills"] > highest_kills:
			winner = player_name
			highest_kills = scores[player_name]["kills"]

	return winner


func _on_server_round_timer_timeout():
	var winner: String = _get_winner()

	round_won_by.emit(winner)

	# Reset the scores
	for player_name in scores:
		scores[player_name]["kills"] = 0
		scores[player_name]["deaths"] = 0


func _on_client_round_timer_timeout():
	client_sync_round_clock()


func _on_server_player_added(username: String, _peer_id: int):
	scores[username] = {"kills": 0, "deaths": 0}


func _on_server_player_removed(username: String):
	scores.erase(username)
