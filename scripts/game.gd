extends Node3D
const Combat = preload("res://scripts/combat.gd")
var combat: Node3D
const Player = preload("res://scripts/player.gd")
const Jeep = preload("res://scripts/jeep.gd")
const Sylhet = preload("res://scripts/sylhet.gd")
var landscape: Node3D
const Touch = preload("res://scripts/touch.gd")
var player: CharacterBody3D
var jeep: CharacterBody3D
var sun: DirectionalLight3D
var environment: WorldEnvironment
var hud: CanvasLayer
var objective: Label
var stats: Label
var message: Label
var menu: PanelContainer
var menu_box: VBoxContainer
var touch: Control
var minimap: Control
var marker: MeshInstance3D
var npc: Node3D
var mission := 0
var step := 0
var unlocked := 0
var rewards := 0
var elapsed := 0.0
var clock := 8.2
var language := "bn"
var quality := 1
var outfit := 0
var playing := false
var paused := false
var notice_time := 0.0
var rain := false
var talked := false
var jumped := false
var goals: Array[Vector3] = []
var mission_names := ["Basic Training","Training Ground","First Border Patrol","Jeep Driving","Missing Child Rescue","River Rescue","Suspicious Cargo Inspection","Night Search Mission","Flood Rescue","Communications Repair","Forest Fire Rescue","Operation Sobujchar"]
var mission_bn := ["প্রাথমিক প্রশিক্ষণ","প্রশিক্ষণ মাঠ","প্রথম টহল","জিপ চালনা","নিখোঁজ শিশু উদ্ধার","নদীতে উদ্ধার","মালামাল পরীক্ষা","রাতে অনুসন্ধান","বন্যায় উদ্ধার","যোগাযোগ মেরামত","বন আগুনে উদ্ধার","অপারেশন সবুজচর"]
# First four are playable; later missions remain explicitly unavailable until distinct mechanics exist.
var routes := [
	[Vector3(0,0,-12),Vector3(-12,0,-23),Vector3(0,0,8)],
	[Vector3(12,0,-20),Vector3(16,0,-34),Vector3(-12,0,-23)],
	[Vector3(0,0,-65),Vector3(36,0,-90),Vector3(0,0,8)],
	[Vector3(9,0,9),Vector3(0,0,-75),Vector3(0,0,8)]
]
func tr2(bn: String,en: String) -> String:
	return bn if language == "bn" else en
func _ready() -> void:
	make_world()
	make_ui()
	load_game(false)
	show_menu()
	if "--physics-test" in OS.get_cmdline_user_args():
		physics_test.call_deferred()
	if "--smoke" in OS.get_cmdline_user_args():
		smoke_test.call_deferred()
func box(pos: Vector3,size: Vector3,color: Color,solid: bool = true) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	mesh.material_override = mat
	mesh.position = pos
	add_child(mesh)
	if solid:
		var body := StaticBody3D.new()
		var collision := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = size
		collision.shape = bs
		body.add_child(collision)
		mesh.add_child(body)
	return mesh
func make_world() -> void:
	environment = WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("9cb6ba")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("c9d7cf")
	env.ambient_light_energy = 0.65
	environment.environment = env
	add_child(environment)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48,-25,0)
	sun.light_color = Color("ffe5bb")
	sun.light_energy = 1.2
	add_child(sun)
	landscape = Sylhet.new()
	add_child(landscape)
	landscape.build(self)
	var road := box(Vector3(0,-0.04,-20),Vector3(9,0.12,350),Color.WHITE,false)
	road.material_override = landscape.dirt_mat

	box(Vector3(86,0.4,-90),Vector3(30,0.6,7),Color("8e836b"))
	for x in [73,99]:
		box(Vector3(x,1,-90),Vector3(0.3,1.2,7),Color("716854"))
	# Training camp, barracks and open entrance.
	for x in [-24,24]:
		house(Vector3(x,0,15),Vector3(12,5,16),Color("b4af89"))
	for z in [-36,36]:
		box(Vector3(-23,1,z),Vector3(32,2,0.3),Color("686d53"))
	box(Vector3(-40,1,0),Vector3(0.3,2,72),Color("686d53"))
	for i in 5:
		box(Vector3(12+i*2,0.35,-27),Vector3(0.8,0.7,1),Color("9a7852"))
	# Village: raised plinths, brick walls, corrugated gabled roofs.
	for i in 14:
		var pos := Vector3(-80+(i%4)*18,0,-70-(i/4)*24)
		house(pos,Vector3(9,3.2,7),Color("ad8060") if i%2 == 0 else Color("b7ab87"))
	for i in 6:
		box(Vector3(-120+i*20,0.05,65),Vector3(16,0.1,52),Color("8a9b39") if i%2==0 else Color("6a8d43"),false)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in 150:
		var pos := Vector3(rng.randf_range(-190,190),0,rng.randf_range(-190,190))
		if absf(pos.x)<45 or (pos.x>70 and pos.x<102) or (pos.x<0 and pos.z< -50 and pos.x> -100):
			continue
		tree_at(pos,rng.randf_range(0.8,1.5))
	landscape.finish_trees()
	player = Player.new()
	player.position = Vector3(0,1,8)
	add_child(player)
	jeep = Jeep.new()
	jeep.position = Vector3(9,1,9)
	add_child(jeep)
	npc = Node3D.new()
	npc.position = Vector3(-12,0,-23)
	add_child(npc)
	var npc_mesh := box(npc.position+Vector3(0,1,0),Vector3(0.6,1.8,0.4),Color("64714b"),false)
	npc_mesh.name = "TrainingOfficer"
	var head := box(npc.position+Vector3(0,2,0),Vector3(0.35,0.35,0.35),Color("bc8a64"),false)
	head.name = "OfficerHead"
	marker = box(Vector3(0,2,-12),Vector3(0.8,3,0.8),Color("e9c667"),false)
	marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	apply_quality()
func house(pos: Vector3,size: Vector3,color: Color) -> void:
	box(pos+Vector3(0,0.3,0),Vector3(size.x+1,0.6,size.z+1),Color("77766a"))
	var wall := box(pos+Vector3(0,size.y/2+0.6,0),size,color)
	wall.material_override = landscape.brick_mat
	# Shaded veranda, timber posts, window shutters and entrance steps.
	box(pos+Vector3(0,0.35,size.z/2+1.2),Vector3(size.x+0.6,0.5,2.4),Color("918c7c"))
	var awning := box(pos+Vector3(0,size.y+0.35,size.z/2+1.1),Vector3(size.x+1,0.12,3),Color.WHITE)
	awning.material_override = landscape.roof_mat
	awning.rotation.x = 0.14
	for x in [-size.x/2,size.x/2]:
		box(pos+Vector3(x,size.y/2+0.5,size.z/2+2.1),Vector3(0.13,size.y,0.13),Color("635442"))
	for i in 3:
		box(pos+Vector3(0,0.12+float(i)*0.08,size.z/2+2.4-float(i)*0.25),Vector3(2,0.16,0.7),Color("898272"))
	for sign_x in [-1,1]:
		var roof := box(pos+Vector3(sign_x*size.x*0.25,size.y+1,0),Vector3(size.x*0.57,0.18,size.z+1.5),Color("57676b"))
		roof.material_override = landscape.roof_mat
		roof.rotation.z = -sign_x*0.32
	box(pos+Vector3(0,1.5,size.z/2+0.03),Vector3(1.5,2.3,0.1),Color("493b2c"),false)
	for x in [-size.x*0.3,size.x*0.3]:
		box(pos+Vector3(x,2,size.z/2+0.05),Vector3(1.4,1.1,0.1),Color("364b4d"),false)
func tree_at(pos: Vector3,s: float) -> void:
	landscape.make_tree(pos,s)
func make_ui() -> void:
	hud = CanvasLayer.new()
	add_child(hud)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.add_child(root)
	var theme := Theme.new()
	theme.default_font = load("res://assets/Bengali.ttf")
	theme.default_font_size = 21
	root.theme = theme
	objective = Label.new()
	objective.position = Vector2(28,22)
	root.add_child(objective)
	stats = Label.new()
	stats.position = Vector2(28,95)
	root.add_child(stats)
	message = Label.new()
	message.position = Vector2(320,600)
	message.size = Vector2(600,70)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(message)
	touch = Touch.new()
	root.add_child(touch)
	touch.look.connect(func(delta: Vector2):
		if playing and not paused:
			player.yaw -= delta.x*0.004
			player.pitch = clampf(player.pitch-delta.y*0.004,-1.1,0.5))
	button(root,"II",Vector2(1185,24),Vector2(65,55),toggle_pause)
	button(root,"↥",Vector2(1170,500),Vector2(80,65),func(): player.jump_requested = true)
	button(root,"C",Vector2(1070,575),Vector2(80,65),func(): player.crouched = not player.crouched)
	var run_btn := button(root,"RUN",Vector2(1170,575),Vector2(80,65),func(): pass)
	run_btn.button_down.connect(func(): player.running = true)
	run_btn.button_up.connect(func(): player.running = false)
	button(root,"E",Vector2(1070,490),Vector2(80,65),interact)
	button(root,"VIEW",Vector2(1170,400),Vector2(80,65),func(): player.first_person = not player.first_person)
	minimap = Control.new()
	minimap.position = Vector2(1040,100)
	minimap.size = Vector2(200,200)
	minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	minimap.draw.connect(draw_minimap)
	root.add_child(minimap)
	combat = Combat.new()
	add_child(combat)
	combat.setup(self,root)
	menu = PanelContainer.new()
	menu.position = Vector2(370,50)
	menu.size = Vector2(540,620)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035,0.09,0.075,0.96)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	menu.add_theme_stylebox_override("panel",style)
	root.add_child(menu)
	menu_box = VBoxContainer.new()
	menu_box.add_theme_constant_override("separation",9)
	menu.add_child(menu_box)
func button(parent: Node,text: String,pos: Vector2,size: Vector2,action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.custom_minimum_size = size
	b.size = size
	b.pressed.connect(action)
	parent.add_child(b)
	return b
func clear_menu(title: String) -> void:
	for c in menu_box.get_children():
		menu_box.remove_child(c)
		c.queue_free()
	var heading := Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size",27)
	menu_box.add_child(heading)
	menu.show()
func item(text: String,action: Callable) -> Button:
	return button(menu_box,text,Vector2.ZERO,Vector2(470,45),action)
func show_menu() -> void:
	paused = true
	clear_menu("BORDER GUARDIAN\nBANGLADESH")
	var sub := Label.new()
	sub.text = tr2("কাল্পনিক উদ্ধার ও প্রশিক্ষণ অভিযান\nকোনো সরকারি সংস্থার অনুমোদিত নয়","Fictional rescue & training simulator\nNot affiliated with any government agency")
	menu_box.add_child(sub)
	item(tr2("দলীয় যুদ্ধ • Offline Bots","Team Match • Offline Bots"),combat.start_match)
	item(tr2("খেলা শুরু","Start Game"),func(): start_mission(0))
	item(tr2("চালিয়ে যান","Continue"),func():
		if combat.active:
			resume()
		elif FileAccess.file_exists("user://save.json") or OS.has_feature("web"):
			load_game(true)
		else:
			start_mission(0))
	item(tr2("মিশন নির্বাচন","Mission Selection"),mission_menu)
	item(tr2("সেটিংস","Settings"),settings_menu)
	if playing:
		item(tr2("ফিরে যান","Resume"),resume)
func mission_menu() -> void:
	clear_menu(tr2("মিশন নির্বাচন","Mission Selection"))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(470,435)
	menu_box.add_child(scroll)
	var list := VBoxContainer.new()
	scroll.add_child(list)
	for i in mission_names.size():
		var title: String = mission_bn[i] if language == "bn" else mission_names[i]
		var available := i<4 and i<=unlocked
		var b := button(list,str(i+1)+". "+title+("" if available else tr2(" — শীঘ্রই"," — Locked / Coming soon")),Vector2.ZERO,Vector2(450,48),start_mission.bind(i))
		b.disabled = not available
	item(tr2("ফিরে যান","Back"),show_menu)
func settings_menu() -> void:
	clear_menu(tr2("সেটিংস","Settings"))
	item("বাংলা / English",func():
		language = "en" if language == "bn" else "bn"
		save_game()
		settings_menu())
	for i in 3:
		item(["Low • 30 FPS","Medium • 60 FPS","High • 60 FPS"][i]+(" ✓" if quality == i else ""),func():
			quality = i
			apply_quality()
			save_game()
			settings_menu())
	item(tr2("মূল চরিত্র: Rafi","Main character: Rafi"),func(): pass).disabled = true
	item(tr2("বৃষ্টি চালু / বন্ধ","Toggle rain atmosphere"),func(): rain = not rain)
	item(tr2("ফিরে যান","Back"),show_menu)
func apply_quality() -> void:
	Engine.max_fps = 30 if quality == 0 else 60
	sun.shadow_enabled = quality>0
	get_viewport().scaling_3d_scale = [0.7,0.85,1.0][quality]
func start_mission(index: int) -> void:
	if is_instance_valid(combat): combat.stop_match()
	if index<0 or index>=4 or index>unlocked:
		return
	mission = index
	step = 0
	talked = false
	jumped = false
	elapsed = 0
	goals.assign(routes[mission])
	player.position = Vector3(0,1,8)
	player.health = 100
	player.stamina = 100
	if player.driving:
		leave_vehicle()
	jeep.position = Vector3(9,1,9)
	jeep.rotation = Vector3.ZERO
	jeep.speed = 0
	playing = true
	update_marker()
	resume()
	save_game()
func resume() -> void:
	paused = false
	menu.hide()
func toggle_pause() -> void:
	if not playing:
		return
	if paused:
		resume()
	else:
		save_game()
		show_menu()
func interact() -> void:
	if not playing or paused:
		return
	if player.driving:
		leave_vehicle()
	elif player.position.distance_to(jeep.position)<5:
		player.driving = true
		player.hide()
		player.collision_layer = 0
		player.collision_mask = 0
		jeep.active = true
		jeep.camera.make_current()
	elif player.position.distance_to(npc.position)<4:
		talked = true
		notify(tr2("প্রশিক্ষক: হলুদ চিহ্ন অনুসরণ করুন। নিরাপদ থাকুন।","Officer: Follow the yellow markers. Stay safe."))
func leave_vehicle() -> void:
	player.driving = false
	player.show()
	player.collision_layer = 1
	player.collision_mask = 1
	player.position = jeep.position+jeep.basis.x*3+Vector3.UP
	jeep.active = false
	jeep.throttle = 0
	player.camera.make_current()
func update_marker() -> void:
	marker.position = goals[step]+Vector3(0,2,0)
func notify(text: String) -> void:
	message.text = text
	notice_time = 5
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_ESCAPE: toggle_pause()
			KEY_SPACE: player.jump_requested = true
			KEY_C: player.crouched = not player.crouched
			KEY_E: interact()
			KEY_V: player.first_person = not player.first_person
			KEY_R: combat.reload_weapon()
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and not paused:
		player.yaw -= event.relative.x*0.004
		player.pitch = clampf(player.pitch-event.relative.y*0.004,-1.1,0.5)
func _process(dt: float) -> void:
	player.set_physics_process(playing and not paused)
	jeep.set_physics_process(playing and not paused)
	touch.visible = playing and not paused
	if not playing or paused:
		return
	elapsed += dt
	clock = fmod(clock+dt/120,24)
	sun.rotation_degrees.x = -sin((clock-6)/24*TAU)*65
	sun.light_energy = maxf(0.08,sin((clock-6)/24*TAU)*1.2)*(0.6 if rain else 1.0)
	environment.environment.background_color = Color("627981") if rain else Color("9cb6ba")
	player.stick = touch.move_axis
	if player.driving:
		player.position = jeep.position
		jeep.throttle = touch.move_axis.y + float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W))
		jeep.steering = touch.move_axis.x + float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A))
	var pos: Vector3 = jeep.position if player.driving else player.position
	# River is hazardous outside the bridge; prototype has no swimming yet.
	if pos.x>77 and pos.x<95 and absf(pos.z+90)>5:
		player.health -= dt*18
	if combat.active:
		objective.text = tr2("কাল্পনিক দলীয় ম্যাচ • মিত্র সবুজ, প্রতিপক্ষ বাদামি","Fictional match • Allies green, opponents brown")
		stats.text = tr2("স্বাস্থ্য ","Health ")+str(int(player.health))+" • "+str(Engine.get_frames_per_second())+" FPS"
		minimap.queue_redraw()
		if notice_time>0: notice_time-=dt
		else: message.text=""
		return
	if player.health<=0 or elapsed>600:
		fail_mission()
		return
	if not player.is_on_floor() and player.velocity.y>1:
		jumped = true
	var gate := (mission!=0 or step!=1 or talked) and (mission!=1 or step!=1 or jumped)
	if pos.distance_to(goals[step])<4 and (mission!=3 or player.driving) and gate:
		advance_objective()
	var distance := int(pos.distance_to(goals[step]))
	objective.text = (mission_bn[mission] if language == "bn" else mission_names[mission])+"  •  "+str(step+1)+"/"+str(goals.size())+"\n"+instruction()+"  •  "+str(distance)+" m"
	stats.text = tr2("স্বাস্থ্য","Health")+" "+str(int(player.health))+"  |  "+tr2("শক্তি","Stamina")+" "+str(int(player.stamina))+"  |  "+str(Engine.get_frames_per_second())+" FPS\n"+tr2("পুরস্কার","Rewards")+": "+str(rewards)+"  •  "+("Rain" if rain else "Clear")
	marker.rotation.y += dt
	minimap.queue_redraw()
	if notice_time>0:
		notice_time -= dt
	else:
		message.text = ""
func instruction() -> String:
	if mission == 0:
		return [tr2("হলুদ চিহ্নে হেঁটে যান","Walk to the yellow marker"),tr2("প্রশিক্ষকের কাছে যান • E দিয়ে কথা","Visit officer • E to talk"),tr2("শুরুর স্থানে ফিরে যান","Return to start")][step]
	if mission == 3:
		return tr2("জিপের কাছে E চাপুন, তারপর চিহ্নে চালান","Press E near jeep; drive to markers")
	if mission == 1 and step == 1:
		return tr2("লাফ দিন, তারপর হলুদ চিহ্নে যান","Jump, then reach the yellow marker")
	return tr2("হলুদ চিহ্ন অনুসরণ করুন • নদী এড়িয়ে চলুন","Follow markers • avoid the river")
func advance_objective() -> void:
	step += 1
	if step>=goals.size():
		rewards += 100*(mission+1)
		unlocked = mini(3,maxi(unlocked,mission+1))
		step = 0
		save_game()
		paused = true
		clear_menu(tr2("মিশন সম্পূর্ণ!","Mission complete!"))
		item(tr2("পরের মিশন","Next mission"),func(): start_mission(mini(3,mission+1)))
		item(tr2("প্রধান মেনু","Main menu"),show_menu)
	else:
		update_marker()
		notify(tr2("লক্ষ্য সম্পন্ন! পরের চিহ্নে যান।","Objective complete! Follow the next marker."))
func fail_mission() -> void:
	paused = true
	clear_menu(tr2("মিশন ব্যর্থ • স্বাস্থ্য / সময় শেষ","Mission failed • health / time exhausted"))
	item(tr2("আবার চেষ্টা","Retry"),func(): start_mission(mission))
	item(tr2("প্রধান মেনু","Main menu"),show_menu)
func draw_minimap() -> void:
	minimap.draw_rect(Rect2(0,0,200,200),Color(0.03,0.1,0.08,0.85))
	minimap.draw_line(Vector2(143,0),Vector2(143,200),Color("589caa"),9)
	minimap.draw_line(Vector2(100,0),Vector2(100,200),Color("b3a078"),4)
	minimap.draw_circle(Vector2(player.position.x,player.position.z)/2+Vector2(100,100),4,Color.WHITE)
	if is_instance_valid(combat) and combat.active:
		minimap.draw_line(Vector2(135,0),Vector2(135,200),Color("edcc6b"),1)
		for actor in combat.actors:
			if actor.dead_left>0:continue
			minimap.draw_circle(Vector2(actor.position.x,actor.position.z)/2+Vector2(100,100),2,[Color("69d580"),Color("ee9471"),Color("c8c7b6")][actor.team])
	if not goals.is_empty() and not combat.active:
		minimap.draw_circle(Vector2(goals[step].x,goals[step].z)/2+Vector2(100,100),5,Color("edcc6b"))
func save_game() -> void:
	if is_instance_valid(combat) and combat.active: return
	var data := {"version":1,"visual_revision":2,"unlocked":unlocked,"rewards":rewards,"mission":mission,"step":step,"elapsed":elapsed,"talked":talked,"jumped":jumped,"position":[player.position.x,player.position.y,player.position.z],"health":player.health,"stamina":player.stamina,"language":language,"quality":quality,"outfit":outfit}
	if OS.has_feature("web"):
		var encoded := Marshalls.utf8_to_base64(JSON.stringify(data))
		JavaScriptBridge.eval("try { localStorage.setItem('bgb-save-v1','"+encoded+"'); } catch(e) {}", true)
	var file := FileAccess.open("user://save.tmp",FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()
		DirAccess.rename_absolute("user://save.tmp","user://save.json")
func load_game(continue_game: bool) -> void:
	var saved := ""
	if OS.has_feature("web"):
		var encoded = JavaScriptBridge.eval("(function(){try{return localStorage.getItem('bgb-save-v1')||'';}catch(e){return '';}})()", true)
		if encoded is String and not encoded.is_empty():
			saved = Marshalls.base64_to_utf8(encoded)
	if saved.is_empty() and FileAccess.file_exists("user://save.json"):
		saved = FileAccess.get_file_as_string("user://save.json")
	if saved.is_empty():
		if continue_game:
			start_mission(0)
		return
	var data = JSON.parse_string(saved)
	if not data is Dictionary or data.get("version")!=1:
		return
	unlocked = clampi(int(data.get("unlocked",0)),0,3)
	rewards = maxi(0,int(data.get("rewards",0)))
	language = "en" if data.get("language")=="en" else "bn"
	quality = 1 if int(data.get("visual_revision",0)) < 2 else clampi(int(data.get("quality",1)),0,2)
	outfit = clampi(int(data.get("outfit",0)),0,2)
	apply_quality()
	if continue_game:
		mission = clampi(int(data.get("mission",0)),0,unlocked)
		goals.assign(routes[mission])
		step = clampi(int(data.get("step",0)),0,goals.size()-1)
		elapsed = clampf(float(data.get("elapsed",0)),0,600)
		talked = bool(data.get("talked",false))
		jumped = bool(data.get("jumped",false))
		var p = data.get("position",[0,1,8])
		if p is Array and p.size()==3:
			player.position = Vector3(clampf(float(p[0]),-198,198),maxf(1,float(p[1])),clampf(float(p[2]),-198,198))
		player.health = clampf(float(data.get("health",100)),1,100)
		player.stamina = clampf(float(data.get("stamina",100)),0,100)
		playing = true
		update_marker()
		resume()
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED and is_instance_valid(player):
		save_game()
		paused = true
func smoke_test() -> void:
	start_mission(0)
	assert(playing and goals.size()==3)
	for i in 3:
		advance_objective()
	assert(unlocked>=1 and rewards>=100)
	start_mission(1)
	assert(mission==1 and step==0)
	player.position = npc.position
	interact()
	assert(notice_time>0)
	player.position = jeep.position+Vector3(3,0,0)
	interact()
	assert(player.driving and jeep.active)
	leave_vehicle()
	assert(not player.driving and not jeep.active)
	step = 1
	save_game()
	step = 0
	load_game(true)
	assert(step==1)
	player.health = 0
	fail_mission()
	assert(paused and menu.visible)
	print("SMOKE PASS: world, mission progression, NPC, vehicle entry/exit, save/continue, failure menu")
	get_tree().quit()

func physics_test() -> void:
	unlocked = 3
	start_mission(0)
	for i in 40:
		await get_tree().physics_frame
	assert(player.is_on_floor(), "Player must land on terrain")
	var start: Vector3 = player.position
	player.stick = Vector2(0,-1)
	touch.move_axis = Vector2(0,-1)
	for i in 40:
		await get_tree().physics_frame
	assert(player.position.distance_to(start)>1, "Joystick must move character")
	touch.move_axis = Vector2.ZERO
	player.jump_requested = true
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert(player.velocity.y>0, "Jump must generate upward velocity")
	for i in 60:
		await get_tree().physics_frame
	assert(player.is_on_floor())
	player.running = true
	touch.move_axis = Vector2(1,0)
	for i in 25:
		await get_tree().physics_frame
	assert(player.stamina<100, "Running must consume stamina")
	player.running = false
	touch.move_axis = Vector2.ZERO
	player.crouched = true
	await get_tree().physics_frame
	assert(player.visual.scale.y<1)
	player.crouched = false
	player.position = jeep.position+Vector3(3,0,0)
	interact()
	var vehicle_start: Vector3 = jeep.position
	touch.move_axis = Vector2(0,-1)
	for i in 60:
		await get_tree().physics_frame
	assert(jeep.position.distance_to(vehicle_start)>1, "Vehicle must drive")
	touch.move_axis = Vector2.ZERO
	leave_vehicle()
	paused = true
	var stopped: Vector3 = player.position
	for i in 10:
		await get_tree().physics_frame
	assert(player.position.distance_to(stopped)<0.01, "Pause must freeze character")
	# Multi-touch joystick press, drag and release.
	var press := InputEventScreenTouch.new()
	press.index = 4
	press.position = Vector2(100,600)
	press.pressed = true
	touch._input(press)
	var drag := InputEventScreenDrag.new()
	drag.index = 4
	drag.position = Vector2(100,535)
	touch._input(drag)
	assert(touch.move_axis.y< -0.9)
	press.pressed = false
	touch._input(press)
	assert(touch.move_axis == Vector2.ZERO)
	print("PHYSICS PASS: terrain collision, joystick movement, jump/land, sprint stamina, crouch, vehicle movement, pause, touch release")
	get_tree().quit()
