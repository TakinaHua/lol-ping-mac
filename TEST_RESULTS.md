# Prototype verification

Tested October 11, 2026 on macOS 14.6.1 (23G93), Apple Silicon, Swift 5.10.

- Native optimized app build: passed. Explicit macOS 12 deployment target; macOS 12 itself and Intel have not been tested.
- Geometry/audio suite: 46 assertions passed. Covers center cancellation, dead-zone threshold, non-finite input, all eight sectors with three angles each, negative-coordinate screen clamping, and decoding all eight generated WAV files with expected duration.
- Desktop smoke test: passed (exit 0). Registered Control–Option–Space, rendered the wheel/effect preview, created and showed panels, requested sound playback, and completed the overlay lifecycle before exiting.
- Visual inspection: preview shows all eight labels, selected Danger state, center release label, and expanding ping rings.
- Bundle property list validation and local code-signature verification: passed.

The initial GUI launch in the restricted execution sandbox exited with status 134. Re-running the same smoke test with approved desktop-session access passed.

Not established by automated checks: real keyboard press/release delivery, audible output, click-through under physical input, shortcut conflicts with particular apps, settings persistence across interactive runs, multi-monitor hardware behavior, screen changes, Spaces, full-screen apps, Stage Manager, sleep recovery, or older/newer macOS versions. The README includes a manual checklist. The PNG is an offscreen render, not a screenshot proving cross-app overlay behavior.
