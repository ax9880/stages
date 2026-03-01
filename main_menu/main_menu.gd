extends MarginContainer

const _MAX_PILES: int = 13

@export var start_button: Button

@export var piles_option_button: OptionButton
@export var players_option_button: OptionButton
@export var host_button: Button
@export var join_button: Button

@export var characters_button: Button

@export var multiplayer_is_desktop_only_label: Label

@export var host_h_box_container: HBoxContainer
@export var host_waiting_label: Label
@export var host_waiting_h_box_container: HBoxContainer

@export var join_h_box_container: HBoxContainer

@export var join_waiting_label: Label
@export var join_waiting_h_box_container: HBoxContainer

@export var host_port_text_edit: TextEdit

@export var ip_address_text_edit: TextEdit
@export var join_port_text_edit: TextEdit

@export var quit_button: AudioButton

func _ready() -> void:
	$Network/ServerConnector.stop()
	
	_on_full_screen_check_box_toggled(GameData.is_full_screen)
	
	$MarginContainer/VBoxContainer/StartButton.grab_focus()
	
	if GameData.players > 1:
		players_option_button.selected = GameData.players - 2
	
	piles_option_button.selected = GameData.piles - 3
	
	ip_address_text_edit.text = GameData.ip_address
	host_port_text_edit.text = str(GameData.port)
	join_port_text_edit.text = str(GameData.port)
	
	if OS.get_name() == "Web":
		host_h_box_container.visible = false
		join_h_box_container.visible = false
		
		multiplayer_is_desktop_only_label.visible = true
		
		quit_button.visible = false
	else:
		host_h_box_container.visible = true
		join_h_box_container.visible = true
		
		multiplayer_is_desktop_only_label.visible = false
	
	host_waiting_h_box_container.visible = false
	join_waiting_h_box_container.visible = false
	
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.server_disconnected.connect(_on_disconnected_to_server)
	
	_update_piles(piles_option_button.selected)
	_update_players(players_option_button.selected)


func _on_start_button_pressed() -> void:
	randomize()
	GameData.game_seed = randi()
	GameData.players = 1
	
	Loader.change_scene("res://board/game_tree.tscn")


func _on_characters_button_pressed() -> void:
	Loader.change_scene("res://characters_menu/characters.tscn")


func _on_quit_button_pressed() -> void:
	GameData.disconnect_network(true)
	
	get_tree().quit()


func _on_host_button_pressed() -> void:
	var text: String = host_port_text_edit.text
	
	if not text.is_valid_int():
		return
	
	var port: int = text.to_int()
	
	if port < 1023 or port > 65535:
		return
	
	_disable_buttons()
	
	host_waiting_label.text = tr("WAITING_FOR_PLAYERS")
	
	$Network/Server.start_server(port)
	
	host_h_box_container.visible = false
	host_waiting_h_box_container.visible = true


func _on_join_button_pressed() -> void:
	var text: String = join_port_text_edit.text
	
	if not text.is_valid_int():
		return
	
	var port: int = text.to_int()
	
	if port < 1023 or port > 65535:
		return
	
	_disable_buttons()
	
	join_waiting_label.text = tr("JOINING")
	
	$Network/ServerConnector.connect_to_server(ip_address_text_edit.text.strip_edges(), port)
	
	join_h_box_container.visible = false
	join_waiting_h_box_container.visible = true


func _on_piles_option_button_item_selected(index: int) -> void:
	GameData.piles = int(piles_option_button.get_item_text(index))
	
	var piles = GameData.piles
	
	while (GameData.players * GameData.piles + 1) > _MAX_PILES && players_option_button.selected >= 0:
		var next_selected: int = players_option_button.selected - 1
		
		_update_players(next_selected)
		
		players_option_button.select(next_selected)


func _on_players_option_button_item_selected(index: int) -> void:
	_update_players(index)
	
	while (GameData.players * GameData.piles + 1) > _MAX_PILES && piles_option_button.selected >= 0:
		var next_selected: int = piles_option_button.selected - 1
		
		_update_piles(next_selected)
		
		piles_option_button.select(next_selected)


func _update_piles(index: int) -> void:
	GameData.piles = int(piles_option_button.get_item_text(index))


func _update_players(index: int) -> void:
	GameData.players = int(players_option_button.get_item_text(index))


func _on_cancel_host_button_pressed() -> void:
	$Network/Server.stop_server()
	
	host_h_box_container.visible = true
	host_waiting_h_box_container.visible = false
	
	_enable_buttons()


func _enable_buttons() -> void:
	start_button.disabled = false
	piles_option_button.disabled = false
	players_option_button.disabled = false
	host_button.disabled = false
	join_button.disabled = false
	characters_button.disabled = false


func _disable_buttons() -> void:
	start_button.disabled = true
	piles_option_button.disabled = true
	players_option_button.disabled = true
	host_button.disabled = true
	join_button.disabled = true
	characters_button.disabled = true


func _on_server_on_peer_connection_status_change(connected_peers: int) -> void:
	host_waiting_label.text = "%s %d/%d" % [tr("WAITING_FOR_PLAYERS"), connected_peers + 1, GameData.players]


func _on_cancel_join_button_pressed() -> void:
	$Network/ServerConnector.stop()
	
	join_h_box_container.visible = true
	join_waiting_h_box_container.visible = false
	
	_enable_buttons()


func _on_connected_to_server() -> void:
	join_waiting_label.text = tr("CONNECTED")


func _on_disconnected_to_server() -> void:
	join_waiting_label.text = tr("JOINING")


func _on_full_screen_check_box_toggled(toggled_on: bool) -> void:
	GameData.is_full_screen = toggled_on
	
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
