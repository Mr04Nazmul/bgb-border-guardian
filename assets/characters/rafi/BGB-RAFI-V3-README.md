# BGB Rafi V3 — the picture itself as a game character

`bgb-rafi-v3.glb` is built from the actual character-sheet pictures:
the front, back and side views were cut out of the sheet with transparent
backgrounds (`rafi-front.png`, `rafi-side.png`, `rafi-back.png`) and placed
on three crossed planes inside one GLB.

- From the front you see the front picture, from behind the back picture,
  from the side the profile picture — pixel-for-pixel the sheet character.
- Height 1.9 units, alpha mode MASK (cutoff 0.35), double-sided, textures embedded.
- Nodes: `RafiFront`, `RafiBack`, `RafiSide`.
- Godot: drag the .glb into a scene. Three.js: GLTFLoader.load('bgb-rafi-v3.glb').
- The three transparent PNGs are also included — they can be used directly
  as sprites (Sprite3D / billboard) in Godot or Three.js.

Limit: this is a flat picture-card character (2.5D), not a sculpted solid
model. It looks exactly like the picture from front/back/side, which a
hand-built low-poly model cannot.
