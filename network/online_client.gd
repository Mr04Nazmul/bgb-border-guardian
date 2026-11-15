extends Node
var game: Node3D
var socket:=WebSocketPeer.new()
var connected:=false
var active:=false
var own_id:=-1
var sequence:=0
var send_left:=0.0
var elapsed:=0.0
var remotes: Dictionary={}
var status: Label
var reload_request:=false
var jump_request:=false
var last_shots:=-1
var lobby_players:=0
var host_id:=-1
func menu() -> void:
	game.clear_menu("ONLINE • CUSTOM SERVER")
	var info:=Label.new();info.text="WSS server address দিন\nServer hosting required";game.menu_box.add_child(info)
	var field:=LineEdit.new();field.placeholder_text="wss://your-server.example";field.custom_minimum_size.y=45;game.menu_box.add_child(field)
	game.item("CONNECT",func():connect_server(field.text))
	status=Label.new();status.text="Server not connected";status.add_theme_font_size_override("font_size",16);game.menu_box.add_child(status)
	game.item("START MATCH • Host only",func():send({"type":"start"}))
	game.item("BACK",func():disconnect_server();game.show_menu())
func connect_server(url: String) -> void:
	if not url.begins_with("wss://") and not (not OS.has_feature("web") and url.begins_with("ws://")):
		status.text="HTTPS browser requires wss://";return
	disconnect_server()
	var error:=socket.connect_to_url(url)
	if error!=OK:status.text="Connection error "+str(error);return
	elapsed=0;status.text="Connecting…"
func disconnect_server() -> void:
	socket.close();socket=WebSocketPeer.new();connected=false;active=false;own_id=-1;last_shots=-1
	for remote in remotes.values():
		if is_instance_valid(remote):
			game.combat.actors.erase(remote);remote.queue_free()
	remotes.clear()
func send(data: Dictionary) -> void:
	if socket.get_ready_state()==WebSocketPeer.STATE_OPEN:socket.send_text(JSON.stringify(data))
func _process(dt: float) -> void:
	socket.poll()
	if socket.get_ready_state()==WebSocketPeer.STATE_OPEN and not connected:
		connected=true;send({"type":"join","name":"Guardian"})
	if not connected:
		if socket.get_ready_state()==WebSocketPeer.STATE_CONNECTING:
			elapsed+=dt
			if elapsed>10:socket.close();if_valid_status("Connection timed out")
		return
	if socket.get_ready_state()!=WebSocketPeer.STATE_OPEN:
		disconnect_server();game.combat.stop_match();game.show_menu();game.notify("Online server disconnected");return
	while socket.get_available_packet_count()>0:
		var data=JSON.parse_string(socket.get_packet().get_string_from_utf8())
		if data is Dictionary:receive(data)
	send_left-=dt
	if send_left<=0:
		send_left=.05;sequence+=1
		var p: CharacterBody3D=game.player
		send({"type":"input" if active else "ping","seq":sequence,"x":p.stick.x if not game.paused else 0,"z":p.stick.y if not game.paused else 0,"yaw":p.yaw,"pitch":p.pitch,"stance":p.current_stance(),"fire":not game.paused and (game.combat.fire_held or game.combat.mouse_fire),"reload":reload_request,"jump":jump_request})
		reload_request=false;jump_request=false
func if_valid_status(text: String) -> void:
	if is_instance_valid(status):status.text=text
func receive(data: Dictionary) -> void:
	match str(data.get("type","")):
		"joined":own_id=int(data.id);if_valid_status("Joined lobby • waiting for host")
		"error":if_valid_status(str(data.message))
		"result":
			active=false;game.paused=true;game.touch.reset();game.clear_menu("ONLINE VICTORY" if int(data.winner)==own_id else "ONLINE MATCH ENDED")
			game.item("REMATCH • Host only",func():send({"type":"start"}))
			game.item("MAIN MENU",func():disconnect_server();game.combat.stop_match();game.show_menu())
		"state":
			lobby_players=data.players.size();host_id=int(data.host)
			if bool(data.running) and not active and not bool(data.finished):
				for remote in remotes.values():
					game.combat.actors.erase(remote);remote.queue_free()
				remotes.clear()
				game.combat.stop_match();game.combat.active=true;game.playing=true;game.paused=false;game.menu.hide();game.player.reset_motion();game.marker.hide();active=true
			if not active:if_valid_status("LOBBY • "+str(data.players.size())+" / 4 • Host: START");return
			var seen: Dictionary={}
			for state in data.players:
				var id:=int(state.id);var pos:=Vector3(float(state.pos[0]),float(state.pos[1]),float(state.pos[2]));seen[id]=true
				if id==own_id:
					var p: CharacterBody3D=game.player
					p.position=pos if p.position.distance_to(pos)>2 else p.position.lerp(pos,.3)
					p.health=float(state.hp);game.combat.ammo=int(state.ammo);game.combat.reserve=int(state.reserve);game.combat.reload_left=float(state.reload)
					if last_shots>=0 and int(state.shots)>last_shots:game.combat.shot_audio.play();p.kick_weapon()
					last_shots=int(state.shots)
				else:
					if not remotes.has(id):
						var actor: CharacterBody3D=game.combat.spawn_actor(1,pos);actor.set_physics_process(false);remotes[id]=actor
					var actor: CharacterBody3D=remotes[id]
					var moved:=actor.position.distance_to(pos)>.05;actor.position=pos;actor.visual.rotation.y=float(state.yaw);actor.health=float(state.hp);actor.visible=actor.health>0
					actor.collision_layer=0;actor.collision_mask=0
					var clip: String="prone" if state.stance=="prone" else ("crouch" if state.stance=="crouch" else ("armed_walk" if moved else "aim"))
					if actor.animator.current_animation!=clip:actor.animator.play(clip,.1)
					actor.animator.advance(.1)
			for id in remotes.keys():
				if not seen.has(id):game.combat.actors.erase(remotes[id]);remotes[id].queue_free();remotes.erase(id)
			game.combat.label.text="ONLINE • "+str(data.players.size())+" PLAYERS\n"+str(game.combat.ammo)+" / "+str(game.combat.reserve)+"\nZONE "+str(int(data.radius))+"m"
			game.objective.text="ONLINE • Authoritative custom server"
