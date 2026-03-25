# CAMS Queue-First Reconnect Acceptance

## Purpose

Manual acceptance checklist for the queue-first / track-level streaming refactor.

This phase assumes the new CAMS contract is authoritative from:

- `docs copy/cams/API_CAMS.md`
- `docs copy/cams/SIGNALR_STOREHUB.md`
- `docs copy/CHANGELOG-FRONTEND.md`

## What Is Already Locked By Automated Tests

- `CamsPlaybackBloc` refreshes `GET /state` after SignalR reconnect.
- `LocationBloc` reloads manager location data after manager-room reconnect.
- `StoreHubService` remains the sync channel and still uses SignalR.
- `StoreHubService` auto re-joins `Space` and `ManagerRoom` groups on `onreconnected`.

## Preconditions

- Manager device and playback device are paired to the same `spaceId`.
- Backend exposes queue-first endpoints:
  - `POST /api/cams/spaces/queue/tracks`
  - `POST /api/cams/spaces/queue/playlist`
  - `GET /api/cams/spaces/{spaceId}/state`
  - `GET /api/cams/spaces/{spaceId}/queue`
  - `PATCH /api/cams/spaces/state/audio`
- Track responses provide `hlsUrl` per track, or legacy `audioUrl` fallback during transition.
- SignalR StoreHub is reachable from both devices.

## Manager Flow

1. Open location list and verify current playback label shows the track name from queue-first state.
2. Open a playlist detail screen and tap `Play`.
3. Confirm app calls queue-native playback, not playlist override flow.
4. Tap a single track and confirm it plays via `queue/tracks` with `PlayNow`.
5. Pause, resume, skip next, skip previous, and skip to a target track.
6. Change volume and mute state from manager.
7. Apply mood override and confirm only mood override still uses override endpoint.

Expected:

- Current playback label follows `currentTrackName` / queue snapshot first.
- Skip identity settles from `SpaceStateSync`, not from optimistic playlist assumptions.
- Volume and mute sync to playback device.

## Playback Device Flow

1. Start playback from manager using `Play All`.
2. Confirm device receives HLS stream and does not auto-build identity from playlist id.
3. Let the current track end naturally.
4. Confirm device reports `TrackEnded` and waits for server-selected next item.
5. Trigger a pending-transcode case where `pendingQueueItemId` is present.

Expected:

- Device stays in preparing state while pending.
- Existing stream is not cleared too early when backend is still preparing next item.
- When queue ends, client respects backend state and does not auto-loop locally.

## Reconnect Matrix

### Manager reconnect

1. Start active playback.
2. Disconnect manager network.
3. Reconnect manager network.
4. Wait for SignalR reconnect.

Expected:

- Location screen reloads space snapshots.
- Playback label remains consistent with queue-first state.
- No forced stop or stale playlist hydration when queue data is already present.

### Playback device reconnect

1. Start active playback.
2. Disconnect playback device network.
3. Reconnect playback device network.
4. Wait for SignalR reconnect and REST refresh.

Expected:

- `StoreHubService` reconnects through SignalR.
- Device re-joins the current `Space`.
- Device refreshes playback state from `GET /state`.
- Seek resumes from server-provided offset instead of restarting from the beginning.

## Final Sign-Off Cases

- `Play All` on playlist
- `Play Track`
- Pause / Resume
- Skip next / Skip previous
- Skip to track
- Pending transcode
- Volume / Mute sync
- Natural track end
- Queue exhausted with `queueEndBehavior = Stop`
- Manager reconnect
- Playback device reconnect

## Remaining Work After This Phase

After this acceptance phase is green, the final phase is removing the remaining legacy fallback paths and trimming old playlist-centric contract usage where queue-first state is already guaranteed.
