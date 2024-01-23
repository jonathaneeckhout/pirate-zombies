extends CanvasLayer

@export var player: Player = null

@export var stats_synchronizer: StatsSynchronizer = null

@onready var health_bar: TextureProgressBar = $HealthBar

@onready var round_time_label: Label = $RoundTimeLabel

const bar_green: Resource = preload("res://assets/healthbar/scaled/GreenBar.png")
const bar_yellow: Resource = preload("res://assets/healthbar/scaled/YellowBar.png")
const bar_red: Resource = preload("res://assets/healthbar/scaled/RedBar.png")

var _round_time_update_timer: Timer = null


func _ready():
	if not player.multiplayer_connection.is_own_player(player):
		queue_free()
		return

	update(stats_synchronizer.hp, stats_synchronizer.max_hp)

	stats_synchronizer.hurt.connect(_on_hurt)
	stats_synchronizer.hp_reset.connect(_on_hp_reset)

	_round_time_update_timer = Timer.new()
	_round_time_update_timer.wait_time = 0.2
	_round_time_update_timer.autostart = true
	_round_time_update_timer.timeout.connect(_on_round_time_update_timer)
	_round_time_update_timer.name = "RoundTimeUpdateTimer"
	add_child(_round_time_update_timer)


func update(amount, full):
	health_bar.texture_progress = bar_green
	if amount < 0.75 * full:
		health_bar.texture_progress = bar_yellow
	if amount < 0.45 * full:
		health_bar.texture_progress = bar_red
	health_bar.value = amount


func _on_hurt(_attacker_name: String, _damage: int):
	update(stats_synchronizer.hp, stats_synchronizer.max_hp)


func _on_hp_reset(_new_hp: int):
	update(stats_synchronizer.hp, stats_synchronizer.max_hp)


func _on_round_time_update_timer():
	var time_left: float = (
		player.multiplayer_connection.map.round_synchronizer.round_timer.time_left
	)

	round_time_label.text = (
		"Round Time left: %2d:%2d" % [floor(time_left / 60), int(time_left) % 60]
	)
