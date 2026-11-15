extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.combat.br.start()
	game.player.health=10000
	Engine.time_scale=8
	for i in 600:await physics_frame
	Engine.time_scale=1
	var br: Node3D=game.combat.br
	var armed:=0
	for actor in game.combat.actors:
		if actor.team>=100 and actor.has_weapon:armed+=1
	assert(armed>0,"Bots must autonomously acquire loot")
	assert(br.bot_shots>0,"Bots must autonomously target and fire")
	assert(br.alive_count()<20,"Autonomous elimination must occur")
	print("BATTLE SIM PASS: ",armed," bots acquired weapons; ",br.bot_shots," bot shots; ",br.alive_count()," survivors")
	game.combat.stop_match()
	game.queue_free()
	for i in 20:await process_frame
	quit()
