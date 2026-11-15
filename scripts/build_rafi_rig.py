"""Reproducible original stylized full-volume Rafi-inspired rig. Run in Blender."""
import bpy, math, random, os, json
from mathutils import Vector
from pathlib import Path
root=Path(__file__).resolve().parents[1]
out=root/'assets/characters/rafi_rig';out.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
random.seed(44)
# An original seamless camouflage palette inspired by the supplied reference.
size=256
image=bpy.data.images.new('OriginalRafiCamo',width=size,height=size,alpha=False)
colors=[(.19,.25,.15,1),(.38,.35,.22,1),(.45,.30,.20,1),(.13,.17,.12,1)]
patches=[(random.random()*size,random.random()*size,random.uniform(10,34),random.choice(colors)) for _ in range(170)]
pixels=[]
for y in range(size):
 for x in range(size):
  color=colors[0]
  for cx,cy,r,c in patches:
   dx=min(abs(x-cx),size-abs(x-cx));dy=min(abs(y-cy),size-abs(y-cy))
   if dx*dx+dy*dy<(r*(.82+.18*math.sin(x*.23+y*.16)))**2:color=c
  pixels.extend(color)
image.pixels=pixels;image.filepath_raw=str(out/'original_camo.png');image.file_format='PNG';image.save()
def mat(name,color,rough=.7):
 m=bpy.data.materials.new(name);m.diffuse_color=color;m.use_nodes=True
 b=m.node_tree.nodes.get('Principled BSDF');b.inputs['Base Color'].default_value=color;b.inputs['Roughness'].default_value=rough
 return m
camo=mat('Rafi camouflage',colors[0]);node=camo.node_tree.nodes.new('ShaderNodeTexImage');node.image=image;camo.node_tree.links.new(node.outputs['Color'],camo.node_tree.nodes['Principled BSDF'].inputs['Base Color'])
skin=mat('Warm skin',(.58,.36,.21,1));hair=mat('Dark hair',(.035,.043,.038,1));boot=mat('Boot leather',(.052,.059,.049,1));white=mat('Eyes',(.92,.91,.83,1),.35);iris=mat('Brown iris',(.14,.075,.035,1),.25);black=mat('Pupils',(.008,.01,.008,1),.2);belt=mat('Belt',(.11,.105,.075,1));gold=mat('Fictional name badge',(.59,.51,.29,1));gunmetal=mat('Game prop',(.10,.12,.11,1),.45)
objects=[]
def weight(obj,bone):
 group=obj.vertex_groups.new(name=bone);group.add(list(range(len(obj.data.vertices))),1.0,'REPLACE');objects.append(obj);return obj
def ball(name,loc,scale,material,bone,segments=16,rings=10):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=rings,location=loc);obj=bpy.context.object;obj.name=name;obj.scale=scale;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 obj.data.materials.append(material)
 for face in obj.data.polygons:face.use_smooth=True
 return weight(obj,bone)
def cube(name,loc,scale,material,bone,bevel=.025):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);obj=bpy.context.object;obj.name=name;obj.scale=scale;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 if bevel:
  mod=obj.modifiers.new('Rounded edges','BEVEL');mod.width=bevel;mod.segments=2;bpy.ops.object.modifier_apply(modifier=mod.name)
 obj.data.materials.append(material);return weight(obj,bone)
def limb(name,a,b,r1,r2,material,bone):
 mid=(Vector(a)+Vector(b))/2;length=(Vector(b)-Vector(a)).length
 bpy.ops.mesh.primitive_cone_add(vertices=12,radius1=r1,radius2=r2,depth=length,location=mid)
 obj=bpy.context.object;obj.name=name;obj.rotation_euler=(Vector(b)-Vector(a)).to_track_quat('Z','Y').to_euler();bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
 obj.data.materials.append(material)
 for face in obj.data.polygons:face.use_smooth=True
 return weight(obj,bone)
# Blender Z-up / -Y forward; glTF exporter converts to Godot Y-up / -Z forward.
bones=[('root',(0,0,0),(0,0,.18),None),('hips',(0,0,.87),(0,0,1.02),'root'),('chest',(0,0,1.02),(0,0,1.43),'hips'),('neck',(0,0,1.43),(0,0,1.52),'chest'),('head',(0,0,1.52),(0,0,1.85),'neck')]
for suffix,sign in [('L',1),('R',-1)]:
 shoulder=(sign*.27,0,1.39);elbow=(sign*.38,0,1.10);wrist=(sign*.40,-.015,.85)
 hip=(sign*.14,0,.88);knee=(sign*.14,0,.49);ankle=(sign*.14,0,.12)
 bones += [(f'upper_arm.{suffix}',shoulder,elbow,'chest'),(f'forearm.{suffix}',elbow,wrist,f'upper_arm.{suffix}'),(f'hand.{suffix}',wrist,(sign*.40,-.015,.72),f'forearm.{suffix}'),(f'thigh.{suffix}',hip,knee,'hips'),(f'shin.{suffix}',knee,ankle,f'thigh.{suffix}'),(f'foot.{suffix}',ankle,(sign*.14,-.20,.08),f'shin.{suffix}')]
 ball('Thigh '+suffix,(sign*.14,0,.69),(.115,.115,.225),camo,f'thigh.{suffix}')
 ball('Knee '+suffix,knee,(.098,.098,.10),camo,f'shin.{suffix}')
 ball('Shin '+suffix,(sign*.14,0,.31),(.09,.095,.195),camo,f'shin.{suffix}')
 cube('Boot '+suffix,(sign*.14,-.055,.09),(.21,.36,.18),boot,f'foot.{suffix}',.04)
 ball('Shoulder '+suffix,shoulder,(.105,.13,.115),camo,f'upper_arm.{suffix}')
 limb('Sleeve '+suffix,shoulder,(sign*.345,0,1.20),.095,.09,camo,f'upper_arm.{suffix}')
 limb('Upper arm '+suffix,(sign*.335,0,1.22),elbow,.075,.068,skin,f'upper_arm.{suffix}')
 ball('Elbow '+suffix,elbow,(.07,.075,.07),skin,f'forearm.{suffix}')
 limb('Forearm '+suffix,elbow,wrist,.065,.05,skin,f'forearm.{suffix}')
 ball('Palm '+suffix,(sign*.40,-.02,.79),(.055,.04,.075),skin,f'hand.{suffix}')
 for finger in range(4):
  ball('Finger '+suffix+str(finger),(sign*.40+(finger-1.5)*.025,-.025,.735),(.012,.02,.055),skin,f'hand.{suffix}',8,6)
 ball('Thumb '+suffix,(sign*.35,-.03,.79),(.025,.028,.045),skin,f'hand.{suffix}',10,6)
ball('Uniform torso',(0,0,1.16),(.28,.16,.315),camo,'chest')
ball('Pants hips',(0,0,.88),(.245,.15,.12),camo,'hips')
cube('Waist belt',(0,0,.94),(.49,.31,.065),belt,'hips',.015)
cube('Buckle',(0,-.17,.94),(.085,.025,.055),gold,'hips',.009)
for x in [-.13,.13]:cube('Chest pocket',(x,-.15,1.24),(.145,.045,.145),camo,'chest',.01)
cube('Original Rafi name strip',(.12,-.18,1.35),(.13,.025,.035),gold,'chest',.005)
limb('Neck',(0,0,1.40),(0,0,1.54),.075,.075,skin,'neck')
ball('Rafi head',(0,-.005,1.65),(.19,.165,.225),skin,'head',24,16)
for x in [-.19,.19]:ball('Ear',(x,0,1.65),(.037,.035,.065),skin,'head',12,8)
for x in [-.074,.074]:
 ball('Eye white',(x,-.151,1.68),(.060,.031,.063),white,'head',16,12)
 ball('Iris',(x,-.179,1.68),(.031,.012,.039),iris,'head',16,10)
 ball('Pupil',(x,-.188,1.68),(.017,.007,.025),black,'head',12,8)
 ball('Eye glint',(x-.008,-.195,1.695),(.007,.004,.008),white,'head',8,6)
 brow=cube('Eyebrow',(x,-.155,1.758),(.10,.022,.022),hair,'head',.009);brow.rotation_euler.y=(-.08 if x<0 else .08)
ball('Nose',(0,-.18,1.625),(.044,.048,.048),skin,'head',14,10)
ball('Mouth',(0,-.153,1.555),(.057,.012,.014),mat('Lips',(.29,.16,.115,1)),'head',16,8)
ball('Hair cap',(0,.012,1.815),(.201,.168,.12),hair,'head',24,12)
for i in range(8):
 x=-.16+i*.045
 tuft=ball('Hair tuft'+str(i),(x,-.08,1.88+(.025*math.sin(i))),(.04,.095,.075),hair,'head',12,8);tuft.rotation_euler.y=-.35
# Join into one skinned mesh, retaining semantic bone vertex groups.
bpy.ops.object.select_all(action='DESELECT')
for obj in objects:obj.select_set(True)
bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join();mesh=bpy.context.object;mesh.name='RafiSolidBody'
bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
bpy.ops.object.armature_add(enter_editmode=True,location=(0,0,0));rig=bpy.context.object;rig.name='RafiRig';rig.data.edit_bones.remove(rig.data.edit_bones[0])
for name,head,tail,parent in bones:
 bone=rig.data.edit_bones.new(name);bone.head=head;bone.tail=tail
 if parent:bone.parent=rig.data.edit_bones[parent]
bpy.ops.object.mode_set(mode='OBJECT');mod=mesh.modifiers.new('Rafi skeleton','ARMATURE');mod.object=rig;mesh.parent=rig
rig.animation_data_create();scene=bpy.context.scene;scene.render.fps=30
clips=[('idle',60),('walk',30),('run',20),('jump',30),('crouch',40),('aim',30),('reload',45)]
for clip,length in clips:
 action=bpy.data.actions.new(clip);action.use_fake_user=True;rig.animation_data.action=action
 for frame in range(0,length+1,2):
  p=frame/length;wave=math.sin(p*2*math.pi)
  for bone in rig.pose.bones:bone.rotation_mode='XYZ';bone.rotation_euler=(0,0,0);bone.location=(0,0,0)
  rig.pose.bones['chest'].rotation_euler.x=.025*wave
  if clip in ['walk','run']:
   amp=.5 if clip=='walk' else .85
   for side,sign in [('L',1),('R',-1)]:
    v=wave*sign
    rig.pose.bones['thigh.'+side].rotation_euler.x=v*amp
    rig.pose.bones['shin.'+side].rotation_euler.x=max(0,-v)*.9
    rig.pose.bones['upper_arm.'+side].rotation_euler.x=-v*amp*.8
    rig.pose.bones['forearm.'+side].rotation_euler.x=.25
   rig.pose.bones['root'].location.y=abs(wave)*(.025 if clip=='walk' else .045)
  if clip=='jump':
   tuck=math.sin(p*math.pi)
   for side in ['L','R']:
    rig.pose.bones['thigh.'+side].rotation_euler.x=-.55*tuck;rig.pose.bones['shin.'+side].rotation_euler.x=1.0*tuck;rig.pose.bones['upper_arm.'+side].rotation_euler.x=-.55*tuck
  if clip=='crouch':
   rig.pose.bones['root'].location.y=-.28
   rig.pose.bones['chest'].rotation_euler.x=.32
   for side in ['L','R']:rig.pose.bones['thigh.'+side].rotation_euler.x=-.8;rig.pose.bones['shin.'+side].rotation_euler.x=1.25
  if clip in ['aim','reload']:
   rig.pose.bones['upper_arm.R'].rotation_euler.x=-1.15;rig.pose.bones['forearm.R'].rotation_euler.x=.45
   rig.pose.bones['upper_arm.L'].rotation_euler.x=-1.05;rig.pose.bones['forearm.L'].rotation_euler.x=.7
   if clip=='reload':rig.pose.bones['forearm.L'].rotation_euler.x=.7+math.sin(p*math.pi)*.8
  for bone in rig.pose.bones:
   bone.keyframe_insert('rotation_euler',frame=frame,group=bone.name);bone.keyframe_insert('location',frame=frame,group=bone.name)
 for curve in action.fcurves:
  for point in curve.keyframe_points:point.interpolation='LINEAR'
rig.animation_data.action=bpy.data.actions['idle'];scene.frame_set(0)
bpy.ops.object.select_all(action='DESELECT');mesh.select_set(True);rig.select_set(True);bpy.context.view_layer.objects.active=rig
bpy.ops.wm.save_as_mainfile(filepath='/tmp/rafi-rig-source.blend')
bpy.ops.export_scene.gltf(filepath=str(out/'rafi_rig.glb'),export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='ACTIONS',export_force_sampling=True,export_skins=True)
print('RAFI RIG BUILT',len(mesh.data.vertices),'vertices',len(mesh.data.polygons),'polygons',len(bones),'bones',len(clips),'clips')
# QA render only; it is not an in-game screenshot.
rig.animation_data.action=bpy.data.actions['idle'];scene.frame_set(0)
scene.render.engine='CYCLES';scene.cycles.samples=24;scene.cycles.use_denoising=False
scene.world.color=(.2,.2,.2)
def area(name,loc,power,size):
 data=bpy.data.lights.new(name,'AREA');data.energy=power;data.shape='DISK';data.size=size;obj=bpy.data.objects.new(name,data);scene.collection.objects.link(obj);obj.location=loc;obj.rotation_euler=(Vector((0,0,1))-obj.location).to_track_quat('-Z','Y').to_euler()
area('Key',(3,-4,5),450,4);area('Fill',(-3,-2,3),250,3)
data=bpy.data.cameras.new('QA camera');camera=bpy.data.objects.new('QA camera',data);scene.collection.objects.link(camera);camera.location=(2,-4,2.0);camera.rotation_euler=(Vector((0,0,1.05))-camera.location).to_track_quat('-Z','Y').to_euler();data.type='ORTHO';data.ortho_scale=2.25;scene.camera=camera
scene.render.resolution_x=800;scene.render.resolution_y=1000;scene.render.resolution_percentage=100;scene.render.film_transparent=True;scene.render.image_settings.file_format='PNG';scene.render.filepath='/tmp/rafi-rig-qa.png';bpy.ops.render.render(write_still=True)
