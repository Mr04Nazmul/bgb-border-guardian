extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.combat.start_match()
	var arena: Node3D=game.combat
	assert(arena.actors.size()==29,"19 bots plus 10 civilians; player makes balanced 10v10")
	for i in 60:await physics_frame
	assert(game.player.is_on_floor())
	assert(arena.fire_player())
	assert(arena.ammo==23)
	assert(not arena.fire_player(),"Fire rate must be enforced")
	arena.ammo=2
	arena.reload_weapon()
	assert(arena.reload_left>0)
	assert(not arena.fire_player(),"Cannot fire while reloading")
	arena._process(2)
	assert(arena.ammo==24 and arena.reserve==122)
	var enemy: CharacterBody3D=null
	var civilian: CharacterBody3D=null
	for a in arena.actors:
		if a.team==1:enemy=a
		if a.team==2:civilian=a
	# Aim a real physics ray through the camera and muzzle at an opponent.
	for a in arena.actors:a.set_physics_process(false)
	game.player.position=Vector3(30,1,-25)
	enemy.position=Vector3(30,1,-45)
	for i in 3:await physics_frame
	game.player.camera.look_at(enemy.position+Vector3(0,1.2,0),Vector3.UP)
	arena.shot_left=0
	assert(arena.fire_player())
	assert(enemy.health==66,"Aimed hitscan must damage opponent")
	var wall: MeshInstance3D=game.box(Vector3(30,1.5,-35),Vector3(3,3,1),Color.GRAY)
	for i in 3:await physics_frame
	game.player.camera.look_at(enemy.position+Vector3(0,1.2,0),Vector3.UP)
	arena.shot_left=0
	assert(arena.fire_player())
	assert(enemy.health==66,"Walls must block gunfire")
	wall.queue_free()
	var before: int=arena.score[0]
	enemy.receive_damage(100,0)
	assert(enemy.dead_left>0 and arena.score[0]==before+1)
	enemy.receive_damage(100,0)
	assert(arena.score[0]==before+1,"No duplicate kill score")
	civilian.receive_damage(100,0)
	assert(civilian.health==100,"Civilian protection")
	arena.damage_player(100)
	assert(arena.respawn_left>0 and game.player.health==0)
	arena._process(5)
	assert(game.player.health==100 and arena.respawn_left<=0)
	game.paused=true
	var timer: float=arena.clock
	arena._process(10)
	assert(arena.clock==timer,"Pause freezes match")
	game.paused=false
	arena.score=[30,0]
	arena._process(0.1)
	assert(not arena.result.is_empty() and game.paused)
	arena.start_match()
	assert(arena.actors.size()==29,"Restart must not duplicate actors")
	arena.stop_match()
	assert(arena.actors.size()==10)
	game.queue_free()
	for i in 20:await process_frame
	print("COMBAT PASS: actor population, hitscan damage and wall occlusion, fire rate, reload/ammo, elimination scoring, civilian protection, player respawn, pause, victory and restart cleanup")
	quit()
