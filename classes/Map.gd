extends Node

class_name Map

## Node grouping all the players
var players: Node3D = null

## Node grouping all the projectiles
var projectiles: Node3D = null


func _ready():
	# Create the players node
	players = Node3D.new()
	players.name = "Players"
	add_child(players)

	# Create the projectiles node
	projectiles = Node3D.new()
	projectiles.name = "Projectiles"
	add_child(projectiles)
