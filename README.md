# BGB – Border Guardian Bangladesh

A genuine Godot 4.7.2 / GDScript 3D game project. Fictional Bangladesh-inspired setting; no affiliation with or endorsement by Border Guard Bangladesh or any government agency.

## Playtest scope — v0.1.0

Playable 400 × 400 metre environment with camp, village, bridge, farmland, trees and river hazard. Original procedural prototype meshes; these are **not finished realistic assets**.

- Third-person player, optional first-person view, walk/run/jump/crouch, procedural leg animation, health and stamina.
- Multi-touch movement joystick, swipe camera, jump, run, crouch, interact and view controls.
- Patrol jeep with acceleration/braking/steering, sliding collision, vehicle camera and entry/exit. Arcade CharacterBody3D handling, not a complete suspension simulator.
- Four sequential playable missions: Basic Training, Training Ground, First Border Patrol, Jeep Driving. Talk and jump gates, marker routes, ten-minute timeout, river damage, retry and rewards.
- All 12 mission names appear in selection; missions 5–12 explicitly remain unavailable pending real rescue/inspection/repair mechanics. They are not claimed as completed missions.
- Bengali/English menus and instructions, minimap, pause, local save/continue, three quality settings, outfit color, moving sunlight and rain-colored atmosphere.
- No internet permission in Android; no login, telemetry, advertisements or paid services.

## Controls

Mobile: lower-left joystick; drag middle-right to look; E to talk or enter/exit jeep; arrow to jump; RUN held to sprint; C crouches; VIEW changes camera. In jeep, joystick forward/reverse and left/right controls driving; releasing joystick brakes.

Desktop: WASD, Shift, Space, C, E, V, Escape; hold right mouse and drag to look.

## Build and tests

Use official Godot **4.7.2 stable**, matching export templates, JDK 21, Android SDK platform/build tools 36. Android debug export also built locally with build-tools 35.0.1 (Godot selected this available version).

```sh
godot --headless --editor --quit
godot --headless -- --smoke
godot --headless -- --physics-test
godot --headless --export-debug Android build/bgb-border-guardian-debug.apk
godot --headless --export-release Web dist/index.html
python3 scripts/package_web.py
```

GitHub Actions runs tests and produces debug APK and Web artifacts. There is no production publication or release signing in CI. Generated debug keystores are disposable: rebuilding on a fresh runner may require uninstalling a previously installed debug build. Release keystore/AAB pipeline must be added later with owner-managed secrets; never reuse the debug key for Play.

The Web build is the same 3D Godot game, exported single-threaded for Safari compatibility. WebGL2 is required. The engine downloads as approximately 10 MB gzip, with measured download progress, explicit Play, a startup timeout and visible error/retry handling. Packaging verifies exact decompression and SHA-256 integrity. Web saves use localStorage instead of IndexedDB to avoid an initialization dependency in Safari. Browser cache is not a guarantee of offline availability. Android is the offline-first target.

Loader regression tests: `node tests/web_loader.cjs` after Web packaging verifies gzip download/progress/decompression, HTTP and module rejection propagation, engine integrity and WebAssembly compilation. Actual iPhone rendering remains unverified. The previous loading screen could show 100% for the small PCK while the engine download was incomplete and could leave startup rejections hidden. These loader defects are corrected in playtest 0.1.1; the exact on-device stall is not yet independently reproduced.

## Unfinished / not verified

Detailed realistic soldier/animations, terrain elevation, real LOD meshes, audio, rain particles, complete day/night sky, swimming/boat, rescue/inspection/repair/fire systems, missions 5–12, 2 × 2 km map, Android device performance and Play Store AAB/release preparation remain unfinished. Quality menu sets targets, not measured device guarantees.

No claim of 30/60 FPS or universal device support is made. Cloud browser reported WebGL2 unavailable, preventing rendered browser playthrough in this session. Headless tests validate gameplay logic/physics but do not validate visual appearance or device compatibility.

## Licensing

Original source and procedural geometry are MIT-licensed (LICENSE). Noto Sans Bengali is bundled under SIL Open Font License; see assets/FONT-LICENSE.txt. Godot's export runtime includes its own open-source notices. No official insignia or third-party character models are used.

## Sylhet environment update — 0.2.0

Replaces the flat green ground with an original 20,000-triangle 400 m terrain, including tea hills and a lowered river channel. Adds 660 contour-row tea bushes, batched meadow grass and leaf-card trees, distant hill silhouettes, animated water, scanned CC0 PBR ground/grass/brick/tin materials, house verandas/posts/steps, rural utility poles/cables, procedural sky and warm directional lighting. Vegetation is spatially batched in 32 m cells for distance culling. Medium quality enables directional shadows; Low disables them. An initial visual-settings migration selects Medium once; subsequent saved choices are preserved.

This is a substantial environment art pass, **not GTA-level photorealism**. Soldier/NPC/jeep geometry remains prototype quality, terrain is fictional rather than a real-world survey, and actual device FPS and iPhone rendering remain unverified. Texture sources and licenses are in assets/textures/SOURCES.json and LICENSES.md. `tests/terrain_check.gd` checks the terrain collision orientation, player landing and tea-instance count; the original smoke/physics and web-loader tests remain required.

## Offline team-match update — 0.3.0

Adds 8 allied bots, 12 opposing bots, 10 protected ambient villagers and the player. The river divides visibly labeled, fictional west/east zones inspired by Bangladesh/India landscapes. This is a fictional game arena, not an actual security layout or real military engagement.

Choose **Team Match • Offline Bots**. First side to 30 eliminations wins; a five-minute timeout decides by score (ties draw). Player has 100 health, a 24-round magazine, 144 reserve rounds, 1.8-second reload, a 0.16-second fire interval and four-second respawn. Bots respawn after five seconds. Hitscan uses a camera ray and a muzzle obstruction ray; walls block fire, allies take no friendly damage, and civilians cannot be damaged. Hold FIRE, tap AIM/RELOAD, or use mouse fire / R on desktop. Match state is transient; mission saves are preserved. Match pause freezes bots, timers, reload and respawn. Bot navigation is a simple scripted bridge route with collision, not a navigation-mesh or tactical AI system.

Includes team minimap dots, team labels, elimination scoring, tracers and an original synthesized gunshot sound. No blood/gore. Civilian animation, soldiers and weapons are still simple prototype meshes; no online multiplayer, battle-royale circle, loot/inventory, weapon selection or PUBG/Free Fire parity is claimed. Bot-match FPS and actual mobile rendering remain unverified.

Regression test: `godot --headless --script tests/combat_check.gd` verifies population, hit damage, wall occlusion, fire rate, reload, scoring, civilian protection, respawn, pause, victory and repeated-match cleanup. The synthesized shot.wav is original MIT-licensed audio under the project LICENSE.

## Main character Rafi — 0.3.1

The player now uses the exact user-supplied bgb-rafi-v3.glb from bgb-rafi-v3-pack.zip. The original GLB bytes are preserved, with provenance/SHA-256 recorded under assets/characters/rafi. Corrects its Z-up coordinate convention at runtime to stand 1.9 metres high. Camera-relative front/back/side selection avoids rendering all crossed picture planes at once. The supplied appearance is preserved; uniform recoloring and the old block weapon overlay are disabled for this avatar. Existing movement, collision, first/third-person camera, crouch scaling, vehicle and combat logic remain.

This asset is a **2.5D picture-card character**, not a solid rigged 3D model. It has no skeleton or animation clips. Movement only adds slight procedural body bob; it does not provide limb walking, running, aiming or reload animation. All other soldiers/NPCs retain their previous models. `tests/rafi_check.gd` validates the imported asset, upright scale, directional selection, landing, camera visibility and settings/save compatibility. Actual iPhone rendering remains unverified.

## Solid animated Rafi — 0.4.0

Replaces the 2.5D player with an original, full-volume stylized 3D mesh inspired by the supplied Rafi reference: rounded head and facial features, original camouflage shirt/trousers, hands/fingers, boots and hair. It is a newly constructed approximation, not an exact reconstruction of the supplied face/artwork. The original reference asset remains preserved.

The GLB contains one skinned body with 17 joints and seven animation clips: idle, walk, run, jump, crouch, aim and reload. Player controls select the clips with short transitions; manual animation advancement freezes poses when paused. Crouching now shortens the actual capsule and lowers the camera, rather than squashing the character. A game prop follows the hand through a BoneAttachment3D calibrated against the aim pose. First-person hides the full body; driving and respawn retain existing behavior. Basic clips are mutually exclusive, not a layered locomotion/aim blend or motion-captured production animation.

The source generator is scripts/build_rafi_rig.py (Blender 4.3.2); geometry, camouflage and animation are original MIT-licensed work. The exported GLB and required textures are committed. No official insignia were copied. The PNG reference and old picture-card GLB were not altered. Tests check mesh volume, skin binding, 17 joints, actual changing leg-bone poses, all seven clips, gameplay-driven transitions, paused animation, first/third-person visibility and prior settings/save compatibility. Actual iPhone rendering, device FPS, foot planting and final animation polish remain unverified.

## Solo Battle Royale — 0.5.0

Adds a playable offline solo battle-royale mode with **one player and 19 independent opposing bots**. Select Battle Royale in the main menu. Everyone starts unarmed; nearby starting supplies must be looted. Villagers are removed from the active match and restored when leaving it. The existing team match and training missions remain available.

Rules and controls:

- One life per participant; no respawn. Last survivor wins. Eliminated players receive a rank and can start a new match.
- E / existing touch interact button collects nearby loot. Carry up to two weapons; Q / SWAP switches them while preserving loaded magazines. A third type replaces and drops the active weapon with its remaining rounds, preventing free-ammo swap loops.
- Pistol (12 rounds), rifle (24) and a simplified single-hit shotgun (6), shared reserve ammo, reload and existing occlusion-aware hitscan. These are game balance values, not real weapons or a copy of another game's gun simulation.
- H / HEAL channels a medkit for four seconds, restoring up to 50 HP. Movement, firing, swapping, reloading or damage cancels healing. Armor absorbs half incoming weapon damage until depleted; zone damage bypasses armor.
- Seven shrinking phases with wait/shrink timers, a visible blue boundary and current/next safe circles on the minimap. Zone centers shift within an accessible road corridor; the final radius reaches zero and zone damage escalates. No arbitrary score-based winner or respawn is used.
- Bots independently seek weapons/ammo/medical loot, engage other participants, reload, drop carried loot when eliminated and move toward safety. Scripted collision/bridge routing remains basic; it is not a production navigation-mesh AI.
- HUD shows alive count, player kills, weapon/ammo, armor, medkits and zone timing. Enemy minimap positions are hidden in BR. Match pause freezes gameplay and zone/heal timers; restart clears inventory, loot, bots and zone state.

This is an original **offline BR prototype**, not online multiplayer or PUBG/Free Fire parity. No plane/parachute sequence, 100-player networking, squads, grenades, dedicated servers, persistent ranking, anti-cheat or monetization is implemented. The fictional Sylhet-inspired map remains 400 m square. Actual iPhone/Android performance and rendering remain unverified.

Tests: tests/battle_royale_check.gd exercises rules/inventory/zone/elimination/winner/reset behavior. tests/battle_simulation.gd runs an accelerated autonomous match to verify bot looting, shooting and eliminations. Existing team combat, rig, movement and web-loader regression tests remain required.
