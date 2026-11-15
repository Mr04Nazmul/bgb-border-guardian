extends SceneTree
var sockets: Array[WebSocketPeer]=[]
var ids: Array[int]=[]
var latest: Dictionary={}
var result: Dictionary={}
func _initialize() -> void:
 Engine.max_fps=60;run.call_deferred()
func poll() -> void:
 for i in sockets.size():
  var socket:=sockets[i];socket.poll()
  while socket.get_available_packet_count()>0:
   var data=JSON.parse_string(socket.get_packet().get_string_from_utf8())
   if data.type=="joined":ids[i]=int(data.id)
   elif data.type=="state":latest=data
   elif data.type=="result":result=data
func wait_for(condition: Callable,seconds: float=5) -> void:
 var deadline:=Time.get_ticks_msec()+int(seconds*1000)
 while not condition.call() and Time.get_ticks_msec()<deadline:
  poll();await process_frame
 assert(condition.call(),"Network condition timed out")
func frames(n: int) -> void:
 for i in n:poll();await process_frame
func send(index: int,data: Dictionary) -> void:sockets[index].send_text(JSON.stringify(data))
func player(id: int) -> Dictionary:
 for p in latest.get("players",[]):
  if int(p.id)==id:return p
 return {}
func command(sequence: int,fire: bool=false,yaw: float=0,pitch: float=0) -> Dictionary:
 return {"type":"input","seq":sequence,"x":0,"z":0,"yaw":yaw,"pitch":pitch,"fire":fire,"stance":"stand"}
func run() -> void:
 var a:=WebSocketPeer.new();sockets.append(a);ids.append(-1);assert(a.connect_to_url("ws://127.0.0.1:9081")==OK)
 await wait_for(func():return a.get_ready_state()==WebSocketPeer.STATE_OPEN)
 send(0,{"type":"join","name":"A"});await wait_for(func():return ids[0]>0)
 send(0,{"type":"start"});await frames(10);assert(not latest.running,"Cannot start alone")
 var b:=WebSocketPeer.new();sockets.append(b);ids.append(-1);assert(b.connect_to_url("ws://127.0.0.1:9081")==OK)
 await wait_for(func():return b.get_ready_state()==WebSocketPeer.STATE_OPEN)
 send(1,{"type":"join","name":"B"});await wait_for(func():return ids[1]>0 and latest.players.size()==2)
 send(0,{"type":"start"});await wait_for(func():return latest.running)
 await frames(45)
 var initial: Vector3=Vector3(player(ids[0]).pos[0],player(ids[0]).pos[1],player(ids[0]).pos[2])
 var move:=command(1);move.x=99999;move.health=99999;move.pos=[99999,99999,99999];send(0,move)
 await frames(12)
 var current: Vector3=Vector3(player(ids[0]).pos[0],player(ids[0]).pos[1],player(ids[0]).pos[2])
 assert(current.distance_to(initial)<1.5 and float(player(ids[0]).hp)==100,"Server owns movement/health")
 send(0,command(2));send(0,{"type":"damage","target":ids[1],"amount":9999});await frames(10)
 assert(float(player(ids[1]).hp)==100,"Forged damage ignored")
 var pa: Dictionary=player(ids[0]);var pb: Dictionary=player(ids[1])
 var delta:=Vector3(pb.pos[0]-pa.pos[0],-0.2,pb.pos[2]-pa.pos[2])
 var yaw:=atan2(-delta.x,-delta.z);var pitch:=atan2(delta.y,Vector2(delta.x,delta.z).length())
 send(0,command(3,true,yaw,pitch));await frames(5);send(0,command(4))
 await wait_for(func():return int(player(ids[0]).ammo)<24)
 var reload_cmd:=command(5);reload_cmd.reload=true;send(0,reload_cmd)
 await wait_for(func():return float(player(ids[0]).reload)>0)
 var ammo: int=int(player(ids[0]).ammo)
 await frames(10);assert(int(player(ids[0]).ammo)==ammo,"Server reload timing")
 await wait_for(func():return int(player(ids[0]).ammo)==24,4)
 var sequence:=6
 for i in 90:
  if i%6==0:
   pa=player(ids[0]);pb=player(ids[1]);delta=Vector3(pb.pos[0]-pa.pos[0],-.2,pb.pos[2]-pa.pos[2]);yaw=atan2(-delta.x,-delta.z);pitch=atan2(delta.y,Vector2(delta.x,delta.z).length())
   send(0,command(sequence,true,yaw,pitch));sequence+=1
  await frames(1)
  if not result.is_empty():break
 assert(not result.is_empty() and int(result.winner)==ids[0],"Authoritative fire eliminates opponent and ends match")
 await wait_for(func():return latest.finished)
 send(0,{"type":"start"});await wait_for(func():return latest.running and not latest.finished)
 assert(float(player(ids[0]).hp)==100 and int(player(ids[0]).ammo)==24,"Host rematch resets authoritative state")
 for socket in sockets:socket.close()
 await frames(3)
 print("NETWORK PASS: two real WebSocket clients, join/host lobby, minimum population, authoritative movement/health, ignored forged damage, server ammo/reload timing, physics ray damage and winner")
 quit()
