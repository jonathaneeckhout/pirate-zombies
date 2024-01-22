extends CanvasLayer

@export var player: Player = null

@export var stats_synchronizer: StatsSynchronizer = null

@onready var health_bar: TextureProgressBar = $HealthBar

const bar_green: Resource = preload("res://assets/healthbar/scaled/GreenBar.png")
const bar_yellow: Resource = preload("res://assets/healthbar/scaled/YellowBar.png")
const bar_red: Resource = preload("res://assets/healthbar/scaled/RedBar.png")


func _ready():
	if not player.multiplayer_connection.is_own_player(player):
		queue_free()
		return

	update(stats_synchronizer.hp, stats_synchronizer.max_hp)

	stats_synchronizer.hurt.connect(_on_hurt)
	stats_synchronizer.hp_reset.connect(_on_hp_reset)


func update(amount, full):
	health_bar.texture_progress = bar_green
	if amount < 0.75 * full:
		health_bar.texture_progress = bar_yellow
	if amount < 0.45 * full:
		health_bar.texture_progress = bar_red
	health_bar.value = amount


func _on_hurt(_damage: int):
	update(stats_synchronizer.hp, stats_synchronizer.max_hp)


func _on_hp_reset(_new_hp: int):
	update(stats_synchronizer.hp, stats_synchronizer.max_hp)
