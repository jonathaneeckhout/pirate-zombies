extends HBoxContainer


func set_values(player_name: String, kills: int, deaths: int):
	$Name.text = player_name
	$Kills.text = str(kills)
	$Deaths.text = str(deaths)
