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
var front_card: Node3D
var back_card: Node3D
var side_card: Node3D

func _ready() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.75
	shape.shape = capsule
	shape.position.y = 0.9
	add_child(shape)
	visual = Node3D.new()
	add_child(visual)
	avatar = preload("res://assets/characters/rafi/bgb-rafi-v3.glb").instantiate()
	avatar.name = "RafiMainCharacter"
	# Uploaded GLB uses Z as its height axis; convert to Godot's Y-up world.
	avatar.rotation.x = -PI/2
	visual.add_child(avatar)
	front_card = avatar.find_child("RafiFront",true,false)
	back_card = avatar.find_child("RafiBack",true,false)
	side_card = avatar.find_child("RafiSide",true,false)
	weapon=Node3D.new()
	visual.add_child(weapon)
	part(Vector3(0.23,1.2,-0.38),Vector3(0.13,0.14,0.8),Color("30352e"),weapon)
	part(Vector3(0.23,1.08,-0.3),Vector3(0.1,0.2,0.12),Color("282d28"),weapon)
	weapon.hide()
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
	weapon.visible = false
	if get_parent().paused or not get_parent().playing:
		return
	if is_instance_valid(get_parent().combat) and get_parent().combat.active and get_parent().combat.respawn_left>0:
		velocity = Vector3.ZERO
		return
	if driving:
		return
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
	visual.scale.y = 0.65 if crouched else 1.0
	if dir.length() > 0.1:
		visual.rotation.y = lerp_angle(visual.rotation.y,atan2(-dir.x,-dir.z),dt*12)
		phase += dt*speed*2
		avatar.position.y = absf(sin(phase))*0.025
	else:
		avatar.position.y = lerpf(avatar.position.y,0,dt*10)
	update_avatar_view()

func update_avatar_view() -> void:
	if not is_instance_valid(camera):return
	var direction := visual.to_local(camera.global_position)
	var side := absf(direction.x)>absf(direction.z)
	front_card.visible = not side and direction.z<0
	back_card.visible = not side and direction.z>=0
	side_card.visible = side
