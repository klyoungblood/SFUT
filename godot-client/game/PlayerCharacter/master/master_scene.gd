extends Node3D

class_name Master

#@export var animation_player: AnimationPlayer
#@export var bones: PhysicalBoneSimulator3D
@onready var player: PlayerCharacterShip = get_parent()

#var _player_input: PlayerInput

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if LobbySystem:
		LobbySystem.signal_lobby_own_info.connect(_on_get_own_lobby)

	if not is_multiplayer_authority():
		set_process(false)
		set_physics_process(false)
	
#	if is_multiplayer_authority():
#		cast_shadow_only()

#	_player_input = player.player_input
	player.health_system.death.connect(func(): _on_master_death.rpc())
	player.health_system.respawn.connect(func(): _on_master_respawn.rpc())
	
	#weapon_manager.player = player
	#weapon_manager.player_input = player.player_input

#	if not animation_player:
#		animation_player = $AnimationPlayer
#	$AnimationPlayer.speed_scale = 1
#	$AnimationPlayer.playback_default_blend_time = 0.2
	
#	if player.look_at_target.get_path():
#		$Armature/GeneralSkeleton/RightLower.target_node = player.look_at_target.get_path()
#		$Armature/GeneralSkeleton/LeftLower.target_node = player.look_at_target.get_path()
#		$Armature/GeneralSkeleton/LeftUpper.target_node = player.look_at_target.get_path()
#		$Armature/GeneralSkeleton/RightHand.target_node = player.look_at_target.get_path()
#		$Armature/GeneralSkeleton/LeftHand.target_node = player.look_at_target.get_path()

func set_mesh_color(new_color: Color):
	#TODO, fix this for the ship model
	pass
	#var mesh_material: StandardMaterial3D = %vanguard_Mesh.get_active_material(0)
	#var new_mat = mesh_material.duplicate() 
	#new_mat.albedo_color = new_color
	#%vanguard_Mesh.set_surface_override_material(0, new_mat)

#func cast_shadow_only():
	#%vanguard_Mesh.cast_shadow = 3
	#%vanguard_visor.cast_shadow = 3

#func _process(_delta):
#	on_animation_check()

@rpc('call_local', 'reliable')
func _on_master_death():
#	bones.physical_bones_start_simulation()
#	animation_player.active = false
	if is_multiplayer_authority():
		%vanguard_Mesh.cast_shadow = 1
		%vanguard_visor.cast_shadow = 1

@rpc('call_local', 'reliable')
func _on_master_respawn():
#	bones.physical_bones_stop_simulation()
#	animation_player.active = true
	if is_multiplayer_authority():
		%vanguard_Mesh.cast_shadow = 3
		%vanguard_visor.cast_shadow = 3

func _on_get_own_lobby(lobby):
	for _this_player in lobby.players:
		if _this_player.id == player.name:
			if _this_player.metadata.has('color'): 
				var _color: Color = Color.from_string(_this_player.metadata.color, Color.WHITE)
				set_mesh_color(_color)
