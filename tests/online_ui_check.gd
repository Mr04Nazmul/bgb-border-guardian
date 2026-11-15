extends SceneTree
func _initialize() -> void:run.call_deferred()
func run() -> void:
 var role:="b"
 for arg in OS.get_cmdline_user_args():
  if arg=="--host":role="a"
 var game=load("res://main.tscn").instantiate();root.add_child(game);game.online.menu();game.online.connect_server("ws://127.0.0.1:9081")
 var deadline:=Time.get_ticks_msec()+10000
 while not game.online.active and Time.get_ticks_msec()<deadline:
  if game.online.own_id==game.online.host_id and game.online.lobby_players==2:game.online.send({"type":"start"})
  await process_frame
 assert(game.online.active,"Actual game client joined and entered match")
 for i in 40:await physics_frame
 assert(game.online.remotes.size()==1 and game.player.weapon.visible and game.combat.active)
 assert(game.online.own_id>0 and game.player.health>0)
 game.touch.move_axis=Vector2(0,-1)
 for i in 10:await physics_frame
 game.touch.move_axis=Vector2.ZERO
 print("ONLINE UI PASS: ",role," joined active match with replicated opponent and player controls")
 if role=="b":
  for i in 120:await physics_frame
 game.online.disconnect_server();game.queue_free()
 for i in 5:await process_frame
 quit()
