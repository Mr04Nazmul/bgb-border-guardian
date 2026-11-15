extends CharacterBody3D
var stick := Vector2.ZERO
var yaw := 0.0
var pitch := -0.15
var running := false
var crouched := false
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
	for clip in ["idle","walk","run","crouch","aim"]:
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
	part(Vector3.ZERO,Vector3(0.10,0.12,0.5),Color("30352e"),weapon)
	part(Vector3(0,-0.1,0.05),Vector3(0.08,0.16,0.10),Color("252b26"),weapon)
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
	if not crouched and body_collision.shape.height < 1.7:
		var q := PhysicsRayQueryParameters3D.create(global_position+Vector3(0,1.1,0),global_position+Vector3(0,1.85,0))
		q.exclude=[get_rid()]
		if not get_world_3d().direct_space_state.intersect_ray(q).is_empty():crouched=true
	body_collision.shape.height=1.15 if crouched else 1.75
	body_collision.position.y=0.6 if crouched else 0.9
	pivot.position.y=1.05 if crouched else 1.5
	var axis := stick
	axis += Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
	axis = axis.limit_length()
	var sprint := (running or Input.is_physical_key_pressed(KEY_SHIFT)) and stamina > 1 and not crouched and axis.length() > 0.1
	stamina = clampf(stamina + (-18.0 if sprint else 12.0)*dt,0,100)
	var speed := 2.0 if crouched else (7.0 if sprint else 4.0)
	var dir := Basis(Vector3.UP,yaw)*Vector3(axis.x,0,axis.y)
	velocity.x = move_toward(velocity.x,dir.x*speed,20*dt)
	velocity.z = move_toward(velocity.z,dir.z*speed,20*dt)
	if not is_on_floor():
		velocity.y -= 22*dt
	if jump_requested and is_on_floor() and not crouched:
		velocity.y = 7
	jump_requested = false
	move_and_slide()
	position.x = clampf(position.x,-198,198)
	position.z = clampf(position.z,-198,198)
	pivot.rotation = Vector3(pitch,yaw,0)
	arm.spring_length = 0.1 if first_person else 5.5
	visual.visible = not first_person
	visual.scale = Vector3.ONE
	var arena = get_parent().combat
	if is_instance_valid(arena) and arena.active and (arena.aim or arena.fire_held or arena.reload_left>0 or arena.shot_left>0):
		visual.rotation.y=lerp_angle(visual.rotation.y,yaw,dt*12)
	elif dir.length()>0.1:
		visual.rotation.y=lerp_angle(visual.rotation.y,atan2(-dir.x,-dir.z),dt*12)
	var clip := "idle"
	if not is_on_floor():clip="jump"
	elif crouched:clip="crouch"
	elif is_instance_valid(arena) and arena.active and arena.reload_left>0:clip="reload"
	elif is_instance_valid(arena) and arena.active and (arena.aim or arena.fire_held or arena.shot_left>0):clip="aim"
	elif axis.length()>0.1:clip="run" if sprint else "walk"
	play_animation(clip,dt)

func play_animation(clip: String,dt: float) -> void:
	if clip!=animation_state:
		animation_state=clip
		animation_player.play(clip,0.12)
	animation_player.advance(dt)
