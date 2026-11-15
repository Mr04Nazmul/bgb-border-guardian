extends Node3D
# Fictional Sylhet-inspired landscape. Original meshes + documented CC0 PBR maps.
var game: Node3D
var grass_mat: StandardMaterial3D
var dirt_mat: StandardMaterial3D
var brick_mat: StandardMaterial3D
var roof_mat: StandardMaterial3D
var foliage_mat: StandardMaterial3D
var trunk_mat: StandardMaterial3D
var tree_cards: Array[Transform3D] = []
var trunks: Array[Transform3D] = []
var rng := RandomNumberGenerator.new()
var tea_count := 0
func pbr(asset: String, scale_value: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = load("res://assets/textures/"+asset+"_Diffuse.jpg")
	mat.normal_enabled = true
	mat.normal_texture = load("res://assets/textures/"+asset+"_nor_gl.jpg")
	mat.normal_scale = 0.65
	mat.roughness_texture = load("res://assets/textures/"+asset+"_Rough.jpg")
	mat.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	mat.uv1_scale = Vector3.ONE*scale_value
	return mat
func build(owner_game: Node3D) -> void:
	game = owner_game
	rng.seed = 191
	grass_mat = pbr("leafy_grass",0.25)
	grass_mat.albedo_color = Color(0.55,0.8,0.45)
	dirt_mat = pbr("forest_ground_04",0.35)
	brick_mat = pbr("red_brick_03",0.45)
	roof_mat = pbr("corrugated_iron_02",0.4)
	roof_mat.metallic = 0.4
	trunk_mat = StandardMaterial3D.new()
	trunk_mat.albedo_color = Color("5b5140")
	trunk_mat.roughness = 1
	foliage_mat = StandardMaterial3D.new()
	foliage_mat.albedo_texture = load("res://assets/textures/foliage.png")
	foliage_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	foliage_mat.alpha_scissor_threshold = 0.4
	foliage_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	foliage_mat.roughness = 0.9
	make_sky()
	terrain()
	river()
	tea_gardens()
	meadow()
	horizon()
	utility_poles()
func height_at(x: float,z: float) -> float:
	var east := smoothstep(108.0,160.0,x)
	var south_west := smoothstep(45.0,95.0,z)*smoothstep(48.0,105.0,-x)
	var north := smoothstep(128.0,188.0,-z)*smoothstep(42.0,85.0,absf(x))
	var hills := east*(8+7*sin(x*0.025)*cos(z*0.018))+south_west*(7+5*sin(x*0.04+z*0.015))+north*(7+6*sin(x*0.025))
	var channel := (1-smoothstep(8.0,12.0,absf(x-86)))*1.5
	return -0.1+hills-channel
func terrain() -> void:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uv := PackedVector2Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	const N := 100
	for iz in N+1:
		for ix in N+1:
			var x := float(ix)*4-200
			var z := float(iz)*4-200
			var h := height_at(x,z)
			vertices.append(Vector3(x,h,z))
			normals.append(Vector3(height_at(x-1,z)-height_at(x+1,z),2,height_at(x,z-1)-height_at(x,z+1)).normalized())
			uv.append(Vector2(x,z)*0.2)
			var shade := 0.9+0.1*sin(x*0.14+z*0.2)
			colors.append(Color(shade,shade,shade))
	for iz in N:
		for ix in N:
			var a := iz*(N+1)+ix
			indices.append_array(PackedInt32Array([a,a+1,a+N+1,a+1,a+N+2,a+N+1]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var mi := MeshInstance3D.new()
	mi.name = "SylhetTerrain400m"
	mi.mesh = mesh
	mi.material_override = grass_mat
	grass_mat.vertex_color_use_as_albedo = true
	add_child(mi)
	mi.create_trimesh_collision()
func make_sky() -> void:
	var sky := Sky.new()
	var atmosphere := ProceduralSkyMaterial.new()
	atmosphere.sky_top_color = Color("477a9a")
	atmosphere.sky_horizon_color = Color("cbd5cb")
	atmosphere.ground_bottom_color = Color("2a3e26")
	atmosphere.ground_horizon_color = Color("b1bca6")
	atmosphere.sky_curve = 0.18
	atmosphere.sun_angle_max = 8
	var cloud_shader := Shader.new()
	cloud_shader.code = """shader_type sky;
float hash21(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise2(vec2 p){vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash21(i),hash21(i+vec2(1.0,0.0)),f.x),mix(hash21(i+vec2(0.0,1.0)),hash21(i+vec2(1.0,1.0)),f.x),f.y);}
void sky(){float h=max(EYEDIR.y,0.0);vec3 sky_color=mix(vec3(0.72,0.79,0.77),vec3(0.23,0.45,0.62),pow(h,0.45));vec2 p=EYEDIR.xz/(h+0.18)*2.2;float n=noise2(p)*0.55+noise2(p*2.1)*0.28+noise2(p*4.2)*0.17;float clouds=smoothstep(0.46,0.7,n)*smoothstep(0.0,0.14,h);COLOR=mix(sky_color,vec3(0.91,0.92,0.86),clouds*0.88);if(EYEDIR.y<0.0){COLOR=mix(vec3(0.26,0.34,0.21),vec3(0.68,0.75,0.67),exp(EYEDIR.y*12.0));}}
"""
	var cloud_material := ShaderMaterial.new()
	cloud_material.shader = cloud_shader
	sky.sky_material = cloud_material
	var env: Environment = game.environment.environment
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_energy = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.06
	env.adjustment_saturation = 0.94
	game.sun.rotation_degrees = Vector3(-24,-40,0)
	game.sun.light_color = Color("ffe3b5")
	game.sun.directional_shadow_max_distance = 90
	game.sun.shadow_bias = 0.04
func river() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(16,400)
	plane.subdivide_width = 12
	plane.subdivide_depth = 100
	var mi := MeshInstance3D.new()
	mi.mesh = plane
	mi.position = Vector3(86,-0.35,0)
	mi.name = "FlowingRiver"
	var shader := Shader.new()
	shader.code = """shader_type spatial;
render_mode cull_disabled;
varying vec3 world_pos;
void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; VERTEX.y+=sin(VERTEX.z*1.8+TIME*1.3)*0.025+sin(VERTEX.x*3.1+TIME)*0.018;}
void fragment(){float w=sin(world_pos.x*4.0+world_pos.z*1.7+TIME*1.4)*sin(world_pos.z*5.0-TIME); float f=pow(1.0-max(dot(normalize(NORMAL),normalize(VIEW)),0.0),3.0); ALBEDO=mix(vec3(0.07,0.19,0.17),vec3(0.43,0.62,0.64),f)+w*0.025; ROUGHNESS=0.22; METALLIC=0.25; SPECULAR=0.7; NORMAL=normalize(NORMAL+vec3(w*0.1,0.0,sin(world_pos.z*7.0+TIME)*0.08));}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mi.material_override = mat
	add_child(mi)
	# Exposed banks use the same scanned ground material as the village paths.
	for x in [75.5,96.5]:
		var bank: MeshInstance3D = game.box(Vector3(x,-0.23,0),Vector3(3,0.2,400),Color.WHITE,false)
		bank.material_override = dirt_mat
func tea_gardens() -> void:
	var bush := SphereMesh.new()
	bush.radius = 0.8
	bush.height = 1.25
	bush.radial_segments = 10
	bush.rings = 5
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("3c632b")
	mat.roughness = 0.85
	bush.material = mat
	var transforms: Array[Transform3D] = []
	for row in 22:
		for col in 30:
			var x := -181.0+float(col)*3.6
			var z := 68.0+float(row)*5+sin(float(col)*0.15)*3
			var h := height_at(x,z)
			transforms.append(Transform3D(Basis.IDENTITY.scaled(Vector3(1.35,0.75,1)),Vector3(x,h+0.5,z)))
	tea_count = transforms.size()
	instances(bush,transforms,"ContourTeaRows",150)
func meadow() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for angle in [0.0,1.05,2.1]:
		var dir := Vector3(cos(angle)*0.14,0,sin(angle)*0.14)
		for v in [-dir,dir,Vector3(0.1,0.6,0.1)]:
			st.set_normal(Vector3.UP)
			st.add_vertex(v)
	var mesh := st.commit()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("7c9145")
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.surface_set_material(0,mat)
	var positions: Array[Transform3D] = []
	for i in 6000:
		var x := rng.randf_range(-194,194)
		var z := rng.randf_range(-194,194)
		if absf(x)<43 or (x>72 and x<100) or (x< -35 and z< -45 and x> -110):
			continue
		positions.append(Transform3D(Basis(Vector3.UP,rng.randf_range(0,TAU)).scaled(Vector3.ONE*rng.randf_range(0.6,1.2)),Vector3(x,height_at(x,z),z)))
	instances(mesh,positions,"MeadowGrass",48)
func instances(mesh: Mesh,transforms: Array[Transform3D],label: String,range_end: float) -> void:
	var groups: Dictionary = {}
	for t in transforms:
		var key := Vector2i(floori(t.origin.x/32),floori(t.origin.z/32))
		if not groups.has(key):
			groups[key] = []
		groups[key].append(t)
	for key in groups:
		var batch: Array = groups[key]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = batch.size()
		for i in batch.size():
			mm.set_instance_transform(i,batch[i])
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mm
		mi.name = label+str(key)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if label.begins_with("Tree") or label == "LeafCanopies" else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visibility_range_end = range_end
		add_child(mi)
func make_tree(pos: Vector3,s: float) -> void:
	pos.y = height_at(pos.x,pos.z)
	var height := rng.randf_range(7,11)*s
	trunks.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.55*s,height,0.55*s)),pos+Vector3.UP*height*0.5))
	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.height = height
	shape.radius = 0.35*s
	collision.shape = shape
	body.position = pos+Vector3.UP*height*0.5
	body.add_child(collision)
	add_child(body)
	for i in 9:
		var angle := rng.randf_range(0,TAU)
		var center := pos+Vector3(cos(angle)*2.0*s,height+rng.randf_range(-1.3,1.6)*s,sin(angle)*2.0*s)
		for a in 3:
			var basis := Basis(Vector3.UP,angle+float(a)*PI/3).scaled(Vector3.ONE*rng.randf_range(3.4,4.7)*s)
			tree_cards.append(Transform3D(basis,center))
func finish_trees() -> void:
	var trunk := CylinderMesh.new()
	trunk.height = 1
	trunk.top_radius = 0.32
	trunk.bottom_radius = 0.6
	trunk.radial_segments = 8
	trunk.material = trunk_mat
	instances(trunk,trunks,"TreeTrunks",180)
	var card := QuadMesh.new()
	card.size = Vector2(1.6,1.1)
	card.material = foliage_mat
	instances(card,tree_cards,"LeafCanopies",180)
func horizon() -> void:
	for i in 22:
		var a := float(i)/22*TAU
		var hill := SphereMesh.new()
		hill.radius = 1
		hill.height = 2
		hill.radial_segments = 32
		hill.rings = 12
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color("526e5b").lerp(Color("8ba59c"),float(i%3)*0.18)
		hill.material = mat
		var m := MeshInstance3D.new()
		m.mesh = hill
		m.position = Vector3(sin(a)*340,-25,cos(a)*340)
		m.scale = Vector3(rng.randf_range(90,150),rng.randf_range(55,95),rng.randf_range(95,145))
		add_child(m)
func utility_poles() -> void:
	for z in [-120,-80,-40,0,40,80,120]:
		game.box(Vector3(6,4.5,z),Vector3(0.18,9,0.18),Color("817461"))
		game.box(Vector3(6,8.2,z),Vector3(2,0.16,0.16),Color("6c5b44"))
		if z<120:
			for x in [5.3,6.7]:
				for section in 8:
					var cable_z := float(z)+float(section)*5+2.5
					var cable_y := 8.5-sin((float(section)+0.5)/8*PI)*0.65
					game.box(Vector3(x,cable_y,cable_z),Vector3(0.025,0.025,5.1),Color("282a27"),false)
