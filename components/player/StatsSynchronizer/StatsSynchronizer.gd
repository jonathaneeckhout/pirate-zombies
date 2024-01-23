extends Node

class_name StatsSynchronizer

enum TYPE { MAX_HP, HP }
enum SYNC_MESSAGE_TYPE { HURT, RESET_HP }

signal hurt(attacker_name: String, damage: int)
signal hp_reset(new_hp: int)
signal died(killer_name: String)

const MAX_HP_DEFAULT: int = 100

## Reference to the NetworkViewSynchronizer component
@export var network_view_synchronizer: NetworkViewSynchronizer

@export var max_hp: int = MAX_HP_DEFAULT
@export var hp: int = MAX_HP_DEFAULT

# Reference to the parent node (assumed to be a Player node).
var _player: Player = null

# Reference to the ClockSynchronizer component for timestamp synchronization.
var _clock_synchronizer: ClockSynchronizer = null

var _stats_synchronizer_rpc: StatsSynchronizerRPC = null

# Buffer which keeps track of all the sync information received from the server
var _server_buffer: Array[Dictionary] = []


func _ready():
	# Get the player; make sure this component is a child of the player's object.
	_player = get_parent()

	# Ensure the player has a multiplayer connection
	assert(_player.multiplayer_connection != null, "Player's multiplayer connection is null")

	# Get the ClockSynchronizer component.
	_clock_synchronizer = _player.multiplayer_connection.component_list.get_component(
		ClockSynchronizer.COMPONENT_NAME
	)

	# Ensure the ClockSynchronizer component is present
	assert(_clock_synchronizer != null, "Failed to get ClockSynchronizer component")

	# Get the StatsSynchronizerRPC component.
	_stats_synchronizer_rpc = _player.multiplayer_connection.component_list.get_component(
		StatsSynchronizerRPC.COMPONENT_NAME
	)

	# Ensure the StatsSynchronizerRPC component is present
	assert(_stats_synchronizer_rpc != null, "Failed to get StatsSynchronizerRPC component")

	# Don't handle the physics on the server
	if _player.multiplayer_connection.is_server():
		set_physics_process(false)
		return

	#Wait until the connection is ready to synchronize stats
	if not multiplayer.has_multiplayer_peer():
		await multiplayer.connected_to_server

	#Wait an additional frame so others can get set.
	await get_tree().process_frame

	#Some entities take a bit to get added to the tree, do not update them until then.
	if not is_inside_tree():
		await tree_entered

	_stats_synchronizer_rpc.sync_stats(_player.name)


func _physics_process(_delta):
	_check_server_buffer()


func _check_server_buffer():
	# Loop backwards
	for i in range(_server_buffer.size() - 1, -1, -1):
		var entry = _server_buffer[i]
		# Check when the projectile should be shot
		if entry["timestamp"] <= _clock_synchronizer.client_clock:
			match entry["type"]:
				SYNC_MESSAGE_TYPE.HURT:
					hp = entry["hp"]

					hurt.emit(entry["attacker"], entry["damage"])

					if hp <= 0:
						died.emit(entry["attacker"])

				SYNC_MESSAGE_TYPE.RESET_HP:
					hp = entry["hp"]

					hp_reset.emit(hp)

			# Remove the entry
			_server_buffer.remove_at(i)


func is_dead():
	return hp <= 0


func server_hurt(attacker: Player, damage: int):
	# Don't hurt the death
	if is_dead():
		return

	var reduced_hp: int = hp - damage
	# You died
	if reduced_hp <= 0:
		hp = 0
		died.emit(attacker.name)
	else:
		hp = reduced_hp

	var timestamp: float = Time.get_unix_time_from_system()

	# Sync the new hp to the owner of this component
	_stats_synchronizer_rpc.sync_hurt(
		_player.peer_id, _player.name, timestamp, attacker.name, hp, damage
	)

	# And to everyone looking at this owner
	for player in network_view_synchronizer.players_in_view:
		_stats_synchronizer_rpc.sync_hurt(
			player.peer_id, _player.name, timestamp, attacker.name, hp, damage
		)

	hurt.emit(attacker.name, damage)


func server_reset_hp():
	hp = max_hp

	var timestamp: float = Time.get_unix_time_from_system()

	# Sync the new hp to the owner of this component
	_stats_synchronizer_rpc.sync_reset_hp(_player.peer_id, _player.name, timestamp, hp)

	# And to everyone looking at this owner
	for player in network_view_synchronizer.players_in_view:
		_stats_synchronizer_rpc.sync_reset_hp(player.peer_id, _player.name, timestamp, hp)

	hp_reset.emit(hp)


func client_sync_hurt(timestamp: float, attacker_name: String, new_hp: int, damage: int):
	_server_buffer.append(
		{
			"type": SYNC_MESSAGE_TYPE.HURT,
			"timestamp": timestamp,
			"attacker": attacker_name,
			"hp": new_hp,
			"damage": damage
		}
	)


func client_reset_hp(timestamp: float, new_hp: int):
	_server_buffer.append(
		{"type": SYNC_MESSAGE_TYPE.RESET_HP, "timestamp": timestamp, "hp": new_hp}
	)


func server_sync_stats(id: int):
	_stats_synchronizer_rpc.sync_response(id, _player.name, {"hp": hp})


func client_sync_response(data: Dictionary):
	hp = data["hp"]
