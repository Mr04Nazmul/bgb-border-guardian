extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	var player: CharacterBody3D=game.player
	assert(player.avatar.name=="RafiRiggedMainCharacter")
	assert(player.skeleton.get_bone_count()==17)
	var body: MeshInstance3D=player.avatar.find_child("RafiSolidBody",true,false)
	assert(body.skin!=null and body.skin.get_bind_count()>=17,"Solid mesh must be skinned")
	assert(body.mesh.get_aabb().size.z>0.3,"Character must have volume, not a flat picture plane")
	for clip in ["idle","walk","run","jump","crouch","aim","reload"]:
		assert(player.animation_player.has_animation(clip))
		assert(player.animation_player.get_animation(clip).get_track_count()>0)
	var thigh: int=player.skeleton.find_bone("thigh.L")
	player.animation_player.play("walk",0)
	player.animation_player.advance(0.25)
	var walking: Quaternion=player.skeleton.get_bone_pose_rotation(thigh)
	assert(not walking.is_equal_approx(Quaternion.IDENTITY),"Walk clip must move a leg bone")
	player.animation_player.play("run",0)
	player.animation_player.advance(0.15)
	assert(not player.skeleton.get_bone_pose_rotation(thigh).is_equal_approx(walking))
	game.start_mission(0)
	for i in 60:await physics_frame
	assert(player.is_on_floor())
	game.touch.move_axis=Vector2(0,-1)
	for i in 15:await physics_frame
	assert(player.animation_state=="walk")
	player.running=true
	for i in 15:await physics_frame
	assert(player.animation_state=="run")
	game.touch.move_axis=Vector2.ZERO
	player.running=false
	player.jump_requested=true
	for i in 3:await physics_frame
	assert(player.animation_state=="jump")
	for i in 65:await physics_frame
	player.crouched=true
	for i in 15:await physics_frame
	assert(player.animation_state=="crouch" and player.body_collision.shape.height<1.75)
	player.crouched=false
	game.combat.start_match()
	for i in 60:await physics_frame
	game.combat.aim=true
	for i in 5:await physics_frame
	assert(player.animation_state=="aim" and player.weapon.visible)
	game.combat.ammo=1
	game.combat.reload_weapon()
	for i in 5:await physics_frame
	assert(player.animation_state=="reload")
	game.paused=true
	var time: float=player.animation_player.current_animation_position
	for i in 8:await physics_frame
	assert(is_equal_approx(time,player.animation_player.current_animation_position),"Pause must freeze animation")
	game.paused=false
	game.combat.stop_match()
	game.start_mission(0)
	player.first_person=true
	for i in 3:await physics_frame
	assert(not player.visual.visible)
	player.first_person=false
	for i in 3:await physics_frame
	assert(player.visual.visible)
	game.settings_menu()
	game.load_game(false)
	game.queue_free()
	for i in 20:await process_frame
	print("RAFI PASS: full-volume skinned body, 17 bones, seven clips, animated leg poses, walk/run/jump/crouch/aim/reload control transitions, pause, camera and save/settings compatibility")
	quit()
