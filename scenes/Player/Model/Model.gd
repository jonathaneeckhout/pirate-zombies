extends Node3D

@export var head: Node3D = null

@onready var skeleton: Skeleton3D = $Root/Skeleton3D

var _chest_number: int = 0


func _ready():
	_chest_number = skeleton.find_bone("Chest")


func _physics_process(_delta):
	skeleton.set_bone_pose_rotation(_chest_number, head.quaternion.inverse())
