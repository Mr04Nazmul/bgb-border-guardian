extends SceneTree
var game: Node3D
func _initialize() -> void:run.call_deferred()
func finger(index: int,point: Vector2,down: bool) -> void:
 var e:=InputEventScreenTouch.new();e.index=index;e.position=point;e.pressed=down;game.touch._input(e)
func action(kind: String,index: int,down: bool=true) -> void:
 for entry in game.touch.actions:
  if entry.button.get_meta("action")==kind:
   finger(index,entry.area.get_center(),down);return
 assert(false,"Missing action "+kind)
func wait_frames(count: int) -> void:
 for i in count:await physics_frame
func run() -> void:
 game=load("res://main.tscn").instantiate();root.add_child(game);game.combat.start_match()
 for actor in game.combat.actors:actor.set_physics_process(false)
 game.player.position=Vector3(0,1,8)
 var p: CharacterBody3D=game.player
 await wait_frames(60)
 # Non-overlapping, independently hittable action regions.
 for a in game.touch.actions:
  for b in game.touch.actions:
   if a!=b:assert(not a.area.intersects(b.area),"Overlapping actions")
 assert(p.is_on_floor())
 var start: Vector3=p.position
 finger(1,Vector2(155,483),true);action("FIRE",2);action("ADS",3)
 await wait_frames(20)
 assert(p.position.distance_to(start)>.3 and game.combat.ammo<24 and game.combat.aim,"Move+ADS+fire")
 action("FIRE_L",4);action("FIRE",2,false)
 assert(game.combat.fire_held,"Releasing one fire finger must preserve the other")
 action("FIRE_L",4,false);assert(not game.combat.fire_held)
 finger(1,Vector2(155,483),false);action("ADS",3,false);action("ADS",3);action("ADS",3,false)
 await wait_frames(20)
 action("CROUCH",5);action("CROUCH",5,false);await wait_frames(20)
 assert(p.crouched and p.body_collision.shape.height<1.2)
 var rounds: int=game.combat.ammo;action("FIRE",2);await wait_frames(15);action("FIRE",2,false)
 assert(game.combat.ammo<rounds,"Crouch fire")
 action("PRONE",6);action("PRONE",6,false);await wait_frames(20)
 assert(p.prone and not p.prone_collision.disabled and p.animation_state=="prone")
 rounds=game.combat.ammo;action("FIRE",2);await wait_frames(15);action("FIRE",2,false)
 assert(game.combat.ammo<rounds,"Prone fire")
 action("RELOAD",7);action("RELOAD",7,false);await wait_frames(5)
 assert(p.animation_state=="prone_reload" and game.combat.reload_left>0)
 await wait_frames(120);assert(game.combat.ammo==24)
 # Physics hits from the prone camera must agree with the reticle.
 var enemy: CharacterBody3D=null
 for actor in game.combat.actors:
  if actor.team==1:enemy=actor;break
 enemy.position=p.position+Vector3(0,0,-12);enemy.health=100
 await wait_frames(3)
 p.camera.look_at(enemy.position+Vector3(0,1.1,0));game.combat.shot_left=0
 var fired: bool=game.combat.fire_player()
 assert(fired and enemy.health==66,"Prone reticle ray must hit the opponent")
 enemy.health=100;p.camera.look_at(enemy.position+Vector3(0,1.64,0));game.combat.shot_left=0
 assert(game.combat.fire_player() and enemy.health==32,"Head hit multiplier")
 action("JUMP",8);action("JUMP",8,false);await wait_frames(15)
 assert(not p.prone and not p.crouched and p.is_on_floor(),"Jump from prone first stands")
 action("JUMP",8);action("JUMP",8,false);await wait_frames(3)
 assert(not p.is_on_floor() and p.animation_state=="jump")
 await wait_frames(70)
 # Backpedal and strafe use distinct clips and remain facing the camera.
 finger(1,Vector2(155,627),true);await wait_frames(12)
 assert(p.animation_state=="walk_back")
 finger(1,Vector2(155,627),false)
 finger(1,Vector2(227,555),true);await wait_frames(12)
 assert(p.animation_state=="strafe_right")
 finger(1,Vector2(227,555),false);await wait_frames(20)
 # Standing must not pass through a low ceiling.
 action("CROUCH",5);action("CROUCH",5,false);await wait_frames(20)
 var ceiling: MeshInstance3D=game.box(p.position+Vector3(0,1.48,0),Vector3(3,.15,3),Color.GRAY)
 await wait_frames(3);action("CROUCH",5);action("CROUCH",5,false);await wait_frames(3)
 assert(p.crouched,"Low ceiling blocks standing")
 ceiling.queue_free();await wait_frames(20)
 action("CROUCH",5);action("CROUCH",5,false);await wait_frames(3);assert(not p.crouched)
 action("FIRE",2);game.toggle_pause();await wait_frames(3)
 assert(not game.combat.fire_held and game.touch.held.is_empty() and not game.touch.visible,"Pause clears every finger")
 game.resume();await wait_frames(3);action("FIRE",2)
 game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT);await wait_frames(4)
 assert(game.paused and game.menu.visible and game.touch.held.is_empty(),"Backgrounding must open a resumable pause menu")
 game.queue_free();await wait_frames(5)
 print("ACTION MATRIX PASS: full multi-finger movement/ADS/dual fire, crouch/prone fire, prone reload, stand/jump transitions, directional gait, low-ceiling clearance and pause cleanup")
 quit()
