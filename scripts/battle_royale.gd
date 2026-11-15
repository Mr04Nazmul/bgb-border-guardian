extends Node3D
# Original offline solo battle royale: no network service or copied game assets.
var arena: Node3D
var loot: Array[Dictionary]=[]
var inventory: Array[String]=[]
var magazines: Dictionary={}
var selected:=0
var medkits:=0
var armor:=0.0
var kills:=0
var bot_shots:=0
var player_alive:=true
var heal_left:=0.0
var heal_origin:=Vector3.ZERO
var zone_center:=Vector2(0,45)
var zone_radius:=230.0
var next_center:=Vector2(0,45)
var next_radius:=170.0
var phase:=0
var phase_time:=0.0
var shrinking:=false
var start_center:=Vector2.ZERO
var start_radius:=230.0
var elapsed:=0.0
var wall: MeshInstance3D
var extra_controls: Array[Button]=[]
const WEAPONS={"pistol":{"mag":12,"damage":24,"interval":0.32,"range":80},"rifle":{"mag":24,"damage":34,"interval":0.16,"range":150},"shotgun":{"mag":6,"damage":65,"interval":0.85,"range":32}}
const RADII=[230.0,170.0,125.0,85.0,55.0,30.0,12.0,0.0]
func setup(owner_arena: Node3D,root: Control) -> void:
	arena=owner_arena
	extra_controls.append(arena.game.action_button(root,"HEAL",Vector2(810,575),Vector2(76,76),use_medkit))
	extra_controls.append(arena.game.action_button(root,"SWAP",Vector2(810,480),Vector2(76,76),switch_weapon))
	for b in extra_controls:b.hide()
	var mesh:=CylinderMesh.new()
	mesh.top_radius=1;mesh.bottom_radius=1;mesh.height=1;mesh.radial_segments=96
	mesh.cap_top=false;mesh.cap_bottom=false
	wall=MeshInstance3D.new();wall.mesh=mesh
	var mat:=StandardMaterial3D.new()
	mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color=Color(0.2,0.52,1,0.18)
	mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	wall.material_override=mat;wall.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(wall);wall.hide()
func start() -> void:
	arena.stop_match()
	arena.royale=true;arena.active=true;arena.result=""
	inventory.clear();magazines.clear();selected=0;medkits=0;armor=0;kills=0;bot_shots=0;player_alive=true
	heal_left=0;phase=0;phase_time=0;shrinking=false;elapsed=0
	zone_center=Vector2(0,45);zone_radius=230;next_center=zone_center;next_radius=170
	start_center=zone_center;start_radius=zone_radius
	arena.ammo=0;arena.reserve=0;arena.reload_left=0;arena.shot_left=0;arena.respawn_left=0
	arena.fire_held=false;arena.aim=false
	var game: Node3D=arena.game
	game.playing=true;game.paused=false;game.menu.hide();game.marker.hide()
	if game.player.driving:game.leave_vehicle()
	game.player.position=Vector3(-8,1,45);game.player.velocity=Vector3.ZERO;game.player.health=100
	game.player.prone=false;game.touch.reset();game.player.look_pending=Vector2.ZERO;game.player.crouched=false;game.player.running=false;game.player.camera.make_current()
	for actor in arena.actors:
		actor.hide();actor.collision_layer=0;actor.collision_mask=0;actor.set_physics_process(false)
	var spawns: Array[Vector2]=[Vector2(-150,-125),Vector2(-125,-80),Vector2(-130,-20),Vector2(-155,50),Vector2(-110,80),Vector2(-75,125),Vector2(130,30),Vector2(15,105),Vector2(45,70),Vector2(52,15),Vector2(38,-35),Vector2(25,-95),Vector2(-10,-125),Vector2(-45,-145),Vector2(135,-110),Vector2(160,80),Vector2(-50,45),Vector2(-90,20),Vector2(15,-145)]
	for i in spawns.size():
		var p:=spawns[i]
		var actor: CharacterBody3D=arena.spawn_actor(100+i,Vector3(p.x,game.landscape.height_at(p.x,p.y)+1,p.y))
		actor.has_weapon=false;actor.rounds=0;actor.reserve_rounds=0
		add_loot("rifle" if i%3==0 else "pistol",Vector3(p.x+3,0,p.y+2))
		add_loot("ammo",Vector3(p.x-3,0,p.y+2),48)
		if i%3==0:add_loot("medkit",Vector3(p.x+2,0,p.y-3))
		if i%4==0:add_loot("armor",Vector3(p.x-2,0,p.y-3))
	# A small visible starting supply, still requiring the player to loot it.
	add_loot("rifle",Vector3(-8,0,39));add_loot("ammo",Vector3(-6,0,39),72)
	add_loot("medkit",Vector3(-10,0,39));add_loot("armor",Vector3(-12,0,39))
	add_loot("shotgun",Vector3(5,0,-10));add_loot("ammo",Vector3(7,0,-10),36)
	arena.crosshair.show()
	for b in arena.controls:b.show()
	for b in extra_controls:b.show()
	wall.show();update_wall()
	game.notify(game.tr2("একবারই জীবন! E দিয়ে loot নিন। নীল zone এড়িয়ে চলুন।","One life! E to loot. Stay inside the blue zone."))
func stop() -> void:
	for item in loot:
		if is_instance_valid(item.node):item.node.queue_free()
	loot.clear()
	if is_instance_valid(wall):wall.hide()
	for b in extra_controls:b.hide()
	for actor in arena.actors:
		if actor.team==2:
			actor.show();actor.collision_layer=1;actor.collision_mask=1;actor.set_physics_process(true)
func weapon_id() -> String:
	return inventory[selected] if not inventory.is_empty() else ""
func weapon_stat(key: String,default_value: float) -> float:
	return float(WEAPONS.get(weapon_id(),{}).get(key,default_value))
func alive_count() -> int:
	var count:=1 if player_alive else 0
	for actor in arena.actors:
		if actor.team>=100 and not actor.eliminated:count+=1
	return count
func add_loot(kind: String,pos: Vector3,amount: int=1,loaded: int=-1) -> void:
	pos.y=arena.game.landscape.height_at(pos.x,pos.z)+0.35
	var node:=Node3D.new();node.position=pos;add_child(node)
	var mi:=MeshInstance3D.new();var mesh:=BoxMesh.new();mesh.size=Vector3(0.65,0.45,0.4);mi.mesh=mesh
	var mat:=StandardMaterial3D.new()
	mat.albedo_color=Color("d7b65e") if WEAPONS.has(kind) else {"ammo":Color("8fbba3"),"medkit":Color("eeefdb"),"armor":Color("7399c5")}.get(kind,Color.WHITE)
	mat.emission_enabled=true;mat.emission=mat.albedo_color*0.13;mi.material_override=mat;node.add_child(mi)
	var label:=Label3D.new();label.text=kind.to_upper();label.font_size=24;label.pixel_size=0.012;label.position.y=0.65
	label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.visibility_range_end=22;node.add_child(label)
	loot.append({"kind":kind,"pos":pos,"amount":amount,"loaded":loaded,"node":node})
func nearest_loot(pos: Vector3,weapon_only: bool=false) -> Dictionary:
	var best: Dictionary={};var distance:=INF
	for item in loot:
		if weapon_only and not WEAPONS.has(item.kind):continue
		var d: float=pos.distance_to(item.pos)
		if d<distance:distance=d;best=item
	return best
func consume(item: Dictionary) -> void:
	loot.erase(item)
	if is_instance_valid(item.node):item.node.queue_free()
func pickup_nearest() -> bool:
	if not arena.royale or arena.game.paused or not player_alive:return false
	var item:=nearest_loot(arena.game.player.position)
	if item.is_empty() or arena.game.player.position.distance_to(item.pos)>3:return false
	var kind: String=item.kind
	if WEAPONS.has(kind):
		var picked_rounds:=clampi(int(item.loaded) if int(item.loaded)>=0 else int(WEAPONS[kind].mag),0,int(WEAPONS[kind].mag))
		if inventory.has(kind):arena.reserve+=picked_rounds
		else:
			if not inventory.is_empty():magazines[weapon_id()]=arena.ammo
			if inventory.size()<2:inventory.append(kind);selected=inventory.size()-1
			else:
				add_loot(weapon_id(),arena.game.player.position+Vector3(1,0,0),1,arena.ammo);inventory[selected]=kind
			arena.ammo=picked_rounds;magazines[kind]=arena.ammo
			arena.reload_left=0;heal_left=0
	elif kind=="ammo":arena.reserve+=int(item.amount)
	elif kind=="medkit":medkits=mini(medkits+1,5)
	elif kind=="armor":armor=maxf(armor,75)
	consume(item)
	arena.game.notify(arena.game.tr2("নিয়েছেন: ","Picked up: ")+kind)
	return true
func switch_weapon() -> void:
	if not arena.royale or arena.game.paused or inventory.size()<2 or not player_alive:return
	magazines[weapon_id()]=arena.ammo;selected=(selected+1)%inventory.size()
	arena.ammo=int(magazines.get(weapon_id(),0));arena.reload_left=0;heal_left=0
func use_medkit() -> void:
	if not arena.royale or arena.game.paused or not player_alive or medkits<=0 or heal_left>0 or arena.game.player.health>=100:return
	heal_left=4;heal_origin=arena.game.player.position;arena.fire_held=false;arena.reload_left=0
func damage_player(amount: float,use_armor: bool=true) -> void:
	if not arena.active or arena.game.paused or not player_alive or not arena.result.is_empty():return
	heal_left=0
	var absorbed:=minf(armor,amount*0.5) if use_armor else 0.0;armor-=absorbed
	arena.game.player.health=maxf(0,arena.game.player.health-(amount-absorbed))
	if arena.game.player.health<=0:
		player_alive=false;arena.fire_held=false
		if arena.game.player.driving:arena.game.leave_vehicle()
		finish(false,alive_count()+1)
func eliminated(actor: CharacterBody3D,killer: int) -> void:
	if actor.eliminated:return
	actor.eliminated=true;actor.hide();actor.collision_layer=0;actor.collision_mask=0;actor.shot_audio.stop()
	if killer==0:kills+=1
	if actor.has_weapon:add_loot(actor.weapon_kind,actor.position,1,actor.rounds)
	if actor.reserve_rounds>0:add_loot("ammo",actor.position+Vector3(1,0,0),actor.reserve_rounds)
	if player_alive and alive_count()==1:finish(true,1)
func nearest_kind(pos: Vector3,kind: String) -> Dictionary:
	var best: Dictionary={};var distance:=INF
	for item in loot:
		if item.kind!=kind:continue
		var d: float=pos.distance_to(item.pos)
		if d<distance:best=item;distance=d
	return best
func bot_goal(actor: CharacterBody3D,default_goal: Vector3) -> Vector3:
	var item: Dictionary={}
	if not actor.has_weapon:item=nearest_loot(actor.position,true)
	elif actor.reserve_rounds+actor.rounds<=0:item=nearest_kind(actor.position,"ammo")
	elif actor.health<70:item=nearest_kind(actor.position,"medkit")
	if not item.is_empty() and actor.position.distance_to(item.pos)<2.5:
		if WEAPONS.has(item.kind):
			actor.has_weapon=true;actor.weapon_kind=item.kind
			actor.rounds=int(item.loaded) if int(item.loaded)>=0 else int(WEAPONS[item.kind].mag)
			actor.reserve_rounds+=24;consume(item)
		elif item.kind=="ammo":actor.reserve_rounds+=int(item.amount);consume(item)
		elif item.kind=="medkit":actor.health=minf(100,actor.health+30);consume(item)
		item={}
	var distance:=Vector2(actor.position.x,actor.position.z).distance_to(zone_center)
	if distance>maxf(2,zone_radius*0.72):return Vector3(zone_center.x,0,zone_center.y)
	if not item.is_empty():return item.pos
	return default_goal
func update_wall() -> void:
	wall.position=Vector3(zone_center.x,5,zone_center.y)
	wall.scale=Vector3(maxf(0.1,zone_radius),14,maxf(0.1,zone_radius))
func tick(dt: float) -> void:
	if not arena.royale or not arena.active or arena.game.paused or not arena.result.is_empty():return
	elapsed+=dt;phase_time+=dt
	if shrinking:
		var t:=minf(1,phase_time/30)
		zone_radius=lerpf(start_radius,next_radius,t);zone_center=start_center.lerp(next_center,t)
		if t>=1:
			shrinking=false;phase_time=0;phase+=1
			if phase<RADII.size()-1:
				next_radius=RADII[phase+1]
				var angle: float=arena.rng.randf_range(0,TAU)
				var shift:=minf(12,(zone_radius-next_radius)*0.35)
				next_center=zone_center+Vector2(cos(angle),sin(angle))*minf(shift,6)
				next_center.x=clampf(next_center.x,-3,3)
				next_center.y=clampf(next_center.y,40,55)
	elif phase<RADII.size()-1 and phase_time>=20:
		shrinking=true;phase_time=0;start_radius=zone_radius;start_center=zone_center
	update_wall()
	var damage:=float(2+phase*2)*dt
	if Vector2(arena.game.player.position.x,arena.game.player.position.z).distance_to(zone_center)>zone_radius:damage_player(damage,false)
	if not arena.result.is_empty():return
	for actor in arena.actors:
		if actor.team>=100 and not actor.eliminated and Vector2(actor.position.x,actor.position.z).distance_to(zone_center)>zone_radius:
			actor.receive_damage(damage,-1)
			if not arena.result.is_empty():break
	if heal_left>0:
		if arena.game.player.position.distance_to(heal_origin)>0.6 or arena.fire_held:heal_left=0
		else:
			heal_left-=dt
			if heal_left<=0:medkits-=1;arena.game.player.health=minf(100,arena.game.player.health+50)
	var nearby:=nearest_loot(arena.game.player.position)
	var hint: String=""
	if not nearby.is_empty() and arena.game.player.position.distance_to(nearby.pos)<3:hint="\n[E] LOOT: "+str(nearby.kind)
	var weapon:=weapon_id().to_upper() if not inventory.is_empty() else "UNARMED • E TO LOOT"
	arena.label.text="BATTLE ROYALE • "+arena.game.tr2("বেঁচে আছে: ","ALIVE: ")+str(alive_count())+"  KILLS: "+str(kills)+"\n"+weapon+"  "+str(arena.ammo)+" / "+str(arena.reserve)+"  ARMOR: "+str(int(armor))+"  MED: "+str(medkits)+"\nZONE "+str(phase+1)+" • "+("SHRINK " if shrinking else "WAIT ")+str(ceili(maxf(0,(30 if shrinking else 20)-phase_time)))+"s"+hint
	if heal_left>0:arena.label.text+="\nHEALING "+str(ceili(heal_left))+"s • Stay still"
	if player_alive and alive_count()==1:finish(true,1)
func finish(won: bool,rank: int) -> void:
	if not arena.result.is_empty():return
	arena.result=arena.game.tr2("শেষ পর্যন্ত বেঁচেছেন!","LAST SURVIVOR!") if won else arena.game.tr2("বাদ পড়েছেন","ELIMINATED")
	arena.game.paused=true;arena.fire_held=false
	arena.game.clear_menu(arena.result+"\nRANK #"+str(rank)+" / 20 • KILLS "+str(kills))
	arena.game.item(arena.game.tr2("আবার Battle Royale","Play Battle Royale again"),start)
	arena.game.item(arena.game.tr2("প্রধান মেনু","Main menu"),func():arena.stop_match();arena.game.show_menu())
