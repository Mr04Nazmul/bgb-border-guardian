# v0.9.0 validation

Implemented and tested in this work session:

| Area | Result |
|---|---|
| Backpack capacity, partial pickup, drop and resource caps | PASS |
| Scope FOV, extended magazine/reload, grip modifier | PASS |
| Helmet, bandage, energy and healing cancellation | PASS |
| Frag fuse/count and physics blast/cover occlusion | PASS |
| Smoke sight blocking, pause and cleanup | PASS |
| Deployable cover collision, durability and cleanup | PASS |
| 5×4 offline squads, friend protection, knock and revive | PASS |
| Damage interruption, squad wipe, spectator, victory/restart | PASS |
| Existing action combinations, auto aim, combat and rig rules | PASS |
| Offline BR rules and autonomous bot simulation | PASS |
| Real two-client WebSocket authority: lobby, movement, health, ammo, reload, damage, winner and rematch | PASS |
| Two actual full game clients: join, replicated opponent, movement | PASS |
| Mission smoke/physics regression | PASS |
| Godot Web export, gzip/integrity/WASM loader | PASS |

Network tests ran against real standalone local Godot server processes, not mocked transports. They were stopped by the test wrapper. No continuous game server is running on behalf of the user.

Unverified or unfinished: physical iPhone input feel/FPS; public network latency/load; Android v0.9 APK/AAB; Docker build; persistent WSS hosting; accounts/authentication; matchmaking/rank; online squad inventory/vehicles; store/events/social/voice; large player-count networking. The browser publication remains owner-private and its audience has not changed.

The online menu is a custom-server prototype and requires a supplied WSS endpoint. It is not a deployed Free Fire-equivalent online service. See `network/README.md` and the main README for limitations.
