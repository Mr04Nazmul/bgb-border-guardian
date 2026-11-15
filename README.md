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
