extends SceneTree
func _initialize() -> void:run.call_deferred()
func run() -> void:
 var game=load("res://main.tscn").instantiate();root.add_child(game)
 game.start_mission(0)
 for i in 50:await physics_frame
 var p: CharacterBody3D=game.player
 var touch: Control=game.touch
 assert(not touch.can_look(Vector2(1200,600)))
 assert(touch.can_look(Vector2(1100,410)),"Fire drag must permit aim")
 touch.show()
 var press:=InputEventScreenTouch.new();press.index=7;press.position=Vector2(130,580);press.pressed=true;touch._input(press)
 var drag:=InputEventScreenDrag.new();drag.index=7;drag.position=Vector2(133,581);touch._input(drag)
 assert(touch.move_axis==Vector2.ZERO,"Joystick deadzone")
 drag.position=Vector2(130,515);touch._input(drag);assert(touch.move_axis.y<-.99)
 touch.reset();assert(touch.move_id==-1 and touch.move_axis==Vector2.ZERO)
 var y: float=p.yaw
 p.add_look(Vector2(40,0));assert(p.yaw==y)
 for i in 20:await physics_frame
 assert(p.yaw<y and p.look_pending.length()<.001,"Smoothed input converges")
 p.look_pending=Vector2.ZERO;p.sensitivity=1;p.ads_sensitivity=.3
 p.add_look(Vector2(20,0));var normal: float=p.look_pending.length();p.look_pending=Vector2.ZERO
 game.combat.aim=true;p.add_look(Vector2(20,0));assert(p.look_pending.length()<normal*.4)
 game.combat.aim=false;p.look_pending=Vector2.ZERO
 p.toggle_prone()
 for i in 12:await physics_frame
 p.skeleton.force_update_all_bone_transforms()
 var head: Vector3=p.skeleton.get_bone_global_pose(p.skeleton.find_bone("head")).origin
 assert(head.y>.1 and head.y<.8,"Prone head must remain above ground")
 assert(p.prone and p.body_collision.shape.height<.7 and p.animation_state=="prone")
 game.touch.move_axis=Vector2(0,-1)
 for i in 10:await physics_frame
 assert(p.animation_state=="crawl" and Vector2(p.velocity.x,p.velocity.z).length()<1)
 game.touch.reset();p.toggle_crouch()
 for i in 10:await physics_frame
 assert(not p.prone and p.crouched and p.animation_state=="crouch")
 p.crouched=false;game.combat.start_match()
 var allies:=0;var enemies:=0
 for actor in game.combat.actors:
  if actor.team==0:allies+=1
  if actor.team==1:enemies+=1
  assert(actor.animator.has_animation("armed_walk"))
 touch.show()
 press.index=1;press.position=Vector2(130,580);press.pressed=true;touch._input(press)
 press.index=2;press.position=Vector2(1100,410);touch._input(press)
 assert(touch.move_id==1 and touch.look_id==2 and game.combat.fire_held,"Independent move/fire fingers")
 drag.index=2;drag.relative=Vector2(20,0);touch._input(drag)
 assert(p.look_pending.length()>0,"Drag while firing changes aim")
 press.index=2;press.pressed=false;touch._input(press)
 assert(not game.combat.fire_held and touch.move_id==1)
 touch.reset()
 assert(allies+1==enemies and enemies==10,"Balanced fictional teams")
 game.touch.move_axis=Vector2(0,-1)
 for i in 30:await physics_frame
 assert(p.animation_state=="armed_walk")
 assert(p.weapon.find_child("Muzzle",true,false)!=null)
 game.paused=true;var clock: float=game.combat.clock
 for i in 5:await physics_frame
 assert(clock==game.combat.clock)
 game.queue_free()
 for i in 5:await process_frame
 print("CONTROLS PASS: joystick deadzone, drag fire, reserved actions, smoothed look, independent ADS sensitivity, prone/crawl/crouch collision and animations, 10v10 sides, animated soldiers, weapon muzzle and pause")
 quit()
