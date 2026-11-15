extends Node3D
# Original offline survival systems, shared by solo and squad BR.
var br: Node3D
var arena: Node3D
var squad:=false
var spectating:=false
var capacity:=120.0
var bandages:=0
var drinks:=0
var grenades:=0
var smoke_charges:=0
var cover_charges:=0
var helmet:=0.0
var attachments: Dictionary={}
var heal_kind:="medkit"
var boost_left:=0.0
var auto_pickup:=true
var pickup_left:=0.0
var projectiles: Array[Dictionary]=[]
var smokes: Array[Dictionary]=[]
var covers: Array[Dictionary]=[]
var player_downed:=false
var player_bleed:=0.0
var revive_target: CharacterBody3D
var revive_left:=0.0
var rescue_progress: Dictionary={}
const SPECIAL=["bandage","energy","grenade","smoke","cover","helmet","backpack","scope","extended_mag","grip"]
func setup(owner_br: Node3D,root: Control) -> void:
	br=owner_br;arena=br.arena
	for spec in [["BAG",Vector2(245,440),open_bag],["GREN",Vector2(360,535),throw_frag],["SMOKE",Vector2(435,535),throw_smoke],["COVER",Vector2(510,535),deploy_cover]]:
		var b: Button=arena.game.action_button(root,spec[0],spec[1],Vector2(64,64),spec[2])
		b.set_meta("royale",true);br.extra_controls.append(b);b.hide()
func reset(as_squad: bool=false) -> void:
	cleanup();squad=as_squad;spectating=false;capacity=120;bandages=0;drinks=0;grenades=0;smoke_charges=0;cover_charges=0;helmet=0
	attachments.clear();heal_kind="medkit";boost_left=0;pickup_left=0;player_downed=false;player_bleed=0;revive_target=null;revive_left=0;rescue_progress.clear()
func cleanup() -> void:
	for collection in [projectiles,smokes,covers]:
		for item in collection:
			if is_instance_valid(item.node):item.node.queue_free()
		collection.clear()
func playing() -> bool:
	return arena.royale and arena.active and not arena.game.paused and br.player_alive and arena.result.is_empty()
func weight() -> float:
	return br.inventory.size()*20+arena.reserve*.1+br.medkits*8+bandages*2+drinks*4+(grenades+smoke_charges+cover_charges)*6
func room_for(kind: String,amount: int) -> int:
	var unit: float={"ammo":.1,"medkit":8.0,"bandage":2.0,"energy":4.0,"grenade":6.0,"smoke":6.0,"cover":6.0}.get(kind,0.0)
	if unit<=0:return amount
	return mini(amount,maxi(0,int(floor((capacity-weight()+.001)/unit))))
func accept_special(kind: String) -> bool:
	if room_for(kind,1)<=0:return false
	match kind:
		"bandage":
			if bandages>=5:return false
			bandages+=1
		"energy":
			if drinks>=3:return false
			drinks+=1
		"grenade":
			if grenades>=3:return false
			grenades+=1
		"smoke":
			if smoke_charges>=3:return false
			smoke_charges+=1
		"cover":
			if cover_charges>=2:return false
			cover_charges+=1
		"helmet":
			if helmet>=60:return false
			helmet=60
		"backpack":
			if capacity>=200:return false
			capacity=200
		"scope","extended_mag","grip":
			if br.inventory.is_empty():return false
			var gun: String=br.weapon_id()
			if not attachments.has(gun):attachments[gun]={}
			if attachments[gun].has(kind):return false
			attachments[gun][kind]=true
		_:return false
	return true
func attached(kind: String) -> bool:
	return bool(attachments.get(br.weapon_id(),{}).get(kind,false))
func mag_bonus() -> int:return 8 if attached("extended_mag") else 0
func start_heal(kind: String) -> void:
	if not playing() or player_downed or br.heal_left>0:return
	var p: CharacterBody3D=arena.game.player
	if kind=="medkit" and (br.medkits<=0 or p.health>=100):return
	if kind=="bandage" and (bandages<=0 or p.health>=75):return
	if kind=="energy" and drinks<=0:return
	heal_kind=kind;br.heal_left=4 if kind=="medkit" else 2;br.heal_origin=p.position
	arena.fire_held=false;arena.mouse_fire=false;arena.fire_sources.clear();arena.reload_left=0
func complete_heal() -> void:
	var p: CharacterBody3D=arena.game.player
	match heal_kind:
		"medkit":br.medkits=maxi(0,br.medkits-1);p.health=minf(100,p.health+50)
		"bandage":bandages=maxi(0,bandages-1);p.health=minf(75,p.health+15)
		"energy":drinks=maxi(0,drinks-1);boost_left=15
func open_bag() -> void:
	if not arena.active or not arena.royale or not br.player_alive:return
	var game: Node3D=arena.game
	game.paused=true;game.touch.reset();arena.fire_held=false;arena.mouse_fire=false;arena.fire_sources.clear()
	game.clear_menu("BACKPACK • "+str(roundi(weight()))+" / "+str(int(capacity)))
	for i in br.inventory.size():
		var gun: String=br.inventory[i]
		game.item(("✓ " if i==br.selected else "")+gun.to_upper()+" • DROP",drop_weapon.bind(i))
	game.item("AMMO "+str(arena.reserve)+" • DROP 30",drop_ammo)
	game.item("MED "+str(br.medkits)+" • DROP 1",drop_medkit)
	game.item("BANDAGE "+str(bandages)+" • USE",bag_heal.bind("bandage"))
	game.item("ENERGY "+str(drinks)+" • USE",bag_heal.bind("energy"))
	game.item("Auto pickup • "+("ON" if auto_pickup else "OFF"),func():auto_pickup=not auto_pickup;open_bag())
	var info:=Label.new();info.text="HELMET "+str(int(helmet))+" • GREN "+str(grenades)+" • SMOKE "+str(smoke_charges)+"\n"+str(attachments.get(br.weapon_id(),{}).keys());info.add_theme_font_size_override("font_size",15);game.menu_box.add_child(info)
	game.item("ফিরে যান • RESUME",game.resume)
func bag_heal(kind: String) -> void:arena.game.resume();start_heal(kind)
func drop_ammo() -> void:
	var amount:=mini(30,arena.reserve)
	if amount>0:arena.reserve-=amount;br.add_loot("ammo",arena.game.player.position+Vector3(1,0,0),amount);br.loot[-1].pickup_after=br.elapsed+4
	open_bag()
func drop_medkit() -> void:
	if br.medkits>0:br.medkits-=1;br.add_loot("medkit",arena.game.player.position+Vector3(1,0,0))
	open_bag()
func drop_weapon(index: int) -> void:
	if index<0 or index>=br.inventory.size():return
	var gun: String=br.inventory[index]
	var rounds: int=arena.ammo if index==br.selected else int(br.magazines.get(gun,0))
	br.add_loot(gun,arena.game.player.position+Vector3(1,0,0),1,rounds)
	br.inventory.remove_at(index);br.magazines.erase(gun)
	for kind in attachments.get(gun,{}).keys():br.add_loot(kind,arena.game.player.position+Vector3(-1,0,0))
	attachments.erase(gun);br.selected=0;arena.ammo=int(br.magazines.get(br.weapon_id(),0));arena.reload_left=0;br.heal_left=0
	open_bag()
func sphere(color: Color,radius: float) -> MeshInstance3D:
	var node:=MeshInstance3D.new();var mesh:=SphereMesh.new();mesh.radius=radius;mesh.height=radius*2;mesh.radial_segments=12;mesh.rings=6;node.mesh=mesh
	var mat:=StandardMaterial3D.new();mat.albedo_color=color
	if color.a<1:mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	node.material_override=mat;add_child(node);return node
func throw_frag() -> void:throw_item("frag")
func throw_smoke() -> void:throw_item("smoke")
func throw_item(kind: String) -> void:
	if not playing() or player_downed or arena.game.player.driving:return
	if (kind=="frag" and grenades<=0) or (kind=="smoke" and smoke_charges<=0):return
	if kind=="frag":grenades-=1
	else:smoke_charges-=1
	var p: CharacterBody3D=arena.game.player
	var node:=sphere(Color("758064"),.12)
	node.position=p.position+Vector3(0,.55 if p.prone else 1.2,0)-p.camera.global_basis.z*.5
	projectiles.append({"node":node,"velocity":-p.camera.global_basis.z*12+Vector3.UP*4,"fuse":2.5,"kind":kind})
func explode(pos: Vector3) -> void:
	var excluded: Array[RID]=[arena.game.player.get_rid()]
	for actor in arena.actors:
		if not arena.hostile_to_player(actor):continue
		var point: Vector3=actor.position+Vector3(0,.6,0)
		var distance:=pos.distance_to(point)
		if distance>6:continue
		var hit: Dictionary=arena.ray(pos+Vector3.UP*.2,point,excluded)
		if hit.is_empty() or hit.collider==actor:actor.receive_damage(maxf(15,100*(1-distance/6)),arena.player_team())
	var p: CharacterBody3D=arena.game.player
	if pos.distance_to(p.position+Vector3.UP)<6:
		var hit: Dictionary=arena.ray(pos+Vector3.UP*.2,p.position+Vector3.UP,excluded)
		if hit.is_empty():br.damage_player(75*(1-pos.distance_to(p.position+Vector3.UP)/6))
	var flash:=sphere(Color(1,.6,.15,.5),2.0);flash.position=pos
	smokes.append({"node":flash,"radius":0.0,"life":.2})
func line_smoked(from: Vector3,to: Vector3) -> bool:
	var segment:=to-from
	for smoke in smokes:
		if smoke.radius<=0:continue
		var t:=clampf((smoke.node.position-from).dot(segment)/maxf(.001,segment.length_squared()),0,1)
		if (from+segment*t).distance_to(smoke.node.position)<smoke.radius:return true
	return false
func deploy_cover() -> void:
	if not playing() or player_downed or cover_charges<=0:return
	var p: CharacterBody3D=arena.game.player
	var pos: Vector3=p.position+Basis(Vector3.UP,p.yaw)*Vector3(0,0,-2.5)+Vector3.UP
	var shape:=BoxShape3D.new();shape.size=Vector3(2.8,1.8,.3)
	var q:=PhysicsShapeQueryParameters3D.new();q.shape=shape;q.transform=Transform3D(Basis(Vector3.UP,p.yaw),pos);q.exclude=[p.get_rid()]
	if not get_world_3d().direct_space_state.intersect_shape(q,1).is_empty():return
	var node: MeshInstance3D=arena.game.box(pos,shape.size,Color("67898a"));node.rotation.y=p.yaw
	covers.append({"node":node,"hp":240.0,"life":20.0});cover_charges-=1
func hit_cover(collider: Object,damage: float) -> void:
	for cover in covers:
		if collider.get_parent()==cover.node:
			cover.hp-=damage
			if cover.hp<=0:cover.life=0
func tick_items(dt: float) -> void:
	if boost_left>0 and not player_downed and br.player_alive:
		boost_left=maxf(0,boost_left-dt);arena.game.player.health=minf(100,arena.game.player.health+dt*1.5);arena.game.player.stamina=minf(100,arena.game.player.stamina+dt*6)
	for shot in projectiles.duplicate():
		var previous: Vector3=shot.node.position
		shot.velocity.y-=12*dt
		var next: Vector3=previous+shot.velocity*dt
		var excluded: Array[RID]=[arena.game.player.get_rid()]
		var hit: Dictionary=arena.ray(previous,next,excluded)
		if not hit.is_empty():shot.node.position=hit.position+hit.normal*.13;shot.velocity=shot.velocity.bounce(hit.normal)*.4
		else:shot.node.position=next
		shot.fuse-=dt
		if shot.fuse<=0:
			if shot.kind=="frag":explode(shot.node.position)
			else:
				var node:=sphere(Color(.7,.75,.72,.32),4.0);node.position=shot.node.position+Vector3.UP
				smokes.append({"node":node,"radius":4.0,"life":8.0})
			shot.node.queue_free();projectiles.erase(shot)
	for smoke in smokes.duplicate():
		smoke.life-=dt
		if smoke.life<=0:smoke.node.queue_free();smokes.erase(smoke)
	for cover in covers.duplicate():
		cover.life-=dt
		if cover.life<=0:cover.node.queue_free();covers.erase(cover)
	if auto_pickup and not player_downed and br.player_alive:
		pickup_left-=dt
		if pickup_left<=0:
			pickup_left=.6
			var item: Dictionary=br.nearest_loot(arena.game.player.position)
			if not item.is_empty() and not br.WEAPONS.has(item.kind) and float(item.get("pickup_after",0))<=br.elapsed and arena.game.player.position.distance_to(item.pos)<1.7:br.pickup_nearest()
func active_teammate(team: int,except_actor: CharacterBody3D=null) -> bool:
	if team==100 and br.player_alive and not player_downed:return true
	for actor in arena.actors:
		if actor!=except_actor and actor.team==team and not actor.eliminated and not actor.downed:return true
	return false
func knock_actor(actor: CharacterBody3D) -> bool:
	if not squad or not active_teammate(actor.team,actor):return false
	actor.downed=true;actor.bleed_left=25;actor.health=1;actor.reload_timer=0;actor.velocity=Vector3.ZERO
	return true
func knock_player() -> bool:
	if not squad:return false
	var ally_available:=false
	for actor in arena.actors:
		if actor.team==100 and not actor.eliminated and not actor.downed:ally_available=true
	if not ally_available:return false
	player_downed=true;player_bleed=25;arena.game.player.health=1;arena.game.player.prone=true;arena.game.player.crouched=false
	arena.fire_held=false;arena.mouse_fire=false;arena.fire_sources.clear();arena.aim=false;br.heal_left=0
	return true
func damage_downed(actor: CharacterBody3D,amount: float,killer: int) -> void:
	actor.bleed_left-=amount*.3
	if actor.bleed_left<=0:finish_actor(actor,killer)
func finish_actor(actor: CharacterBody3D,killer: int) -> void:
	actor.downed=false;actor.health=0;br.eliminated(actor,killer,true)
func revive_actor(actor: CharacterBody3D) -> void:
	actor.downed=false;actor.health=35;actor.bleed_left=0;actor.crouched=false
	rescue_progress.erase(actor.get_instance_id())
func revive_player() -> void:
	player_downed=false;player_bleed=0;arena.game.player.health=35;arena.game.player.prone=false;arena.game.player.crouched=true
	rescue_progress.erase(0)
func nearby_downed() -> CharacterBody3D:
	for actor in arena.actors:
		if actor.team==100 and actor.downed and not actor.eliminated and actor.position.distance_to(arena.game.player.position)<2.8:return actor
	return null
func begin_revive() -> bool:
	if not playing() or not squad or player_downed:return false
	var target:=nearby_downed()
	if not is_instance_valid(target):return false
	revive_target=target;revive_left=3;br.heal_left=0
	arena.fire_held=false;arena.mouse_fire=false;arena.fire_sources.clear()
	return true
func rescue_goal(actor: CharacterBody3D) -> Vector3:
	if not squad or actor.downed:return Vector3.INF
	if actor.team==100 and player_downed and actor.position.distance_to(arena.game.player.position)<35:return arena.game.player.position
	for other in arena.actors:
		if other.team==actor.team and other.downed and not other.eliminated and actor.position.distance_to(other.position)<35:return other.position
	return Vector3.INF
func can_reach_revive(from: Vector3,to: Vector3,actor: CharacterBody3D,target: Node3D) -> bool:
	var excluded: Array[RID]=[actor.get_rid()]
	var hit: Dictionary=arena.ray(from+Vector3.UP*.8,to+Vector3.UP*.4,excluded)
	return hit.is_empty() or hit.collider==target
func bot_revive(actor: CharacterBody3D,dt: float) -> bool:
	var goal:=rescue_goal(actor)
	if goal==Vector3.INF or actor.position.distance_to(goal)>2.8:return false
	var target: CharacterBody3D=null
	if actor.team==100 and player_downed:target=arena.game.player
	else:
		for other in arena.actors:
			if other.team==actor.team and other.downed and other.position.distance_to(actor.position)<2.8:target=other;break
	if not is_instance_valid(target) or not can_reach_revive(actor.position,target.position,actor,target):return false
	var key: int=0 if target==arena.game.player else target.get_instance_id()
	var progress: Dictionary=rescue_progress.get(key,{"actor":actor,"time":0.0,"seen":br.elapsed})
	if progress.actor!=actor or br.elapsed-progress.seen>.2:progress={"actor":actor,"time":0.0,"seen":br.elapsed}
	progress.time+=dt;progress.seen=br.elapsed;rescue_progress[key]=progress
	if progress.time>=3:
		if target==arena.game.player:revive_player()
		else:revive_actor(target)
	return true
func squad_victory() -> bool:
	if not squad:return br.player_alive and br.alive_count()==1
	for actor in arena.actors:
		if actor.team>=101 and not actor.eliminated:return false
	return br.player_alive or active_teammate(100)
func tick_squad(dt: float) -> void:
	if not squad:return
	if player_downed:
		player_bleed-=dt
		if player_bleed<=0:
			eliminate_player()
			if not arena.result.is_empty():return
	for actor in arena.actors:
		if actor.downed and not actor.eliminated:
			actor.bleed_left-=dt
			if actor.bleed_left<=0 or not active_teammate(actor.team,actor):finish_actor(actor,-1)
	if player_downed and not active_teammate(100):eliminate_player()
	if spectating:
		var mate: CharacterBody3D=null
		for actor in arena.actors:
			if actor.team==100 and not actor.eliminated and not actor.downed:mate=actor;break
		if not is_instance_valid(mate):br.finish(false,team_rank());return
		var cam: Camera3D=arena.game.player.camera
		cam.global_position=mate.position+Vector3(0,3,5);cam.look_at(mate.position+Vector3.UP)
		arena.game.objective.text="ELIMINATED • SPECTATING TEAMMATE"
		return
	if is_instance_valid(revive_target):
		var p: CharacterBody3D=arena.game.player
		var excluded: Array[RID]=[p.get_rid()]
		var hit: Dictionary=arena.ray(p.position+Vector3.UP,revive_target.position+Vector3.UP*.4,excluded)
		if not revive_target.downed or p.position.distance_to(revive_target.position)>2.8 or arena.fire_held or (not hit.is_empty() and hit.collider!=revive_target):revive_target=null;revive_left=0
		else:
			revive_left-=dt
			if revive_left<=0:revive_actor(revive_target);revive_target=null
	if player_downed:arena.game.objective.text="KNOCKED • "+str(ceili(player_bleed))+"s • Teammate আসছেন"
	elif revive_left>0:arena.game.objective.text="REVIVING • "+str(ceili(revive_left))+"s • Stay near teammate"
	else:
		var mates:=0
		for actor in arena.actors:
			if actor.team==100 and not actor.eliminated:mates+=1
		arena.game.objective.text="SQUAD • TEAMMATES "+str(mates)+" • USE to revive"
func tick(dt: float) -> void:
	if not arena.royale or not arena.active or arena.game.paused or not arena.result.is_empty():return
	tick_items(dt);tick_squad(dt)

func team_rank() -> int:
	var teams: Dictionary={}
	for actor in arena.actors:
		if actor.team>=101 and not actor.eliminated:teams[actor.team]=true
	return teams.size()+1
func eliminate_player() -> void:
	player_downed=false;br.player_alive=false
	arena.game.player.health=0;arena.game.player.hide();arena.game.player.collision_layer=0;arena.game.player.collision_mask=0
	if active_teammate(100):spectating=true
	else:br.finish(false,team_rank())
