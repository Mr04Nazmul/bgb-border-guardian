extends Node3D
# Original low-poly visual prop inspired by public patrol photographs, not a functional design.
func block(label: String,p: Vector3,s: Vector3,c: Color) -> MeshInstance3D:
	var m:=MeshInstance3D.new();var mesh:=BoxMesh.new();mesh.size=s;m.mesh=mesh;m.name=label;m.position=p
	var mat:=StandardMaterial3D.new();mat.albedo_color=c;mat.roughness=0.55;mat.metallic=0.6 if c.r<0.2 else 0.0;m.material_override=mat
	add_child(m);return m
func _ready() -> void:
	var steel:=Color("303834");var wood:=Color("69513a");var dark:=Color("19201d")
	block("Receiver",Vector3(0,0,0),Vector3(.075,.105,.29),steel)
	block("ShoulderStock",Vector3(0,-.015,.25),Vector3(.065,.13,.24),wood)
	block("StockPad",Vector3(0,-.015,.375),Vector3(.073,.14,.022),dark)
	block("Handguard",Vector3(0,-.01,-.235),Vector3(.075,.09,.19),wood)
	block("UpperCover",Vector3(0,.065,-.04),Vector3(.055,.035,.22),dark)
	block("Grip",Vector3(0,-.115,.075),Vector3(.05,.14,.065),dark).rotation.x=-.18
	for i in 4:
		var mag:=block("Magazine%d"%i,Vector3(0,-.09-float(i)*.041,-.065-float(i*i)*.004),Vector3(.043,.052,.073),steel)
		mag.rotation.x=float(i)*.12
	block("TriggerGuard",Vector3(0,-.075,.035),Vector3(.055,.018,.08),dark)
	block("Barrel",Vector3(0,.012,-.43),Vector3(.027,.027,.24),dark)
	block("FrontSight",Vector3(0,.065,-.48),Vector3(.025,.09,.03),steel)
	block("RearSight",Vector3(0,.085,.025),Vector3(.055,.035,.03),steel)
	for i in 5:block("Vent%d"%i,Vector3(.039,.025,-.16-float(i)*.027),Vector3(.004,.014,.012),dark)
	var muzzle:=Marker3D.new();muzzle.name="Muzzle";muzzle.position=Vector3(0,.012,-.56);add_child(muzzle)
