extends Control
var move_axis := Vector2.ZERO
var move_id := -1
var look_id := -1
var origin := Vector2.ZERO
var knob := Vector2.ZERO
signal look(delta: Vector2)
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and event.position.x < size.x*0.35 and event.position.y > size.y*0.5 and move_id == -1:
			move_id = event.index
			origin = event.position
			knob = origin
		elif event.pressed and event.position.x > size.x*0.38 and event.position.x < size.x*0.82 and look_id == -1:
			look_id = event.index
		elif not event.pressed:
			if event.index == move_id:
				move_id = -1
				move_axis = Vector2.ZERO
			if event.index == look_id:
				look_id = -1
	if event is InputEventScreenDrag:
		if event.index == move_id:
			move_axis = ((event.position-origin)/65).limit_length()
			knob = origin+move_axis*65
		if event.index == look_id:
			look.emit(event.relative)
	queue_redraw()
func _draw() -> void:
	var center := origin if move_id >= 0 else Vector2(130,size.y-135)
	draw_circle(center,76,Color(0.03,0.12,0.1,0.45))
	draw_arc(center,76,0,TAU,48,Color(0.7,0.8,0.6,0.6),2)
	draw_circle(knob if move_id >= 0 else center,30,Color(0.7,0.8,0.6,0.55))
