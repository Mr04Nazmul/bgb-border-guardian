extends SceneTree
func _initialize() -> void:run.call_deferred()
func frames(count: int) -> void:
 for i in count:await physics_frame
func run() -> void:
 var game=load("res://main.tscn").instantiate();root.add_child(game);game.combat.start_match()
 var arena: Node3D=game.combat
 var p: CharacterBody3D=game.player
 var assist: RefCounted=arena.assist
 var enemy: CharacterBody3D=null;var ally: CharacterBody3D=null;var civilian: CharacterBody3D=null
 for actor in arena.actors:
  actor.set_physics_process(false);actor.hide();actor.position=Vector3(180,1,180)
  if actor.team==1:enemy=actor
  if actor.team==0:ally=actor
  if actor.team==2:civilian=actor
 p.position=Vector3(0,1,8);p.yaw=0;p.pitch=0
 enemy.position=Vector3(1.6,0,-12);enemy.show()
 ally.position=Vector3(-3,0,-12);ally.show()
 civilian.position=Vector3(4,0,-12);civilian.show()
 await frames(50)
 assert(not assist.hostile(ally) and not assist.hostile(civilian))
 assert(assist.acquire()==enemy,"Visible hostile near reticle")
 var before: float=assist.angle_to(enemy)
 arena.aim=true;p.manual_look_left=0
 await frames(25)
 assert(assist.target==enemy and assist.angle_to(enemy)<before*.3,"Smooth auto-aim converges")
 var yaw: float=p.yaw;p.manual_look_left=1;assist.tick(.016)
 assert(p.yaw==yaw,"Manual drag overrides assistance")
 p.manual_look_left=0
 assist.enabled=false;assist.tick(.016);assert(assist.target==null)
 assist.enabled=true
 var wall: MeshInstance3D=game.box(Vector3(0,1,-2),Vector3(8,3,1),Color.GRAY)
 await frames(4)
 assert(assist.acquire()==null and assist.target==null,"No locking through walls")
 wall.queue_free();await frames(4)
 enemy.health=0;assert(assist.acquire()==null,"No dead targets")
 enemy.health=100;enemy.position=Vector3(0,0,35);await frames(3)
 assert(assist.acquire()==null,"No target behind camera")
 enemy.position=Vector3(0,0,-100);await frames(3)
 assert(assist.acquire()==null,"No long-range lock")
 arena.aim=false
 # Input buffering: two rapid stance taps are preserved, then explicit stand.
 p.toggle_crouch();p.toggle_crouch();await frames(25)
 assert(not p.crouched and not p.prone and p.requested_stance.is_empty(),"Buffered second crouch tap")
 p.toggle_prone();await frames(20);assert(p.prone)
 p.stand_up();await frames(20);assert(not p.prone and not p.crouched)
 # BR starts unarmed; assistance must not lock until a weapon is acquired.
 arena.br.start()
 for actor in arena.actors:
  actor.set_physics_process(false);actor.hide();actor.position=Vector3(180,1,180)
  if actor.team>=100:enemy=actor
 p.position=Vector3(0,1,8);p.yaw=0;p.pitch=0
 enemy.position=Vector3(1,0,-12);enemy.show()
 arena.aim=true;await frames(20);assert(assist.target==null)
 arena.br.inventory.append("rifle");await frames(20)
 assert(assist.target==enemy,"BR opponent acquisition after arming")
 game.paused=true;yaw=p.yaw;assist.tick(.1);assert(p.yaw==yaw and assist.target==null)
 assist.enabled=false;game.save_controls();assist.enabled=true;game.load_controls()
 assert(not assist.enabled,"Auto-aim preference persists")
 assist.enabled=true;game.save_controls()
 game.queue_free();await frames(5)
 print("AIM ASSIST PASS: visible enemy acquisition, convergence, manual priority, toggle off, wall/friendly/civilian/dead/behind/range rejection, buffered crouch taps, explicit standing, unarmed BR and pause")
 quit()
