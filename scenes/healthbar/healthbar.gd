extends Sprite3D

@onready var progress_bar: TextureProgressBar = $SubViewport/ProgressBar

const bar_green: Resource = preload("res://assets/healthbar/scaled/GreenBar.png")
const bar_yellow: Resource = preload("res://assets/healthbar/scaled/YellowBar.png")
const bar_red: Resource = preload("res://assets/healthbar/scaled/RedBar.png")

@export var stats_synchronizer: StatsSynchronizer = null

var _player: Player = null


func _ready():
	_player = get_parent()
	$SubViewport/Player.text = _player.name

	stats_synchronizer.hurt.connect(_on_hurt)
	stats_synchronizer.hp_reset.connect(_on_hp_reset)


func update(amount, full):
	progress_bar.texture_progress = bar_green
	if amount < 0.75 * full:
		progress_bar.texture_progress = bar_yellow
	if amount < 0.45 * full:
		progress_bar.texture_progress = bar_red
	progress_bar.value = amount


func _on_hurt(_attacker_name: String, _damage: int):
	update(stats_synchronizer.hp, stats_synchronizer.max_hp)


func _on_hp_reset(_new_hp: int):
	update(stats_synchronizer.hp, stats_synchronizer.max_hp)
