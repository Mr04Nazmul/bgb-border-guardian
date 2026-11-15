extends CharacterBody3D
var throttle := 0.0
var steering := 0.0
var speed := 0.0
var active := false
var camera: Camera3D
var wheels: Array[Node3D] = []
func _ready() -> void:
	var c := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2,1.4,4)
	c.shape = box
	c.position.y = 0.9
	add_child(c)
	part(Vector3(0,0.8,0),Vector3(2,0.55,4),Color("45583a"))
	part(Vector3(0,1.45,0.3),Vector3(1.8,0.9,1.9),Color("607253"))
	part(Vector3(0,1.55,-0.69),Vector3(1.6,0.55,0.04),Color("91b7b6"))
	for x in [-1.0,1.0]:
		for z in [-1.3,1.3]:
			var w := MeshInstance3D.new()
			var mesh := CylinderMesh.new()
			mesh.top_radius = 0.48
			mesh.bottom_radius = 0.48
			mesh.height = 0.3
			w.mesh = mesh
			w.rotation.z = PI/2
			w.position = Vector3(x,0.5,z)
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color("202522")
			w.material_override = mat
			add_child(w)
			wheels.append(w)
	var arm := SpringArm3D.new()
	arm.position = Vector3(0,3,0)
	arm.rotation.x = -0.2
	arm.spring_length = 8
	arm.add_excluded_object(get_rid())
	add_child(arm)
	camera = Camera3D.new()
	arm.add_child(camera)
func part(pos: Vector3,size: Vector3,color: Color) -> void:
	var m := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	m.mesh = mesh
	m.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	m.material_override = mat
	add_child(m)
func _physics_process(dt: float) -> void:
	if get_parent().paused or not get_parent().playing:
		return
	if active:
		speed = move_toward(speed,-throttle*17,7*dt)
		rotation.y -= steering*speed*dt*0.055
	else:
		speed = move_toward(speed,0,12*dt)
	velocity = -transform.basis.z*speed
	velocity.y = -5
	move_and_slide()
	if get_slide_collision_count() > 0:
		for i in get_slide_collision_count():
			if absf(get_slide_collision(i).get_normal().y) < 0.4:
				speed *= 0.7
	position.x = clampf(position.x,-196,196)
	position.z = clampf(position.z,-196,196)
