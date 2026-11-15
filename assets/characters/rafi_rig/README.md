# Rafi-inspired solid rig

Original stylized full-volume model and original camouflage texture, built from primitives and a deterministic material pattern, with the supplied Rafi character used as a visual reference. Not a pixel-identical or photorealistic reconstruction.

- 5,790 mesh vertices / 6,220 pre-triangulation polygons in Blender.
- One skinned body, 17 bones, seven animation clips.
- GLB uses the glTF Y-up convention. The player rotates it 180° to align the model's front with Godot's -Z forward.
- MIT license under the project root LICENSE.
- Rebuild: `blender -b --python scripts/build_rafi_rig.py`.
- Blender source/QA render are reproducible scratch outputs; the GLB and PNG are the game assets.

Basic animations are hand-authored keyframe loops. No facial rig, finger animation, inverse-kinematics foot planting or animation retargeting is included.
