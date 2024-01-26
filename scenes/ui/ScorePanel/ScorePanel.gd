extends Control

class_name ScorePanel

@onready
var score_container: VBoxContainer = $VBoxContainer/PanelContainer2/ScrollContainer/VBoxContainer

@onready var _row_scene: Resource = preload("res://scenes/ui/ScorePanel/ScoreRow.tscn")

var _ui: UICanvas = null

var _poll_score_timer: Timer = null


func _ready():
	_ui = get_parent()

	_ui.player.multiplayer_connection.map.round_synchronizer.scores_updated.connect(
		_on_scores_updated
	)
	_poll_score_timer = Timer.new()
	_poll_score_timer.name = "PollScoreTimer"
	_poll_score_timer.autostart = true
	_poll_score_timer.wait_time = 1.0
	_poll_score_timer.timeout.connect(_on_poll_score_timer)
	add_child(_poll_score_timer)


func _input(event):
	if _ui.active:
		return

	if event.is_action_pressed("show_score"):
		visible = true

		_ui.player.multiplayer_connection.map.round_synchronizer.client_sync_scores()

	elif event.is_action_released("show_score"):
		visible = false


func _on_scores_updated():
	# Clear all the scores
	for child in score_container.get_children():
		child.queue_free()

	for player_name in _ui.player.multiplayer_connection.map.round_synchronizer.scores:
		var score = _ui.player.multiplayer_connection.map.round_synchronizer.scores[player_name]
		var row = _row_scene.instantiate()
		row.name = player_name
		row.set_values(player_name, score["kills"], score["deaths"])
		score_container.add_child(row)


func _on_poll_score_timer():
	if visible:
		_ui.player.multiplayer_connection.map.round_synchronizer.client_sync_scores()
