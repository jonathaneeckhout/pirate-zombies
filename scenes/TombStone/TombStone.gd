extends Node3D

class_name TombStone

@export var despawn_time: float = 10.0


# Called when the node enters the scene tree for the first time.
func _ready():
	await get_tree().create_timer(despawn_time).timeout
	queue_free()


func set_player_name(player_name: String):
	$PlayerNameLabel.text = player_name
