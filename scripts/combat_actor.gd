extends CharacterBody3D
var arena: Node3D
var team:=0 # West / east fictional teams, or civilian.
var eliminated:=false
var has_weapon:=true
var weapon_kind:="rifle"
var rounds:=24
var reserve_rounds:=72
var reload_timer:=0.0
var gun_mesh: Node3D
var health:=100.0
var dead_left:=0.0
var shoot_left:=0.0
var spawn_point:=Vector3.ZERO
var age:=0.0
var bridge_exit:=0.0
var shot_audio: AudioStreamPlayer3D
var visual: Node3D
var legs: Array[Node3D]=[]
var animator: AnimationPlayer
var skeleton: Skeleton3D
var rig: Node3D
var crouched:=false
var body_collision: CollisionShape3D
var alert_left:=0.0
var last_seen:=Vector3.ZERO
var facing_target:=Vector3.ZERO
func part(pos: Vector3,size: Vector3,color: Color,parent: Node3D) -> Node3D:
	var m:=MeshInstance3D.new()
	var mesh:=BoxMesh.new()
	mesh.size=size;m.mesh=mesh;m.position=pos
	var mat:=StandardMaterial3D.new();mat.albedo_color=color;m.material_override=mat
	parent.add_child(m);return m
func _ready() -> void:
	shot_audio=AudioStreamPlayer3D.new()
	shot_audio.stream=load("res://assets/sfx/shot.wav")
	shot_audio.volume_db= -22
	shot_audio.max_distance=70
	add_child(shot_audio)
	var c:=CollisionShape3D.new();var shape:=CapsuleShape3D.new()
	shape.radius=0.32;shape.height=1.85;c.shape=shape;c.position.y=0.95;add_child(c);body_collision=c
	visual=Node3D.new();add_child(visual)
	rig=preload("res://assets/characters/rafi_rig/rafi_rig.glb").instantiate()
	rig.rotation.y=PI;visual.add_child(rig)
	animator=rig.find_child("AnimationPlayer",true,false)
	animator.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for clip in ["idle","walk","run","armed_walk","armed_run","aim","crouch","crouch_walk"]:animator.get_animation(clip).loop_mode=Animation.LOOP_LINEAR
	animator.play("aim");animator.advance(0)
	var sk: Skeleton3D=rig.find_child("Skeleton3D",true,false)
	skeleton=sk
	sk.force_update_all_bone_transforms()
	var hand_pose:=sk.get_bone_global_pose(sk.find_bone("hand.R"))
	var attachment:=BoneAttachment3D.new();attachment.bone_name="hand.R";sk.add_child(attachment)
	gun_mesh=Node3D.new();attachment.add_child(gun_mesh)
	gun_mesh.transform=hand_pose.affine_inverse()*Transform3D(Basis(Vector3.UP,PI),hand_pose.origin+Vector3(0,0,.16))
	gun_mesh.add_child(preload("res://scripts/rifle_visual.gd").new())
	gun_mesh.visible=team!=2
	var body_mesh: MeshInstance3D=rig.find_child("RafiSolidBody",true,false)
	body_mesh.visibility_range_end=90 if arena.game.quality==0 else 160
	if team==2:
		var body: MeshInstance3D=rig.find_child("RafiSolidBody",true,false)
		var mat:=StandardMaterial3D.new();mat.albedo_color=[Color("77918b"),Color("b99b7e"),Color("7b7e9c")][get_instance_id()%3];body.material_override=mat
	else:
		# Small shoulder patch identifies the fictional side without replacing camouflage.
		part(Vector3(.29,1.38,0),Vector3(.03,.09,.1),Color("236d44") if team==0 else Color("c08b48"),visual)
	animator.play("idle");animator.advance(0)
	var badge:=Label3D.new()
	badge.text=["বাংলাদেশ দল • ALLY","ভারত দল • BOT","গ্রামবাসী • CIVILIAN"][mini(team,1) if team>=100 else team]
	if team>=100:badge.text="প্রতিযোগী • SURVIVOR"
	badge.font=load("res://assets/Bengali.ttf");badge.font_size=28;badge.pixel_size=0.008
	badge.position.y=2.4;badge.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	badge.modulate=[Color("9fe5b1"),Color("f6ac91"),Color("efe6c6")][mini(team,1) if team>=100 else team]
	badge.visibility_range_end=40;add_child(badge)
	shoot_left=float(get_instance_id()%100)/100
func receive_damage(amount: float,attacker_team: int) -> void:
	if team==2 or dead_left>0 or eliminated or attacker_team==team:return
	alert_left=5
	health=maxf(0,health-amount)
	if health<=0:
		arena.actor_eliminated(self,attacker_team)
		if arena.royale:return
		dead_left=5
		collision_layer=0;collision_mask=0
		visual.rotation.z=PI/2
func _physics_process(dt: float) -> void:
	if not arena.game.playing or arena.game.paused or eliminated:return
	if team!=2 and is_instance_valid(gun_mesh):gun_mesh.visible=has_weapon
	if arena.royale:
		if reload_timer>0:
			reload_timer-=dt
			if reload_timer<=0:
				var capacity: int=int(arena.br.WEAPONS[weapon_kind].mag)
				var amount:=mini(capacity-rounds,reserve_rounds)
				rounds+=amount;reserve_rounds-=amount
		elif has_weapon and rounds<=0 and reserve_rounds>0:reload_timer=2
	age+=dt
	alert_left=maxf(0,alert_left-dt)
	crouched=team!=2 and alert_left>0 and health<60
	body_collision.shape.height=1.5 if crouched else 1.85
	body_collision.position.y=.77 if crouched else .95
	facing_target=Vector3.ZERO
	if dead_left>0:
		dead_left-=dt
		if dead_left<=0:
			health=100;position=spawn_point;velocity=Vector3.ZERO;bridge_exit=0
			collision_layer=1;collision_mask=1;visual.rotation=Vector3.ZERO
		return
	var dest:=spawn_point
	var speed:=1.0
	if team==2:
		dest+=Vector3(sin(age*0.15+float(get_instance_id()%7))*5,0,cos(age*0.12)*4)
	elif arena.active:
		var target: Node3D=arena.target_for(self)
		if is_instance_valid(target):
			dest=target.position
			last_seen=dest;facing_target=dest
			shoot_left-=dt
			if position.distance_to(dest)<46:
				if shoot_left<=0:
					arena.bot_fire(self,target)
					shoot_left=0.7+arena.rng.randf()*0.8
				if position.distance_to(dest)<17:
					dest=position+Vector3(cos(age*.8+team),0,sin(age*.8+team))*3
		else:
			dest=Vector3(86,0,-90)
		speed=1.3 if crouched else 2.8
	if arena.royale and team>=100:dest=arena.br.bot_goal(self,dest)
	# Fictional combat route funnels bots over the bridge, never through the river.
	if team!=2:
		if bridge_exit==0 and ((position.x<76 and dest.x>96) or (position.x>96 and dest.x<76)):
			bridge_exit=100 if position.x<86 else 72
		if bridge_exit!=0:
			if absf(position.x-bridge_exit)<1:
				bridge_exit=0
			elif absf(position.z+90)>1.5:
				dest=Vector3(position.x,position.y,-90)
			else:
				dest=Vector3(bridge_exit,position.y,-90)
	var offset:=Vector3(dest.x-position.x,0,dest.z-position.z)
	var direction:=offset.normalized() if offset.length()>1 else Vector3.ZERO
	if is_on_wall() and bridge_exit==0:
		var normal:=get_wall_normal()
		var tangent:=Vector3(-normal.z,0,normal.x)
		direction=(direction+normal*.8+tangent*(1.0 if get_instance_id()%2==0 else -1.0)).normalized()
	velocity.x=direction.x*speed;velocity.z=direction.z*speed
	velocity.y-=22*dt
	move_and_slide()
	if direction.length()>0.1:
		visual.rotation.y=lerp_angle(visual.rotation.y,atan2(-direction.x,-direction.z),dt*6)
	if facing_target!=Vector3.ZERO:
		var face:=facing_target-position
		visual.rotation.y=lerp_angle(visual.rotation.y,atan2(-face.x,-face.z),1.0-exp(-10*dt))
	var clip:="idle"
	if direction.length()>0.1:clip="walk" if team==2 or not has_weapon else ("crouch_walk" if crouched else "armed_walk")
	elif team!=2 and has_weapon:clip="crouch" if crouched else "aim"
	if reload_timer>0:clip="reload"
	if animator.current_animation!=clip:animator.play(clip,.16)
	animator.advance(dt)
	if gun_mesh.visible:
		skeleton.force_update_all_bone_transforms()
		var hand_world: Vector3=skeleton.global_transform*skeleton.get_bone_global_pose(skeleton.find_bone("hand.R")).origin
		gun_mesh.global_position=hand_world+visual.global_basis*Vector3(0,0,-.15)
		gun_mesh.global_basis=visual.global_basis
	position.x=clampf(position.x,-195,195);position.z=clampf(position.z,-195,195)
	if position.y< -8:
		if arena.royale:receive_damage(1000,-1)
		else:position=spawn_point;velocity=Vector3.ZERO
