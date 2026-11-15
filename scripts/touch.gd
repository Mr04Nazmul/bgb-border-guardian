extends Control
var move_axis := Vector2.ZERO
var move_id := -1
var look_id := -1
var origin := Vector2.ZERO
var knob := Vector2.ZERO
var actions: Array[Dictionary]=[]
var held: Dictionary={}
var reserved: Array[Rect2]=[]
var fire_rect:=Rect2(1070,375,90,90)
var deadzone:=0.12
signal look(delta: Vector2)
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
func _input(event: InputEvent) -> void:
	if not visible:return
	if event is InputEventScreenTouch:
		if event.pressed:
			for action in actions:
				if action.button.visible and not action.button.disabled and action.area.has_point(event.position):
					held[event.index]=action.button
					action.button.button_down.emit();action.button.pressed.emit()
					if fire_rect.has_point(event.position) and look_id==-1:look_id=event.index
					get_viewport().set_input_as_handled();return
		elif held.has(event.index):
			held[event.index].button_up.emit();held.erase(event.index)
			if look_id==event.index:look_id=-1
			get_viewport().set_input_as_handled();return
		if event.pressed and event.position.x < size.x*0.35 and event.position.y > size.y*0.5 and move_id == -1:
			move_id = event.index
			origin = event.position
			knob = origin
		elif event.pressed and event.position.x > size.x*0.38 and look_id == -1 and can_look(event.position):
			look_id = event.index
		elif not event.pressed:
			if event.index == move_id:
				move_id = -1
				move_axis = Vector2.ZERO
			if event.index == look_id:
				look_id = -1
	if event is InputEventScreenDrag:
		if event.index == move_id:
			var raw: Vector2=((event.position-origin)/65).limit_length()
			move_axis=Vector2.ZERO if raw.length()<deadzone else raw.normalized()*(raw.length()-deadzone)/(1.0-deadzone)
			knob = origin+move_axis*65
		if event.index == look_id:
			look.emit(event.relative)
	queue_redraw()
func _draw() -> void:
	var center := origin if move_id >= 0 else Vector2(130,size.y-135)
	draw_circle(center,76,Color(0.03,0.12,0.1,0.45))
	draw_arc(center,76,0,TAU,48,Color(0.7,0.8,0.6,0.6),2)
	draw_circle(knob if move_id >= 0 else center,30,Color(0.7,0.8,0.6,0.55))

func can_look(point: Vector2) -> bool:
	if fire_rect.has_point(point):return true # drag-to-aim while holding fire
	for area in reserved:
		if area.has_point(point):return false
	return point.y>90
func reset() -> void:
	for b in held.values():
		b.button_up.emit()
	held.clear()
	move_axis=Vector2.ZERO;move_id=-1;look_id=-1;queue_redraw()
func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT:reset()
