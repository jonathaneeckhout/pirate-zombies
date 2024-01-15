extends Node3D

class_name NetworkViewSynchronizer

const COMPONENT_NAME = "NetworkViewSynchronizer"

signal player_added(player_name: String, pos: Vector3)
signal player_removed(player_name: String)

var players_in_view: Array[Player] = []

var _player: Player = null

var _delay_timer: Timer = null

@onready var _network_view_area: Area3D = $NetworkViewArea


func _ready():
	_player = get_parent()

	assert(_player.multiplayer_connection != null, "Player's multiplayer connection is null")

	# Register the component with the parent player.
	_player.multiplayer_connection.component_list.register_component(COMPONENT_NAME, self)

	if _player.multiplayer_connection.is_server():
		_network_view_area.body_entered.connect(_on_body_network_view_area_body_entered)
		_network_view_area.body_exited.connect(_on_body_network_view_area_body_exited)

	elif _player.multiplayer_connection.is_own_player(_player):
		# This timer is needed to give the client some time to setup its multiplayer connection
		_delay_timer = Timer.new()
		_delay_timer.name = "DelayTimer"
		_delay_timer.wait_time = 0.1
		_delay_timer.autostart = true
		_delay_timer.one_shot = true
		_delay_timer.timeout.connect(_on_delay_timer_timeout)
		add_child(_delay_timer)


func client_add_player(player_name: String, pos: Vector3):
	player_added.emit(player_name, pos)


func client_remove_player(player_name: String):
	player_removed.emit(player_name)


# func sync_players_in_view():
# 	for player in players_in_view:
# 		Connection.sync_rpc.networkviewsynchronizer_add_player.rpc_id(
# 			_player.peer_id, _player.name, player.name, player.position
# 		)

# 		player_added.emit(player.name, player.position)


# func _on_body_network_view_area_body_entered(body: Node3D):
# 	# Don't handle the player
# 	if body == _player:
# 		return

# 	if not players_in_view.has(body):
# 		Connection.sync_rpc.networkviewsynchronizer_add_player.rpc_id(
# 			_player.peer_id, _player.name, body.name, body.position
# 		)

# 		player_added.emit(body.name, body.position)
# 		players_in_view.append(body)


# func _on_body_network_view_area_body_exited(body: Node3D):
# 	# Don't handle the player
# 	if body == _player:
# 		return

# 	if players_in_view.has(body):
# 		if _player.peer_id in multiplayer.get_peers():
# 			player_removed.emit(body.name)

# 			Connection.sync_rpc.networkviewsynchronizer_remove_player.rpc_id(
# 				_player.peer_id, _player.name, body.name
# 			)

# 		players_in_view.erase(body)


# func _on_delay_timer_timeout():
# 	Connection.sync_rpc.networkviewsynchronizer_sync_bodies_in_view.rpc_id(1)
# 	_delay_timer.queue_free()
