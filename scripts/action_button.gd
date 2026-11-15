extends Button
var kind:=""
func _draw() -> void:
	var center:=size*.5;var radius:=minf(size.x,size.y)*.47
	var selected:=bool(get_meta("selected",false))
	if kind.begins_with("SLOT"):
		draw_rect(Rect2(Vector2.ZERO,size),Color(1,1,1,.25) if selected else Color(0,0,0,.3))
		draw_rect(Rect2(Vector2.ZERO,size),Color(1,1,1,.75),false,1)
		draw_line(Vector2(30,20),Vector2(100,20),Color.WHITE,3,true);draw_line(Vector2(60,20),Vector2(55,32),Color.WHITE,3,true)
		var name_text:=str(get_meta("weapon_name","EMPTY"))
		draw_string(get_theme_default_font(),Vector2(8,46),name_text,HORIZONTAL_ALIGNMENT_LEFT,size.x-12,11,Color.WHITE)
		return
	draw_circle(center,radius,Color(1,1,.8,.27) if is_pressed() or selected or bool(get_meta("touch_down",false)) else Color(.02,.025,.025,.23))
	draw_arc(center,radius,0,TAU,48,Color(1,1,1,.65),1.5,true)
	var c:=Color(1,1,1,.92);var k:=radius*.65
	if kind in ["FIRE","FIRE_L","ADS"]:
		draw_arc(center,k*.57,0,TAU,32,c,2,true)
		for d in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:draw_line(center+d*k*.25,center+d*k,c,2,true)
	elif kind in ["CROUCH","PRONE","JUMP","SPRINT","STAND"]:
		var horizontal:=kind=="PRONE"
		var head:=center+Vector2(-.65,-.1)*k if horizontal else center+Vector2(0,-.6)*k
		draw_circle(head,k*.18,c)
		var hip:=center+Vector2(.15,.25)*k
		var neck:=head+Vector2(.28,.04)*k if horizontal else head+Vector2(0,.25)*k
		draw_line(neck,hip,c,3,true)
		if horizontal:
			draw_line(hip,center+Vector2(.9,.4)*k,c,3,true);draw_line(neck,center+Vector2(-.8,.5)*k,c,3,true)
		elif kind=="CROUCH":
			draw_polyline(PackedVector2Array([hip,center+Vector2(.6,.45)*k,center+Vector2(-.15,.8)*k]),c,3,true)
			draw_line(neck,center+Vector2(.7,.05)*k,c,3,true)
		else:
			draw_polyline(PackedVector2Array([center+Vector2(-.6,.7)*k,hip,center+Vector2(.6,.8)*k]),c,3,true)
			draw_polyline(PackedVector2Array([center+Vector2(-.7,-.1)*k,neck,center+Vector2(.7,-.35)*k]),c,3,true)
	elif kind=="RELOAD":
		draw_arc(center,k*.7,-2.4,2.3,24,c,3,true);draw_line(center+Vector2(-.6,-.45)*k,center+Vector2(-.7,.12)*k,c,3,true)
	elif kind=="HEAL":
		draw_line(center+Vector2(-k*.7,0),center+Vector2(k*.7,0),c,5,true);draw_line(center+Vector2(0,-k*.7),center+Vector2(0,k*.7),c,5,true)
	elif kind=="SWAP":
		for y in [-.35,.35]:draw_line(center+Vector2(-.8,y)*k,center+Vector2(.8,y)*k,c,3,true)
		draw_line(center+Vector2(.8,-.35)*k,center+Vector2(.3,-.7)*k,c,3,true)
		draw_line(center+Vector2(-.8,.35)*k,center+Vector2(-.3,.7)*k,c,3,true)
	elif kind=="II":
		for x in [-.25,.25]:draw_line(center+Vector2(x,-.55)*k,center+Vector2(x,.55)*k,c,3,true)
	elif kind=="VIEW":
		draw_arc(center,k*.65,0,TAU,24,c,2,true);draw_circle(center,k*.2,c)
	else:
		draw_rect(Rect2(center-Vector2(k*.5,k*.5),Vector2.ONE*k),c,false,2)
	if kind not in ["FIRE","FIRE_L","II","ADS"]:
		var font:=get_theme_default_font();var caption:=kind
		var w:=font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,10).x
		draw_string(font,Vector2(center.x-w*.5,size.y-5),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,10,c)
