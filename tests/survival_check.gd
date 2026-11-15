extends SceneTree
var game: Node3D
var br: Node3D
var ext: Node3D
func _initialize() -> void:run.call_deferred()
func frames(count: int) -> void:
 for i in count:await physics_frame
func clear_loot() -> void:
 for item in br.loot.duplicate():br.consume(item)
func pickup(kind: String,amount: int=1) -> bool:
 clear_loot();br.add_loot(kind,game.player.position,amount);return br.pickup_nearest()
func run() -> void:
 game=load("res://main.tscn").instantiate();root.add_child(game);br=game.combat.br;ext=br.ext;br.start()
 for actor in game.combat.actors:actor.set_physics_process(false)
 ext.auto_pickup=false;game.player.position=Vector3(0,1,8);await frames(50)
 assert(pickup("rifle"));assert(pickup("backpack") and ext.capacity==200)
 for kind in ["scope","extended_mag","grip"]:assert(pickup(kind))
 assert(ext.attached("scope") and game.combat.mag_capacity()==32)
 game.combat.aim=true;game.combat._process(1);assert(game.player.camera.fov<36,"Scope narrows ADS FOV")
 game.combat.aim=false
 game.combat.reserve=20;game.combat.reload_weapon();game.combat._process(2)
 assert(game.combat.ammo==32 and game.combat.reserve==12,"Extended mag reload")
 ext.capacity=ext.weight()+.5
 assert(pickup("ammo",20));assert(game.combat.reserve==17 and br.loot[0].amount==15,"Partial pickup preserves remainder")
 ext.capacity=ext.weight();assert(not pickup("ammo",5) and not br.loot.is_empty(),"Full bag preserves world loot")
 ext.capacity=200;br.medkits=5;assert(not pickup("medkit"));br.medkits=0
 assert(pickup("helmet"));game.player.health=100;br.armor=0;br.damage_player(20,true,true)
 assert(game.player.health==90 and ext.helmet==50,"Helmet absorbs head damage")
 assert(pickup("bandage"));game.player.health=50;ext.start_heal("bandage");br.tick(2)
 assert(game.player.health==65 and ext.bandages==0)
 assert(pickup("energy"));ext.start_heal("energy");br.tick(2);assert(ext.drinks==0 and ext.boost_left>0)
 var hp: float=game.player.health;br.tick(1);assert(game.player.health>hp)
 assert(pickup("grenade"));ext.throw_frag();assert(ext.grenades==0 and ext.projectiles[0].kind=="frag")
 ext.tick_items(2.6);ext.cleanup()
 assert(pickup("smoke"));ext.throw_smoke();assert(ext.projectiles.size()==1 and ext.smoke_charges==0)
 ext.tick_items(2.6);assert(ext.smokes.size()==1)
 var smoke: Dictionary=ext.smokes[0]
 assert(ext.line_smoked(smoke.node.position-Vector3(10,0,0),smoke.node.position+Vector3(10,0,0)))
 var life: float=smoke.life;game.paused=true;ext.tick(1);assert(smoke.life==life);game.paused=false
 assert(pickup("cover"));ext.deploy_cover();assert(ext.covers.size()==1 and ext.cover_charges==0)
 var cover: Dictionary=ext.covers[0];var body: StaticBody3D=null
 for child in cover.node.get_children():
  if child is StaticBody3D:body=child
 ext.hit_cover(body,300);ext.tick_items(.01);assert(ext.covers.is_empty(),"Cover takes damage")
 ext.cleanup();await frames(3)
 var enemy: CharacterBody3D=null
 for actor in game.combat.actors:
  if actor.team>=100:enemy=actor;break
 enemy.position=Vector3(0,0,-4);enemy.health=100;await frames(3)
 ext.explode(enemy.position+Vector3.UP);assert(enemy.health<100,"Grenade blast physics damage")
 enemy.health=100
 var wall: MeshInstance3D=game.box(Vector3(-2,1,-4),Vector3(.2,3,5),Color.GRAY);await frames(3)
 ext.explode(Vector3(-4,1,-4));assert(enemy.health==100,"Walls block blast damage")
 wall.queue_free();await frames(3)
 game.combat.reserve=40;ext.open_bag();ext.drop_ammo();assert(game.combat.reserve==10 and game.paused)
 game.resume();br.start(true);ext.auto_pickup=false
 var allies: Array[CharacterBody3D]=[];var enemies: Array[CharacterBody3D]=[]
 for actor in game.combat.actors:
  actor.set_physics_process(false)
  if actor.team==100:allies.append(actor)
  if actor.team>=101:enemies.append(actor)
 assert(allies.size()==3 and enemies.size()==16 and br.alive_count()==20)
 for actor in game.combat.actors:actor.position=Vector3(180,1,180)
 game.player.position=Vector3(0,1,8);allies[0].position=Vector3(1,0,8);await frames(50)
 allies[0].receive_damage(100,100);assert(allies[0].health==100,"Friendly fire protection")
 allies[0].receive_damage(100,101);assert(allies[0].downed and not allies[0].eliminated)
 assert(ext.begin_revive());allies[0].receive_damage(1,101);assert(ext.revive_target==null,"Damage interrupts revive")
 assert(ext.begin_revive());br.tick(3.1);assert(not allies[0].downed and allies[0].health==35)
 br.damage_player(1000);assert(ext.player_downed and br.player_alive and not game.combat.fire_player())
 assert(ext.bot_revive(allies[0],3.1));assert(not ext.player_downed and game.player.health==35,"Ally revives player")
 var wiped: Array[CharacterBody3D]=[]
 for actor in enemies:
  if actor.team==101:wiped.append(actor);actor.receive_damage(1000,100)
 ext.tick_squad(.1)
 for actor in wiped:assert(actor.eliminated,"No active teammate means squad wipe")
 br.damage_player(1000);ext.player_bleed=.01;ext.tick_squad(.02)
 assert(ext.spectating and not br.player_alive and not game.paused,"Spectate surviving allies after bleedout")
 br.start(true)
 for actor in game.combat.actors.duplicate():
  if actor.team>=101:br.eliminated(actor,100,true)
 assert(game.paused and not game.combat.result.is_empty(),"Squad victory")
 br.start();assert(not ext.squad and game.player.visible and game.player.collision_layer==1 and ext.projectiles.is_empty())
 game.queue_free();await frames(6)
 print("SURVIVAL PASS: bag capacity/partial pickup/drop, attachments/reload, helmet, bandage/energy, smoke/pause, destructible cover, blast/occlusion, squad population/friendly fire, knock/player-bot revive, squad wipe, spectator, victory and restart")
 quit()
