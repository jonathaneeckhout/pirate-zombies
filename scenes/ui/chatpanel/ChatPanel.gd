extends Control

const GROUPS: Dictionary = {
	"Global": {"color": "WHITE"}, "Local": {"color": "LIGHT_BLUE"}, "Whisper": {"color": "VIOLET"}
}

var _current_group: String = "Global"
var _username: String = "player"
var _wisper_target: String = ""

var _delay_timer: Timer

var _ui: UICanvas = null

var _chat_rpc: ChatRPC = null

@onready var chat_log: RichTextLabel = $VBoxContainer/Logs/ChatLog
@onready var log_log: RichTextLabel = $VBoxContainer/Logs/LogLog

@onready var input_label: Label = $VBoxContainer/HBoxContainer/Label
@onready var input_field: LineEdit = $VBoxContainer/HBoxContainer/LineEdit


func _ready():
	_ui = get_parent()

	_username = _ui.player.name

	# Get the ClockSynchronizer component.
	_chat_rpc = _ui.player.multiplayer_connection.component_list.get_component(
		ChatRPC.COMPONENT_NAME
	)

	assert(_chat_rpc != null, "Failed to get ChatRPC component")

	input_field.text_submitted.connect(_on_text_submitted)

	change_group("Global")

	_chat_rpc.message_received.connect(_on_message_received)

	$VBoxContainer/SelectButtons/ChatButton.pressed.connect(_on_chat_button_pressed)
	$VBoxContainer/SelectButtons/LogsButton.pressed.connect(_on_logs_button_pressed)

	_delay_timer = Timer.new()
	_delay_timer.name = "DelayTimer"
	_delay_timer.one_shot = true
	_delay_timer.wait_time = 0.1
	_delay_timer.timeout.connect(_on__delay_timer_timeout)
	add_child(_delay_timer)


func _input(event):
	if event.is_action_pressed("ui_accept"):
		if input_field.has_focus():
			if input_field.text.strip_edges() == "":
				# Input is empty and enter is pressed, release focus
				input_field.release_focus()
				_ui.active = false
		else:
			# Input field doesn't have focus, grab it
			input_field.grab_focus()
			_ui.active = true

	if event.is_action_pressed("ui_cancel"):
		input_field.release_focus()
		# This timer is needed to prevent race conditions with other ui_cancel listeners
		_delay_timer.start()


func change_group(value: String):
	_current_group = value

	if _current_group == "Whisper" and _wisper_target != "":
		input_label.text = "[" + _wisper_target + "]"
	else:
		input_label.text = "[" + _current_group + "]"

	input_label.set("theme_override_colors/font_color", Color(GROUPS[_current_group]["color"]))


func escape_bbcode(bbcode_text: String) -> String:
	# We only need to replace opening brackets to prevent tags from being parsed.
	return bbcode_text.replace("[", "[lb]")


func append_chat_line_escaped(from: String, message: String, color: String = "WHITE"):
	chat_log.append_text(
		"[color=%s]%s: %s[/color]\n" % [color, escape_bbcode(from), escape_bbcode(message)]
	)


func _on_text_submitted(text: String):
	if text.is_empty():
		return

	_chat_rpc.send_message(_username, text)

	input_field.text = ""

	input_field.release_focus()

	_ui.active = false


func _on_message_received(from: String, message: String):
	append_chat_line_escaped(from, message, GROUPS["Global"]["color"])


func append_log_line(message: String, color: String = "YELLOW"):
	log_log.append_text("[color=%s]%s[/color]\n" % [color, escape_bbcode(message)])


func _on_chat_button_pressed():
	chat_log.show()
	log_log.hide()


func _on_logs_button_pressed():
	chat_log.hide()
	log_log.show()


func _on__delay_timer_timeout():
	_ui.active = false
