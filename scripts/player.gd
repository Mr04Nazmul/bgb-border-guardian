extends CharacterBody3D
var stick := Vector2.ZERO
var yaw := 0.0
var pitch := -0.15
var running := false
var crouched := false
var prone := false
var look_velocity := Vector2.ZERO
var look_pending := Vector2.ZERO
var sensitivity := 0.75
var ads_sensitivity := 0.45
var jump_requested := false
var stamina := 100.0
var health := 100.0
var first_person := false
var driving := false
var phase := 0.0
var weapon: Node3D
var visual: Node3D
var pivot: Node3D
var arm: SpringArm3D
var camera: Camera3D
var avatar: Node3D
var animation_player: AnimationPlayer
var skeleton: Skeleton3D
var body_collision: CollisionShape3D
var animation_state := "idle"

func _ready() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.75
	body_collision = shape
	shape.shape = capsule
	shape.position.y = 0.9
	add_child(shape)
	visual = Node3D.new()
	add_child(visual)
	avatar = preload("res://assets/characters/rafi_rig/rafi_rig.glb").instantiate()
	avatar.name = "RafiRiggedMainCharacter"
	# Blender's -Y facing direction exports as glTF +Z; turn toward Godot -Z.
	avatar.rotation.y = PI
	visual.add_child(avatar)
	animation_player = avatar.find_child("AnimationPlayer",true,false)
	skeleton = avatar.find_child("Skeleton3D",true,false)
	for clip in ["idle","walk","run","crouch","aim","armed_walk","armed_run","crouch_walk","prone","crawl"]:
		animation_player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	animation_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	# Calibrate the prop to the animated hand, rather than attaching it to the torso.
	animation_player.play("aim")
	animation_player.advance(0)
	skeleton.force_update_all_bone_transforms()
	var hand_index := skeleton.find_bone("hand.R")
	var hand_pose := skeleton.get_bone_global_pose(hand_index)
	var attachment := BoneAttachment3D.new()
	attachment.bone_name = "hand.R"
	skeleton.add_child(attachment)
	weapon = Node3D.new()
	weapon.name = "AnimatedTrainingProp"
	attachment.add_child(weapon)
	weapon.transform = hand_pose.affine_inverse()*Transform3D(Basis(Vector3.UP,PI),hand_pose.origin+Vector3(0,0,0.16))
	weapon.add_child(preload("res://scripts/rifle_visual.gd").new())
	weapon.hide()
	animation_player.play("idle")
	animation_player.advance(0)
	pivot = Node3D.new()
	pivot.position.y = 1.5
	add_child(pivot)
	arm = SpringArm3D.new()
	arm.spring_length = 5.5
	arm.margin = 0.2
	arm.add_excluded_object(get_rid())
	pivot.add_child(arm)
	camera = Camera3D.new()
	camera.fov = 70
	arm.add_child(camera)

func part(pos: Vector3, size: Vector3, color: Color, parent: Node3D) -> void:
	var m := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	m.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	m.material_override = mat
	m.position = pos
	parent.add_child(m)

func _physics_process(dt: float) -> void:
	weapon.visible = is_instance_valid(get_parent().combat) and get_parent().combat.active and (not get_parent().combat.royale or not get_parent().combat.br.inventory.is_empty())
	if get_parent().paused or not get_parent().playing:
		return
	if is_instance_valid(get_parent().combat) and get_parent().combat.active and get_parent().combat.respawn_left>0:
		velocity = Vector3.ZERO
		return
	if is_instance_valid(get_parent().combat) and get_parent().combat.royale and not get_parent().combat.br.player_alive:
		return
	if driving:
		return
	var look_step := look_pending*(1.0-exp(-22.0*dt))
	look_pending-=look_step
	yaw-=look_step.x
	pitch=clampf(pitch-look_step.y,-1.15,0.65)
	if not crouched and not prone and body_collision.shape.height < 1.7:
		var q := PhysicsRayQueryParameters3D.create(global_position+Vector3(0,1.1,0),global_position+Vector3(0,1.85,0))
		q.exclude=[get_rid()]
		if not get_world_3d().direct_space_state.intersect_ray(q).is_empty():crouched=true
	body_collision.shape.height=0.65 if prone else (1.15 if crouched else 1.75)
	body_collision.position.y=0.34 if prone else (0.6 if crouched else 0.9)
	pivot.position.y=lerpf(pivot.position.y,0.5 if prone else (1.05 if crouched else 1.5),1.0-exp(-12*dt))
	var axis := stick
	axis += Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
	axis = axis.limit_length()
	var sprint: bool= (running or Input.is_physical_key_pressed(KEY_SHIFT)) and stamina > 1 and not crouched and not prone and not get_parent().combat.aim and axis.length() > 0.1
	stamina = clampf(stamina + (-18.0 if sprint else 12.0)*dt,0,100)
	var speed := 0.9 if prone else (1.7 if crouched else (7.0 if sprint else (2.5 if get_parent().combat.aim else 4.0)))
	var dir := Basis(Vector3.UP,yaw)*Vector3(axis.x,0,axis.y)
	velocity.x = move_toward(velocity.x,dir.x*speed,20*dt)
	velocity.z = move_toward(velocity.z,dir.z*speed,20*dt)
	if not is_on_floor():
		velocity.y -= 22*dt
	if jump_requested and is_on_floor() and not crouched and not prone:
		velocity.y = 7
	jump_requested = false
	move_and_slide()
	position.x = clampf(position.x,-198,198)
	position.z = clampf(position.z,-198,198)
	pivot.rotation = Vector3(pitch,yaw,0)
	arm.spring_length = lerpf(arm.spring_length,0.1 if first_person else (3.0 if get_parent().combat.aim else 4.6),1.0-exp(-12*dt))
	arm.position.x=lerpf(arm.position.x,0.43 if get_parent().combat.aim else 0.15,1.0-exp(-12*dt))
	visual.visible = not first_person
	visual.scale = Vector3.ONE
	var arena = get_parent().combat
	if is_instance_valid(arena) and arena.active and (arena.aim or arena.fire_held or arena.reload_left>0 or arena.shot_left>0):
		visual.rotation.y=lerp_angle(visual.rotation.y,yaw,dt*12)
	elif dir.length()>0.1:
		visual.rotation.y=lerp_angle(visual.rotation.y,atan2(-dir.x,-dir.z),dt*12)
	var clip := "idle"
	if not is_on_floor():clip="jump"
	elif prone:clip="crawl" if axis.length()>0.1 else "prone"
	elif crouched:clip="crouch_walk" if axis.length()>0.1 else "crouch"
	elif is_instance_valid(arena) and arena.active and arena.reload_left>0:clip="reload"
	elif is_instance_valid(arena) and arena.active and (arena.aim or arena.fire_held or arena.shot_left>0):clip=("armed_walk" if axis.length()>0.1 else "aim")
	elif axis.length()>0.1:clip=("armed_run" if sprint else "armed_walk") if weapon.visible else ("run" if sprint else "walk")
	play_animation(clip,dt)
	if weapon.visible:
		skeleton.force_update_all_bone_transforms()
		var hand_world: Vector3=skeleton.global_transform*skeleton.get_bone_global_pose(skeleton.find_bone("hand.R")).origin
		weapon.global_position=hand_world+visual.global_basis*Vector3(0,0,-.15)
		weapon.global_basis=visual.global_basis*Basis(Vector3.RIGHT,pitch if arena.aim else 0.0)

func play_animation(clip: String,dt: float) -> void:
	if clip!=animation_state:
		animation_state=clip
		animation_player.play(clip,0.12)
	animation_player.advance(dt)

func add_look(delta: Vector2) -> void:
	var scale_factor:=ads_sensitivity if get_parent().combat.aim else sensitivity
	look_pending+=delta.limit_length(90)*0.0032*scale_factor
func toggle_crouch() -> void:
	prone=false;crouched=not crouched
func toggle_prone() -> void:
	if driving or not is_on_floor():return
	prone=not prone;crouched=false;running=false
