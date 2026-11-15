extends Control
var game: Node3D
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
func _process(_dt: float) -> void:queue_redraw()
func _draw() -> void:
	if not is_instance_valid(game) or not game.playing or game.paused:return
	var p: CharacterBody3D=game.player
	var hp:=Rect2(455,659,350,9)
	draw_rect(hp,Color(0,0,0,.6));draw_rect(Rect2(hp.position,Vector2(hp.size.x*p.health/100,hp.size.y)),Color("edecc1") if p.health>30 else Color("ed6955"))
	draw_rect(Rect2(455,673,350*p.stamina/100,3),Color("d0aa62"))
	if not game.combat.active:return
	var mid:=size*.5
	var spread: float=(4 if game.combat.aim else 9)+Vector2(p.velocity.x,p.velocity.z).length()*1.4+p.recoil*9
	var color: Color=Color("ed6955") if game.combat.blocked_left>0 else game.combat.crosshair.modulate
	for d in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:draw_line(mid+d*spread,mid+d*(spread+7),color,1.5,true)
	draw_circle(mid,1.2,Color.WHITE)
	if is_instance_valid(game.combat.assist.target):draw_arc(mid,22,0,TAU,36,Color("a9db9b"),1.5,true)
	if game.combat.aim:
		draw_arc(mid,70,0,TAU,64,Color(0,0,0,.28),1,true)
