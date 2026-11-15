extends CharacterBody3D
var arena: Node3D
var team:=0 # West / east fictional teams, or civilian.
var health:=100.0
var dead_left:=0.0
var shoot_left:=0.0
var spawn_point:=Vector3.ZERO
var age:=0.0
var bridge_exit:=0.0
var shot_audio: AudioStreamPlayer3D
var visual: Node3D
var legs: Array[Node3D]=[]
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
	shape.radius=0.32;shape.height=1.75;c.shape=shape;c.position.y=0.9;add_child(c)
	visual=Node3D.new();add_child(visual)
	var color: Color=[Color("477453"),Color("825a46"),Color("a5a3c5")][team]
	part(Vector3(0,1.17,0),Vector3(0.62,0.7,0.32),color,visual)
	part(Vector3(0,1.74,0),Vector3(0.34,0.37,0.32),Color("b58b69"),visual)
	if team!=2:
		part(Vector3(0,1.94,0),Vector3(0.4,0.16,0.4),color.darkened(0.3),visual)
		part(Vector3(0,1.17,-0.42),Vector3(0.1,0.12,0.85),Color("303431"),visual)
	for x in [-0.2,0.2]:
		var leg:=Node3D.new();leg.position=Vector3(x,0.85,0);visual.add_child(leg)
		part(Vector3(0,-0.38,0),Vector3(0.23,0.75,0.26),color.darkened(0.15),leg);legs.append(leg)
	for x in [-0.42,0.42]:part(Vector3(x,1.13,-0.1),Vector3(0.18,0.6,0.2),color,visual)
	var badge:=Label3D.new()
	badge.text=["মিত্র • ALLY","প্রতিপক্ষ • BOT","গ্রামবাসী • CIVILIAN"][team]
	badge.font=load("res://assets/Bengali.ttf");badge.font_size=28;badge.pixel_size=0.008
	badge.position.y=2.4;badge.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	badge.modulate=[Color("9fe5b1"),Color("f6ac91"),Color("efe6c6")][team]
	badge.visibility_range_end=40;add_child(badge)
	shoot_left=float(get_instance_id()%100)/100
func receive_damage(amount: float,attacker_team: int) -> void:
	if team==2 or dead_left>0 or attacker_team==team:return
	health=maxf(0,health-amount)
	if health<=0:
		arena.add_point(attacker_team)
		dead_left=5
		collision_layer=0;collision_mask=0
		visual.rotation.z=PI/2
func _physics_process(dt: float) -> void:
	if not arena.game.playing or arena.game.paused:return
	age+=dt
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
			shoot_left-=dt
			if position.distance_to(dest)<46:
				if shoot_left<=0:
					arena.bot_fire(self,target)
					shoot_left=0.7+arena.rng.randf()*0.8
				if position.distance_to(dest)<17:dest=position
		else:
			dest=Vector3(86,0,-90)
		speed=2.8
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
	velocity.x=direction.x*speed;velocity.z=direction.z*speed
	velocity.y-=22*dt
	move_and_slide()
	if direction.length()>0.1:
		visual.rotation.y=lerp_angle(visual.rotation.y,atan2(-direction.x,-direction.z),dt*6)
		legs[0].rotation.x=sin(age*8)*0.5;legs[1].rotation.x=-sin(age*8)*0.5
	position.x=clampf(position.x,-195,195);position.z=clampf(position.z,-195,195)
	if position.y< -8:position=spawn_point;velocity=Vector3.ZERO
