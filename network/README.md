# Custom online arena prototype

The published browser game includes **Online • Custom Server**. This connects to an existing `wss://` endpoint; it is not a publicly hosted matchmaking service. No always-on server or paid hosting has been activated.

The genuine Godot headless server supports one room of 2–4 real clients, host-controlled start/rematch, server-controlled movement, world collision, jump/crouch/prone capsule heights, rifle ammunition/reload/cooldown, physics-ray damage, shrinking zone, elimination and winner broadcasts. It loads the same map as the browser game. Clients send inputs, not authoritative positions, health or damage. A 20-second heartbeat timeout removes disconnected clients.

Limits: single room, rifle loadout, no accounts or cross-device progression, no ranked matchmaking, no persistence across server restarts, no online squad revive/inventory/vehicles, no lag compensation, no production security audit or load test. Offline solo/squad modes contain the richer survival mechanics. This is not Free Fire service parity.

## Run a test server

With official Godot 4.7.2 imported project assets:

```sh
godot --headless --editor --quit
godot --headless --script network/arena_server.gd -- --port=9080
```

The native client accepts `ws://127.0.0.1:9080` for local tests. HTTPS browsers require a TLS reverse proxy and `wss://your-domain`. The server does not terminate TLS itself. A persistent TCP/WebSocket-capable host is required; the current static Sites publication cannot execute a long-running Godot process.

A reproducible Docker recipe is included. It pins the downloaded Godot ZIP checksum. Docker build/deployment has not been tested here; the actual standalone Godot server and clients have been tested.

```sh
docker build -f network/Dockerfile -t border-guardian-server .
docker run --rm -p 9080:9080 border-guardian-server
```

## Verification

`GODOT_BIN=godot python3 tests/run_network.py` starts and stops real server processes, exercises two raw WebSocket clients, then two actual game clients. It checks lobby entry, server-owned movement/health/ammunition/damage, reload timing, winner, client scene replication and controls. Logs are in `build/`. No test server remains running afterward.
