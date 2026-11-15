extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	var player: CharacterBody3D=game.player
	assert(player.avatar.name=="RafiMainCharacter")
	assert(player.front_card!=null and player.back_card!=null and player.side_card!=null)
	var front: MeshInstance3D=player.front_card
	var local_top: Vector3=player.avatar.transform*(front.get_aabb().position+front.get_aabb().size)
	assert(local_top.y>1.8 and local_top.y<2.0,"Uploaded Z-up character must stand upright at 1.9 m")
	player.camera.global_position=player.visual.to_global(Vector3(0,1.4,5))
	player.update_avatar_view()
	assert(player.back_card.visible and not player.front_card.visible and not player.side_card.visible)
	player.camera.global_position=player.visual.to_global(Vector3(0,1.4,-5))
	player.update_avatar_view()
	assert(player.front_card.visible and not player.back_card.visible)
	player.camera.global_position=player.visual.to_global(Vector3(5,1.4,0))
	player.update_avatar_view()
	assert(player.side_card.visible and not player.front_card.visible and not player.back_card.visible)
	game.start_mission(0)
	for i in 60:await physics_frame
	assert(player.is_on_floor())
	assert(player.avatar.is_visible_in_tree())
	player.first_person=true
	for i in 3:await physics_frame
	assert(not player.visual.visible,"First-person view must not obscure camera")
	player.first_person=false
	for i in 3:await physics_frame
	assert(player.visual.visible)
	game.settings_menu()
	game.load_game(false)
	game.queue_free()
	for i in 3:await process_frame
	print("RAFI PASS: uploaded model, upright scale, directional views, terrain landing, first/third-person visibility and settings/save compatibility")
	quit()
