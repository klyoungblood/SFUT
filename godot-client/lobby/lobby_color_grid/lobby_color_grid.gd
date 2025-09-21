extends Control

var colors = [Color.WHITE, Color.DEEP_PINK, Color.CYAN, Color.BLUE_VIOLET, Color.ROYAL_BLUE, Color.CORAL, Color.FOREST_GREEN, Color.CRIMSON, Color.GOLD]

func _ready() -> void:
	if LobbySystem:
		LobbySystem.signal_client_connection_confirmed.connect(func(_lobbyId): choose_random_color())
	
	var new_toggle_group = ButtonGroup.new()
	for color_string: Color in colors:
		var new_button = Button.new()
		new_button.custom_minimum_size = Vector2(30.0, 30.0)
		new_button.toggle_mode = true
		new_button.button_group = new_toggle_group
		new_button.toggled.connect(func(is_toggled): choose_color(is_toggled, color_string))
		#new_button.modulate = Color('ff52ff')
		var style_normal = StyleBoxFlat.new()
		style_normal.set_corner_radius_all(3)
		var temp = Color(color_string, 0.5)
		style_normal.bg_color = temp
		var style_pressed = StyleBoxFlat.new()
		style_pressed.bg_color = color_string
		style_pressed.set_corner_radius_all(3)
		new_button.add_theme_stylebox_override('normal', style_normal)
		new_button.add_theme_stylebox_override('pressed', style_pressed)
		new_button.add_theme_stylebox_override('hover', style_pressed)
		new_button.mouse_default_cursor_shape = 2
		%ColorGrid.add_child(new_button)
		
func choose_random_color():
	var random_color = randi_range(0, colors.size() - 1)
	var button_to_press: Button = %ColorGrid.get_child(random_color)
	button_to_press.set_pressed_no_signal(true)
	choose_color(true, colors[random_color])
	
func choose_color(toggled_on, color_string: Color):
	if toggled_on and LobbySystem:
		%ColorRect.color = color_string
		LobbySystem.user_update_info({ "color": color_string.to_html()})
