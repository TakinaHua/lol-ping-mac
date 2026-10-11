# Desktop Ping Wheel — macOS prototype

A native Swift/AppKit menu bar app inspired by directional game pings. It runs independently of League of Legends: no process access, injection, game files, network requests, or messages to other players. All symbols, animation, and synthesized sounds are original; no Riot assets are bundled.

## Build and run

Requires macOS 12 or later and Apple's Xcode Command Line Tools (Swift 5.10 or later recommended). In Terminal, from this directory:

```sh
# Only if developer tools are not installed:
xcode-select --install

./scripts/build.sh
open "build/Desktop Ping Wheel.app"
```

The ◎ icon appears in the menu bar; there is no Dock icon. Quit from that menu. The build script compiles for the current Mac's architecture and applies a local ad-hoc signature. The included build is for Apple Silicon. Rebuild on an Intel Mac for Intel support. This prototype is not Developer ID signed or notarized. If a downloaded build is blocked, build locally from the source; do not disable Gatekeeper globally.

## Use

1. Position the pointer where you want the ping to appear.
2. Hold **Control–Option–Space**.
3. Move at least 30 screen points toward a wheel label.
4. Release **Space** to emit that ping at the starting pointer location, then release the modifiers.
5. To cancel, return within 30 points of your starting location before releasing. Holding for 12 seconds also cancels.

Eight directions, counterclockwise from the right: On My Way, Assist, Danger, Missing, Vision, Retreat, Push, Hold. Near an edge the wheel shifts inward to stay readable, but selection still uses movement relative to your original pointer location. You do not need to move onto a visible button.

While disabled, the app still reserves its shortcut; quit to release it completely.

The menu provides four shortcut presets, sound on/off, an enable switch, a delayed demo, and usage help. Shortcut and sound choices persist in UserDefaults under `local.prototype.desktop-ping-wheel`. Letter shortcuts use physical US keyboard positions. A registration conflict produces an alert and preserves the previous working shortcut.

The overlay never takes keyboard focus and passes mouse clicks through to the app underneath. Clicking while the wheel is open therefore operates that other app. No click is required for this prototype. Pings last about 1.15 seconds. One wheel or effect is shown at a time; starting another replaces it.

## macOS permissions and troubleshooting

This implementation uses Carbon's registered global hotkey press/release events plus AppKit's pointer position. It does **not** install a global keyboard/mouse event tap or capture the screen, so Accessibility, Input Monitoring, and Screen Recording access are not required. There is no permission request or instruction to grant broad access to Terminal.

If the shortcut fails, try another preset and check System Settings → Keyboard → Keyboard Shortcuts for a conflict. Security-sensitive input contexts and system surfaces may prevent global shortcuts or overlays; test in a normal desktop app first. Check the menu's Enabled state and use “Try a ping in 1 second” to test drawing independently of the shortcut. Check Sound and the Mac's output volume if silent. Only run one copy at a time, since a second copy can conflict with the first copy's shortcut.

Panels are created for each connected screen and rebuilt after display changes. They are configured to join Spaces and participate as auxiliary windows in full-screen Spaces. Full-screen apps, Stage Manager, Mission Control, lock screens, protected system UI, and unusual display layouts require manual testing; visibility on every system surface is not guaranteed.

## Tests

```sh
./scripts/test.sh
# Run in a logged-in graphical desktop session, with the normal app quit:
PING_PREVIEW_PATH="$PWD/build/preview.png" \
  "build/Desktop Ping Wheel.app/Contents/MacOS/PingWheel" --smoke-test
```

The first command checks dead-zone behavior, all eight directional sectors including near-boundary points, negative-coordinate screen placement, and WAV decoding/duration. The smoke test registers the default hotkey, renders a PNG, creates and displays overlay panels, requests sound playback, and exits. It does not simulate a real global key press, verify audibility, or establish end-to-end interaction correctness.

Manual acceptance checklist:

- In Finder and a text editor, hold the shortcut and try each direction; release the main key first.
- Return to the origin and release; confirm no ping or sound.
- Keep another app focused; confirm the wheel does not steal focus and clicks reach it.
- Switch each shortcut, relaunch, and verify the saved choice; test a shortcut conflict.
- Mute, disable, re-enable, and quit from the menu.
- Test display corners, a secondary display placed left/below the primary, display unplugging, Spaces, and full-screen apps.
- Test sleep or session switching while holding a wheel and the 12-second cancellation.

See `TEST_RESULTS.md` for checks performed on the development machine.

## Source layout

- `Sources/Model.swift`: ping definitions and selection geometry.
- `Sources/HotKey.swift`: registered global shortcut, press/release handling, conflict reporting.
- `Sources/Overlay.swift`: transparent nonactivating panels, wheel drawing, animation, pointer polling while active.
- `Sources/Sound.swift`: generated PCM WAV tones and playback.
- `Sources/main.swift`: menu, saved settings, lifecycle, smoke test.
- `Tests/main.swift`: geometry and audio checks.

There are no external package dependencies. The timer runs only while a wheel/effect is visible. Carbon is used only for its macOS global hotkey API; drawing and app lifecycle use AppKit. This is a prototype with fixed shortcut presets, not an arbitrary shortcut recorder or an Option-click implementation.

Apple references: [ignoresMouseEvents](https://developer.apple.com/documentation/appkit/nswindow/ignoresmouseevents), [NSEvent.mouseLocation](https://developer.apple.com/documentation/appkit/nsevent/mouselocation), [full-screen auxiliary windows](https://developer.apple.com/library/archive/documentation/General/Conceptual/MOSXAppProgrammingGuide/FullScreenApp/FullScreenApp.html).
