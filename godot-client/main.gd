extends Node

@export var use_quick_connect: bool = false

var game_world = preload("res://game/world/world.tscn")

func _ready() -> void:
	if use_quick_connect:
		get_node_or_null("LobbyMenu").queue_free()
		get_node_or_null("LobbyQuickConnect").show()
	else:
		get_node_or_null("LobbyMenu").show()
		get_node_or_null("LobbyQuickConnect").queue_free()

	# Game start signal
	LobbySystem.signal_network_create_new_peer_connection.connect(new_game_connection)

func new_game_connection(_id):
	# TODO: Improve. This is fragile.
	if get_node_or_null("World") == null:
		if get_node_or_null("LobbyMenu"): get_node("LobbyMenu").hide()
		if get_node_or_null("LobbyQuickConnect"): get_node("LobbyQuickConnect").hide()
		var new_world = game_world.instantiate()
		add_child(new_world)
