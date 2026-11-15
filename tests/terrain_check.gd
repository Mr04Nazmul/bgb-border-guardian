extends SceneTree
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.start_mission(0)
	for i in 60:
		await physics_frame
	var q := PhysicsRayQueryParameters3D.create(Vector3(0,10,8),Vector3(0,-10,8))
	q.exclude = [game.player.get_rid()]
	var hit: Dictionary = game.get_world_3d().direct_space_state.intersect_ray(q)
	assert(not hit.is_empty(), "Terrain must be hittable from above")
	assert(hit.normal.y > 0.9, "Playable camp must have upward terrain normals")
	assert(game.landscape.tea_count == 660)
	assert(game.player.is_on_floor())
	print("TERRAIN PASS: upward collision, landed character, 660 tea bushes")
	print("PLAYER ",game.player.position," velocity ",game.player.velocity," floor ",game.player.is_on_floor())
	if "--export-world" in OS.get_cmdline_user_args():
		var document := GLTFDocument.new()
		var state := GLTFState.new()
		var error := document.append_from_scene(game,state)
		assert(error == OK)
		error = document.write_to_filesystem(state,"/tmp/sylhet-world.glb")
		assert(error == OK)
	quit()
