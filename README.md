# BuenaPostura

> Version 0.1.0 · macOS 14 or later · Apple Silicon

BuenaPostura is an open source macOS menu bar posture reminder that uses AirPods headphone motion data locally through Core Motion.

The public home is planned for `buenapostura.app`. This is a clean-room implementation: no camera, no cloud, no account, and no proprietary assets.

## Features

- Menu bar app for macOS 14 or later.
- AirPods / Beats headphone motion via `CMHeadphoneMotionManager`.
- Two-step calibration: save good posture, then save bad posture.
- Local posture score based on head attitude drift.
- Smoothed scoring to avoid reacting to quick head movements.
- Configurable sensitivity, alert delay, cooldown, and looking-down tolerance.
- Local macOS notifications.
- MIT licensed.

## Requirements

- Apple Silicon Mac.
- macOS 14 Sonoma or later.
- AirPods or Beats model that supports head-tracked spatial audio.
- Xcode command line tools.

Apple introduced `CMHeadphoneMotionManager` support on macOS 14. See Apple's Core Motion documentation and WWDC23 "What's new in Core Motion" for the underlying API.

## Run

```sh
swift run BuenaPostura
```

The app appears in the macOS menu bar. Wear compatible AirPods, open the popover, save a good posture sample, save a slouched sample, then keep monitoring on.

## Build the app bundle

```sh
script/build_app.sh
open BuenaPostura.dmg
```

The script creates a single `BuenaPostura.dmg` file containing the release app and an Applications shortcut. The app bundle includes the motion usage description required by macOS and enables local notifications.

## Build

```sh
swift build
swift run BuenaPosturaCoreSmokeTests
```

## Roadmap

- Add signing and notarization.
- Add saved posture profiles for different desks.
- Add custom alert sounds.
- Add launch-at-login support.
- Improve scoring with rolling windows and per-axis weights.
- Add localization.

## Privacy

All posture analysis is local. BuenaPostura does not create accounts, collect analytics, use the camera, or send motion data over the network.
