extends Node3D
# Offline arena rules only. No real-world border procedures or military layouts.
var game: Node3D
var actors: Array[CharacterBody3D] = []
var active := false
var fire_held := false
var aim := false
var ammo := 24
var reserve := 144
var reload_left := 0.0
var shot_left := 0.0
var respawn_left := 0.0
var clock := 300.0
var score := [0,0]
var result := ""
var ticks := 0.0
var shot_audio: AudioStreamPlayer
var label: Label
var crosshair: Label
var rng := RandomNumberGenerator.new()
var traces: Array[Dictionary] = []
var controls: Array[Button] = []
const BattleRoyale = preload("res://scripts/battle_royale.gd")
var br: Node3D
var royale := false
const Actor = preload("res://scripts/combat_actor.gd")
func setup(owner_game: Node3D,root: Control) -> void:
	game = owner_game
	shot_audio=AudioStreamPlayer.new()
	shot_audio.stream=load("res://assets/sfx/shot.wav")
	shot_audio.volume_db= -18
	shot_audio.max_polyphony=3
	add_child(shot_audio)
	rng.seed = 201
	label = Label.new()
	label.position = Vector2(315,18)
	root.add_child(label)
	crosshair = Label.new()
	crosshair.text = "+"
	crosshair.add_theme_font_size_override("font_size",32)
	crosshair.position = Vector2(630,337)
	root.add_child(crosshair)
	crosshair.hide()
	var fire: Button = game.button(root,"FIRE",Vector2(955,490),Vector2(100,75),func(): pass)
	fire.button_down.connect(func(): fire_held=true)
	fire.button_up.connect(func(): fire_held=false)
	var reload_button: Button = game.button(root,"RELOAD",Vector2(925,580),Vector2(130,60),reload_weapon)
	var aim_button: Button = game.button(root,"AIM",Vector2(955,405),Vector2(100,60),func(): aim=not aim)
	controls.assign([fire,reload_button,aim_button])
	for control in controls:control.hide()
	br=BattleRoyale.new()
	add_child(br)
	br.setup(self,root)
	# Visible fictional divider; the river separates the two zones.
	for z in range(-160,170,20):
		var post: MeshInstance3D = game.box(Vector3(70,0.8,float(z)),Vector3(0.3,1.6,0.3),Color("e8dfbb"))
		post.name="FictionalBoundaryPost"
	for team in 2:
		var sign := Label3D.new()
		sign.text = "বাংলাদেশ-অনুপ্রাণিত পশ্চিম অঞ্চল\nWEST ZONE • FICTIONAL" if team==0 else "ভারত-অনুপ্রাণিত পূর্ব অঞ্চল\nEAST ZONE • FICTIONAL"
		sign.font = load("res://assets/Bengali.ttf")
		sign.font_size=45
		sign.pixel_size=0.025
		sign.position=Vector3(55 if team==0 else 111,5,-98)
		add_child(sign)
	# Ambient villagers also exist during non-combat missions.
	for i in 10:
		spawn_actor(2,Vector3(-76+float(i%4)*17,1,-58-float(i/4)*20))
func spawn_actor(team: int,pos: Vector3) -> CharacterBody3D:
	var actor := Actor.new()
	actor.arena=self
	actor.team=team
	actor.spawn_point=pos
	actor.position=pos
	actors.append(actor)
	add_child(actor)
	return actor
func start_match() -> void:
	stop_match()
	active=true
	result=""
	score=[0,0]
	clock=300
	ammo=24
	reserve=144
	reload_left=0
	respawn_left=0
	shot_left=0
	fire_held=false
	game.playing=true
	game.paused=false
	game.menu.hide()
	game.marker.hide()
	game.player.position=Vector3(35,1,-90)
	game.player.health=100
	game.player.velocity=Vector3.ZERO
	if game.player.driving:
		game.leave_vehicle()
		game.player.position=Vector3(35,1,-90)
	game.player.camera.make_current()
	for i in 8:
		spawn_actor(0,Vector3(32+float(i%4)*5,1,-108+float(i/4)*9))
	for i in 12:
		var x := 112+float(i%4)*6
		var z := -110+float(i/4)*10
		spawn_actor(1,Vector3(x,game.landscape.height_at(x,z)+1,z))
	crosshair.show()
	for control in controls:control.show()
func stop_match() -> void:
	if is_instance_valid(br):br.stop()
	royale=false
	active=false
	game.playing=false
	if is_instance_valid(shot_audio):shot_audio.stop()
	fire_held=false
	aim=false
	if is_instance_valid(game.player):game.player.camera.fov=70
	for control in controls:control.hide()
	for effect in traces:
		if is_instance_valid(effect.node):effect.node.queue_free()
	traces.clear()
	for actor in actors.duplicate():
		if is_instance_valid(actor) and actor.team!=2:
			actor.shot_audio.stop()
			actors.erase(actor)
			actor.queue_free()
	if is_instance_valid(crosshair):crosshair.hide()
	if is_instance_valid(label):label.text=""
	if is_instance_valid(game.marker):game.marker.show()
func reload_weapon() -> void:
	if active and not game.paused and respawn_left<=0 and reload_left<=0 and ammo<mag_capacity() and reserve>0:
		if royale:br.heal_left=0
		reload_left=1.8
func mag_capacity() -> int:
	return int(br.weapon_stat("mag",24)) if royale else 24
func damage_player(amount: float) -> void:
	if royale:
		br.damage_player(amount)
		return
	if not active or respawn_left>0 or not result.is_empty():return
	game.player.health=maxf(0,game.player.health-amount)
	if game.player.health<=0:
		if game.player.driving:game.leave_vehicle()
		score[1]+=1
		respawn_left=4
		fire_held=false
func actor_eliminated(actor: CharacterBody3D,killer: int) -> void:
	if royale:br.eliminated(actor,killer)
	else:add_point(killer)
func add_point(team: int) -> void:
	if active and result.is_empty():score[team]+=1
func ray(from: Vector3,to: Vector3,excluded: Array[RID]) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from,to)
	query.exclude=excluded
	return get_world_3d().direct_space_state.intersect_ray(query)
func fire_player() -> bool:
	if not active or game.paused or respawn_left>0 or reload_left>0 or shot_left>0 or game.player.driving or not result.is_empty():return false
	if royale and br.heal_left>0:
		br.heal_left=0
		return false
	if royale and br.inventory.is_empty():return false
	if ammo<=0:
		reload_weapon()
		return false
	shot_audio.play()
	ammo-=1
	shot_left=br.weapon_stat("interval",0.16) if royale else 0.16
	var camera: Camera3D=game.player.camera
	var start:=camera.global_position
	var target: Vector3=start-camera.global_basis.z*(br.weapon_stat("range",150) if royale else 160)
	var hit:=ray(start,target,[game.player.get_rid()])
	if not hit.is_empty():target=hit.position
	# Muzzle ray prevents shooting through a nearby wall with the chase camera.
	var muzzle: Vector3=game.player.position+Vector3(0,1.35,0)
	var obstruction:=ray(muzzle,target,[game.player.get_rid()])
	if not obstruction.is_empty():hit=obstruction;target=hit.position
	if not hit.is_empty() and hit.collider is CharacterBody3D and hit.collider in actors:
		var actor: CharacterBody3D=hit.collider
		if actor.team==1 or (royale and actor.team>=100):
			actor.receive_damage(br.weapon_stat("damage",34) if royale else 34,0)
			crosshair.modulate=Color("ffb46a")
		elif actor.team==2:
			game.notify(game.tr2("গ্রামের মানুষ লক্ষ্য নয়।","Civilians are not targets."))
	trace(muzzle,target,Color("ffe0a0"))
	return true
func trace(from: Vector3,to: Vector3,color: Color) -> void:
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINES)
	st.add_vertex(from)
	st.add_vertex(to)
	var mi:=MeshInstance3D.new()
	mi.mesh=st.commit()
	var mat:=StandardMaterial3D.new()
	mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color=color
	mi.material_override=mat
	add_child(mi)
	traces.append({"node":mi,"life":0.07})
func bot_fire(actor: CharacterBody3D,target: Node3D) -> void:
	if royale and (not actor.has_weapon or actor.rounds<=0 or actor.reload_timer>0):return
	var from: Vector3=actor.position+Vector3(0,1.35,0)
	var to: Vector3=target.position+Vector3(0,1.1,0)
	var hit:=ray(from,to,[actor.get_rid()])
	if hit.is_empty():return
	if hit.collider!=target and not (target==game.player and game.player.driving and hit.collider==game.jeep):return
	if royale:
		actor.rounds-=1
		br.bot_shots+=1
	actor.shot_audio.play()
	trace(from,to,Color("ffc36c") if actor.team==0 else Color("ff8d72"))
	if rng.randf()<0.52:
		if target==game.player:damage_player(9)
		else:target.receive_damage(12,actor.team)
func target_for(actor: CharacterBody3D) -> Node3D:
	var best: Node3D=null
	var nearest:=75.0
	if (actor.team==1 or royale) and respawn_left<=0 and (not royale or br.player_alive):
		var dist: float=actor.position.distance_to(game.player.position)
		if dist<nearest:best=game.player;nearest=dist
	for other in actors:
		if not is_instance_valid(other) or other.team==2 or other.team==actor.team or other.dead_left>0 or other.eliminated:continue
		var dist: float=actor.position.distance_to(other.position)
		if dist<nearest:best=other;nearest=dist
	return best
func finish() -> void:
	if not result.is_empty():return
	result=game.tr2("জয়!","Victory!") if score[0]>score[1] else (game.tr2("পরাজয়","Defeat") if score[0]<score[1] else game.tr2("ড্র","Draw"))
	game.paused=true
	fire_held=false
	game.clear_menu(result+"  "+str(score[0])+" — "+str(score[1]))
	game.item(game.tr2("আবার ম্যাচ খেলুন","Play again"),start_match)
	game.item(game.tr2("প্রধান মেনু","Main menu"),func():stop_match();game.show_menu())
func _process(dt: float) -> void:
	if not is_instance_valid(game) or game.paused or not game.playing:return
	for effect in traces.duplicate():
		effect.life-=dt
		if effect.life<=0:
			effect.node.queue_free()
			traces.erase(effect)
	if not active:return
	clock=maxf(0,clock-dt)
	shot_left=maxf(0,shot_left-dt)
	crosshair.modulate=crosshair.modulate.lerp(Color.WHITE,dt*8)
	if reload_left>0:
		reload_left-=dt
		if reload_left<=0:
			var amount:=mini(mag_capacity()-ammo,reserve)
			ammo+=amount
			reserve-=amount
	if respawn_left>0:
		respawn_left-=dt
		if respawn_left<=0:
			game.player.position=Vector3(35,1,-90)
			game.player.velocity=Vector3.ZERO
			game.player.health=100
			ammo=24
			reserve=maxi(reserve,72)
			game.player.yaw= -PI/2
	else:
		if game.player.health<=0:damage_player(100)
		if fire_held or (not DisplayServer.is_touchscreen_available() and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):fire_player()
	game.player.camera.fov=50 if aim else 70
	if royale:
		br.tick(dt)
		return
	label.text=game.tr2("অফলাইন দলীয় ম্যাচ","OFFLINE TEAM MATCH")+"  "+str(score[0])+" : "+str(score[1])+" / 30\n"+str(int(clock))+"s  •  "+str(ammo)+" / "+str(reserve)+(game.tr2(" • রিলোড"," • Reloading") if reload_left>0 else "")
	if respawn_left>0:label.text+="\n"+game.tr2("ফিরে আসবেন: ","Respawn: ")+str(ceili(respawn_left))+"s"
	if score[0]>=30 or score[1]>=30 or clock<=0:finish()
