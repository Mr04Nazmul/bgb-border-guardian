extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	var arena: Node3D=game.combat
	var br: Node3D=arena.br
	br.start()
	assert(arena.royale and arena.active and br.alive_count()==20)
	assert(br.inventory.is_empty() and arena.ammo==0 and not arena.fire_player(),"Player must loot first")
	for actor in arena.actors:actor.set_physics_process(false)
	for item in br.loot.duplicate():br.consume(item)
	game.player.position=Vector3(0,0,45)
	br.add_loot("pistol",Vector3(0,0,45))
	assert(br.pickup_nearest() and br.weapon_id()=="pistol" and arena.ammo==12)
	br.add_loot("ammo",Vector3(0,0,45),60)
	assert(br.pickup_nearest() and arena.reserve==60)
	br.add_loot("rifle",Vector3(0,0,45));assert(br.pickup_nearest())
	assert(br.inventory.size()==2 and br.weapon_id()=="rifle")
	arena.ammo=7;br.switch_weapon()
	assert(br.weapon_id()=="pistol" and arena.ammo==12)
	br.switch_weapon();assert(arena.ammo==7,"Weapon swap preserves magazine")
	br.add_loot("shotgun",Vector3(0,0,45));assert(br.pickup_nearest())
	assert(br.inventory.size()==2 and br.weapon_id()=="shotgun" and arena.mag_capacity()==6)
	for item in br.loot.duplicate():br.consume(item)
	br.add_loot("armor",Vector3(0,0,45));assert(br.pickup_nearest())
	arena.damage_player(20)
	assert(game.player.health==90 and br.armor==65)
	br.damage_player(10,false)
	assert(game.player.health==80 and br.armor==65,"Zone damage ignores armor")
	br.add_loot("medkit",Vector3(0,0,45));assert(br.pickup_nearest())
	br.use_medkit();assert(br.heal_left==4)
	br.tick(4);assert(game.player.health==100 and br.medkits==0)
	br.medkits=1;game.player.health=40;br.use_medkit()
	game.player.position.x+=2;br.tick(0.1)
	assert(br.heal_left==0 and br.medkits==1,"Movement cancels heal without consuming kit")
	game.player.position=Vector3(0,0,45)
	for actor in arena.actors:
		if actor.team>=100:actor.position=Vector3(0,0,45)
	br.phase_time=0;br.tick(20)
	assert(br.shrinking)
	br.tick(30)
	assert(br.phase==1 and is_equal_approx(br.zone_radius,170),"Safe zone shrinks in phases")
	var radius: float=br.zone_radius
	var elapsed: float=br.elapsed
	game.paused=true;br.tick(20)
	assert(br.zone_radius==radius and br.elapsed==elapsed)
	game.paused=false
	var victim: CharacterBody3D=null
	for actor in arena.actors:
		if actor.team>=100:victim=actor;break
	victim.has_weapon=true;victim.reserve_rounds=12
	var previous_loot: int=br.loot.size()
	victim.receive_damage(100,0)
	assert(victim.eliminated and br.alive_count()==19 and br.kills==1)
	assert(br.loot.size()>previous_loot,"Elimination drops loot")
	victim._physics_process(30)
	assert(victim.eliminated and victim.health==0,"Battle royale has no respawn")
	var bot: CharacterBody3D=null
	for actor in arena.actors:
		if actor.team>=100 and not actor.eliminated:bot=actor;break
	for item in br.loot.duplicate():br.consume(item)
	br.add_loot("rifle",bot.position)
	br.bot_goal(bot,bot.position)
	assert(bot.has_weapon and bot.rounds>0,"Bots loot weapons")
	for actor in arena.actors.duplicate():
		if actor.team>=100 and not actor.eliminated:actor.receive_damage(1000,0)
	assert(br.alive_count()==1 and game.paused and not arena.result.is_empty())
	br.start()
	assert(br.alive_count()==20 and br.inventory.is_empty() and br.kills==0)
	br.armor=0;arena.damage_player(1000)
	assert(not br.player_alive and arena.respawn_left==0 and game.paused)
	arena.stop_match()
	assert(not arena.royale and arena.actors.size()==10 and br.loot.is_empty() and not br.wall.visible)
	game.queue_free()
	for i in 20:await process_frame
	print("BATTLE ROYALE PASS: 20 participants, unarmed start, loot, two-slot inventory, magazine persistence, armor, medkit/cancel, phased zone and pause, bot loot, elimination drops, no respawn, last survivor, player defeat and restart cleanup")
	quit()
