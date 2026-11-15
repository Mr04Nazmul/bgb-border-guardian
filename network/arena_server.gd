extends SceneTree
# Standalone authoritative Godot WebSocket server. Put behind TLS for browser clients.
var listener:=TCPServer.new()
var peers: Dictionary={}
var players: Dictionary={}
var next_id:=1
var world: Node3D
var running:=false
var finished:=false
var match_time:=0.0
var broadcast_left:=0.0
var now:=0.0
var port:=9080
var zone_radius:=230.0
func _initialize() -> void:boot.call_deferred()
func boot() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--port="):port=int(arg.split("=")[1])
	world=load("res://main.tscn").instantiate();root.add_child(world)
	world.playing=false;world.paused=true;world.player.hide();world.player.collision_layer=0;world.player.collision_mask=0
	for actor in world.combat.actors:actor.collision_layer=0;actor.collision_mask=0;actor.hide()
	var error:=listener.listen(port,"0.0.0.0")
	if error!=OK:printerr("SERVER ERROR ",error);quit(1);return
	print("ARENA SERVER READY ",port)
func send(id: int,data: Dictionary) -> void:
	if peers.has(id) and peers[id].socket.get_ready_state()==WebSocketPeer.STATE_OPEN:peers[id].socket.send_text(JSON.stringify(data))
func packet(id: int,data: Dictionary) -> void:
	match str(data.get("type","")):
		"join":
			if players.has(id):return
			if running or players.size()>=4:send(id,{"type":"error","message":"Room full or match already started"});return
			var node:=CharacterBody3D.new();var shape:=CollisionShape3D.new();var capsule:=CapsuleShape3D.new();capsule.radius=.32;capsule.height=1.85;shape.shape=capsule;shape.position.y=.95;node.add_child(shape);world.add_child(node)
			node.position=[Vector3(-3,2,8),Vector3(3,2,-12),Vector3(-3,2,-30),Vector3(3,2,25)][players.size()]
			players[id]={"node":node,"shape":shape,"name":str(data.get("name","Player")).substr(0,20),"axis":Vector2.ZERO,"yaw":0.0,"pitch":0.0,"health":100.0,"stamina":100.0,"ammo":24,"reserve":144,"reload":0.0,"cooldown":0.0,"seq":-1,"fire":false,"jump":false,"stance":"stand","shots":0,"last_command":now}
			send(id,{"type":"joined","id":id});broadcast()
		"start":
			if not players.is_empty() and id==players.keys()[0] and players.size()>=2 and not running:
				running=true;finished=false;match_time=0;zone_radius=230
				var index:=0
				for player in players.values():
					player.node.position=[Vector3(-3,2,8),Vector3(3,2,-12),Vector3(-3,2,-30),Vector3(3,2,25)][index];index+=1
					player.node.velocity=Vector3.ZERO;player.node.collision_layer=1;player.health=100;player.ammo=24;player.reserve=144;player.reload=0;player.fire=false;player.cooldown=0;player.stance="stand"
				broadcast()
		"input":
			if not running or not players.has(id):return
			var p: Dictionary=players[id]
			for key in ["seq","x","z","yaw","pitch"]:
				if typeof(data.get(key,0)) not in [TYPE_INT,TYPE_FLOAT]:return
			var sequence:=int(data.get("seq",-1))
			if sequence<=p.seq:return
			var x:=float(data.get("x",0));var z:=float(data.get("z",0));var yaw:=float(data.get("yaw",0));var pitch:=float(data.get("pitch",0))
			if not is_finite(x) or not is_finite(z) or not is_finite(yaw) or not is_finite(pitch):return
			p.seq=sequence;p.axis=Vector2(x,z).limit_length();p.yaw=wrapf(yaw,-PI,PI);p.pitch=clampf(pitch,-1.15,.65);p.fire=bool(data.get("fire",false));p.jump=bool(data.get("jump",false));p.last_command=now
			var stance:=str(data.get("stance","stand"))
			if stance in ["stand","crouch","prone"]:p.stance=stance
			if bool(data.get("reload",false)) and p.ammo<24 and p.reserve>0 and p.reload<=0:p.reload=1.8
func broadcast() -> void:
	var roster: Array=[]
	for id in players:
		var p: Dictionary=players[id];var v: Vector3=p.node.position
		roster.append({"id":id,"name":p.name,"pos":[v.x,v.y,v.z],"yaw":p.yaw,"pitch":p.pitch,"hp":p.health,"ammo":p.ammo,"reserve":p.reserve,"reload":p.reload,"stance":p.stance,"shots":p.shots})
	for id in players:send(id,{"type":"state","running":running,"finished":finished,"host":players.keys()[0] if not players.is_empty() else -1,"time":match_time,"radius":zone_radius,"players":roster})
func _process(dt: float) -> bool:
	now+=dt
	while listener.is_connection_available():
		var socket:=WebSocketPeer.new();socket.accept_stream(listener.take_connection());peers[next_id]={"socket":socket,"last":now};next_id+=1
	for id in peers.keys():
		var socket: WebSocketPeer=peers[id].socket;socket.poll()
		if socket.get_ready_state()==WebSocketPeer.STATE_CLOSED or now-peers[id].last>20:
			socket.close();peers.erase(id)
			if players.has(id):players[id].node.queue_free();players.erase(id);broadcast()
			if players.is_empty():running=false;finished=false
			continue
		while socket.get_available_packet_count()>0:
			var bytes:=socket.get_packet()
			if bytes.size()>2048:socket.close(1009);break
			var data=JSON.parse_string(bytes.get_string_from_utf8())
			peers[id].last=now
			if data is Dictionary:packet(id,data)
	broadcast_left-=dt
	if broadcast_left<=0:broadcast_left=.1;broadcast()
	return false
func _physics_process(dt: float) -> bool:
	if not running:return false
	match_time+=dt;zone_radius=maxf(0,230-maxf(0,match_time-20)*.7)
	for id in players:
		var p: Dictionary=players[id]
		if p.health<=0:continue
		if now-p.last_command>.3:p.axis=Vector2.ZERO;p.fire=false
		p.cooldown=maxf(0,p.cooldown-dt)
		if p.fire and p.ammo<=0 and p.reserve>0 and p.reload<=0:p.reload=1.8
		if p.reload>0:
			p.reload-=dt
			if p.reload<=0:
				var take:=mini(24-p.ammo,p.reserve);p.ammo+=take;p.reserve-=take
		var body: CharacterBody3D=p.node
		var height: float=.65 if p.stance=="prone" else (1.5 if p.stance=="crouch" else 1.85)
		# A standing request must fit the authoritative world geometry.
		if height>p.shape.shape.height:
			var q:=PhysicsShapeQueryParameters3D.new();var cap:=CapsuleShape3D.new();cap.radius=.30;cap.height=height-.02;q.shape=cap;q.transform.origin=body.position+Vector3(0,height*.5+.035,0);q.exclude=[body.get_rid()]
			if not body.get_world_3d().direct_space_state.intersect_shape(q,1).is_empty():height=p.shape.shape.height
		p.shape.shape.height=height;p.shape.position.y=height*.5+.025
		var direction: Vector3=Basis(Vector3.UP,p.yaw)*Vector3(p.axis.x,0,p.axis.y)
		var speed:=.85 if height<1 else (1.7 if height<1.7 else 4.0)
		body.velocity.x=direction.x*speed;body.velocity.z=direction.z*speed
		body.velocity.y-=22*dt
		if p.jump and body.is_on_floor() and height>1.7:body.velocity.y=6.4
		p.jump=false;body.move_and_slide();body.position.x=clampf(body.position.x,-198,198);body.position.z=clampf(body.position.z,-198,198)
		if Vector2(body.position.x,body.position.z-45).length()>zone_radius:p.health=maxf(0,p.health-dt*4)
		if p.fire and p.cooldown<=0 and p.reload<=0 and p.ammo>0:
			p.cooldown=.16;p.ammo-=1;p.shots+=1
			var from: Vector3=body.position+Vector3(0,height*.72,0)
			var direction_fire: Vector3=Basis(Vector3.UP,p.yaw)*Basis(Vector3.RIGHT,p.pitch)*Vector3.FORWARD
			var query:=PhysicsRayQueryParameters3D.create(from,from+direction_fire*150);query.exclude=[body.get_rid()]
			var hit:=body.get_world_3d().direct_space_state.intersect_ray(query)
			if not hit.is_empty():
				for other_id in players:
					var victim: Dictionary=players[other_id]
					if victim.node==hit.collider:
						victim.health=maxf(0,victim.health-(68 if hit.position.y-victim.node.position.y>1.48 else 34))
						if victim.health<=0:victim.node.collision_layer=0
	var living: Array=[]
	for id in players:
		if players[id].health>0:living.append(id)
	if living.size()<=1:
		running=false;finished=true
		for id in players:send(id,{"type":"result","winner":living[0] if living.size()==1 else 0})
		broadcast()
	return false
