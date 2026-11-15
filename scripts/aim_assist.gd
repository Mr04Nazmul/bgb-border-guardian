extends RefCounted
# Offline controller assistance: visible opponents near the reticle, never through cover.
var arena: Node3D
var target: CharacterBody3D
var enabled:=true
var strength:=0.8
var acquisition_left:=0.0
func hostile(actor: CharacterBody3D) -> bool:
	return is_instance_valid(actor) and actor.visible and actor.health>0 and actor.dead_left<=0 and not actor.eliminated and (actor.team>=100 if arena.royale else actor.team==1)
func aim_point(actor: CharacterBody3D) -> Vector3:
	return actor.global_position+Vector3(0,1.07 if actor.crouched else 1.17,0)
func visible_target(actor: CharacterBody3D) -> bool:
	var p: CharacterBody3D=arena.game.player
	var point:=aim_point(actor)
	var excluded: Array[RID]=[p.get_rid()]
	var camera_hit: Dictionary=arena.ray(p.camera.global_position,point,excluded)
	if not camera_hit.is_empty() and camera_hit.collider!=actor:return false
	var body_hit: Dictionary=arena.ray(p.global_position+Vector3(0,.43 if p.prone else (1.1 if p.crouched else 1.35),0),point,excluded)
	return body_hit.is_empty() or body_hit.collider==actor
func angle_to(actor: CharacterBody3D) -> float:
	var cam: Camera3D=arena.game.player.camera
	var delta:=aim_point(actor)-cam.global_position
	return acos(clampf((-cam.global_basis.z).dot(delta.normalized()),-1,1))
func valid_target(actor: CharacterBody3D,sticky: bool=false) -> bool:
	if not hostile(actor):return false
	var p: CharacterBody3D=arena.game.player
	var distance:=p.global_position.distance_to(actor.global_position)
	if distance>75 or distance<1:return false
	var cone:=deg_to_rad(8.0 if arena.aim else 12.0)*(1.4 if sticky else 1.0)
	return angle_to(actor)<cone and visible_target(actor)
func acquire() -> CharacterBody3D:
	if valid_target(target,true):return target
	var best: CharacterBody3D=null;var score:=INF
	for actor in arena.actors:
		if not valid_target(actor):continue
		var rank: float=angle_to(actor)+arena.game.player.global_position.distance_to(actor.global_position)*.0008
		if rank<score:score=rank;best=actor
	return best
func tick(dt: float) -> void:
	var p: CharacterBody3D=arena.game.player
	if not enabled or not arena.active or arena.game.paused or not arena.game.playing or p.driving or arena.respawn_left>0 or not arena.result.is_empty() or (arena.royale and (not arena.br.player_alive or arena.br.inventory.is_empty())):
		target=null;return
	if not (arena.aim or arena.fire_held or arena.mouse_fire):target=null;return
	acquisition_left-=dt
	if acquisition_left<=0 or not hostile(target):
		target=acquire();acquisition_left=.07
	# Visibility is checked every tick, even while preserving a sticky target.
	if not valid_target(target,true):target=null;return
	if p.manual_look_left>0:return
	var delta: Vector3=aim_point(target)-p.camera.global_position
	var desired_yaw:=atan2(-delta.x,-delta.z)
	var desired_pitch:=atan2(delta.y,Vector2(delta.x,delta.z).length())
	var rate:=deg_to_rad(55.0)*strength*dt
	p.yaw+=clampf(wrapf(desired_yaw-p.yaw,-PI,PI),-rate,rate)
	p.pitch=clampf(move_toward(p.pitch,desired_pitch,rate*.8),-1.15,.65)
