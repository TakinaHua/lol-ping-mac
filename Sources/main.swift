import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let hotKey = HotKey()
    private let overlay = OverlayController()
    private let sounds = SoundBank()
    private var item: NSStatusItem!
    private var shortcutIndex = 0
    private var shortcutItems: [NSMenuItem] = []
    private var muted = UserDefaults.standard.bool(forKey: "muted")
    private var enabled = true

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        overlay.rebuild()
        overlay.onPing = { [weak self] ping in
            guard let self = self, !self.muted else { return }
            self.sounds.play(ping)
        }
        if CommandLine.arguments.contains("--smoke-test") { smokeTest(); return }
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "◎"
        item.button?.toolTip = "Desktop Ping Wheel"
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Desktop Ping Wheel", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Hold shortcut • move • release key", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Return to starting point to cancel", action: nil, keyEquivalent: ""))
        menu.addItem(.separator())
        let shortcutMenu = NSMenu()
        for (index, shortcut) in Shortcut.choices.enumerated() {
            let row = NSMenuItem(title: shortcut.name, action: #selector(changeShortcut(_:)), keyEquivalent: "")
            row.tag = index; row.target = self
            shortcutMenu.addItem(row); shortcutItems.append(row)
        }
        let shortcutRow = NSMenuItem(title: "Shortcut", action: nil, keyEquivalent: "")
        shortcutRow.submenu = shortcutMenu; menu.addItem(shortcutRow)
        add(menu, "Sound", #selector(toggleSound(_:))).state = muted ? .off : .on
        add(menu, "Enabled", #selector(toggleEnabled(_:))).state = .on
        add(menu, "Try a ping in 1 second", #selector(demo))
        add(menu, "How to use…", #selector(help))
        menu.addItem(.separator())
        add(menu, "Quit", #selector(quit), key: "q")
        item.menu = menu
        hotKey.onPress = { [weak self] in
            guard let self = self, self.enabled else { return }
            self.overlay.begin()
        }
        hotKey.onRelease = { [weak self] in self?.overlay.release() }
        shortcutIndex = min(max(0, UserDefaults.standard.integer(forKey: "shortcut")), Shortcut.choices.count-1)
        let status = hotKey.register(Shortcut.choices[shortcutIndex])
        shortcutItems[shortcutIndex].state = status == 0 ? .on : .off
        if status != 0 { showError(status) }
        NotificationCenter.default.addObserver(self, selector: #selector(screensChanged), name: NSApplication.didChangeScreenParametersNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(cancel), name: NSWorkspace.willSleepNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(cancel), name: NSWorkspace.sessionDidResignActiveNotification, object: nil)
    }
    @discardableResult private func add(_ menu: NSMenu, _ title: String, _ action: Selector, key: String = "") -> NSMenuItem {
        let row = NSMenuItem(title: title, action: action, keyEquivalent: key)
        row.target = self; menu.addItem(row); return row
    }
    @objc private func changeShortcut(_ sender: NSMenuItem) {
        if sender.tag == shortcutIndex && sender.state == .on { return }
        overlay.cancel()
        let status = hotKey.register(Shortcut.choices[sender.tag])
        guard status == 0 else { showError(status); return }
        shortcutIndex = sender.tag
        UserDefaults.standard.set(shortcutIndex, forKey: "shortcut")
        shortcutItems.forEach { $0.state = $0.tag == shortcutIndex ? .on : .off }
    }
    private func showError(_ status: Int32) {
        let alert = NSAlert()
        alert.messageText = "Couldn't register the shortcut"
        alert.informativeText = "Another app or macOS may already use it (status \(status)). Choose a different shortcut from the ◎ menu. Any previously registered shortcut stays active."
        NSApp.activate(ignoringOtherApps: true); alert.runModal()
    }
    @objc private func toggleSound(_ sender: NSMenuItem) {
        muted.toggle(); sender.state = muted ? .off : .on
        UserDefaults.standard.set(muted, forKey: "muted")
    }
    @objc private func toggleEnabled(_ sender: NSMenuItem) {
        enabled.toggle(); sender.state = enabled ? .on : .off; overlay.cancel()
    }
    @objc private func demo() {
        DispatchQueue.main.asyncAfter(deadline: .now()+1) { [weak self] in
            guard let self = self, self.enabled else { return }
            self.overlay.display(.danger, at: NSEvent.mouseLocation)
        }
    }
    @objc private func help() {
        let alert = NSAlert()
        alert.messageText = "Desktop Ping Wheel"
        alert.informativeText = "Hold \(Shortcut.choices[shortcutIndex].name), move at least 30 points toward a label, then release the main key to ping at your starting point. Move back to your starting point before releasing to cancel. Near screen edges, the wheel shifts inward; movement still starts at your original pointer position.\n\nNo mouse click is needed. The overlay lets clicks through. Pings are local to this Mac; nothing is sent to League or other users.\n\nNo Accessibility, Input Monitoring, or Screen Recording permission is needed by this implementation. Shortcut choices use physical US key positions. A held wheel cancels after 12 seconds."
        NSApp.activate(ignoringOtherApps: true); alert.runModal()
    }
    @objc private func screensChanged() { overlay.rebuild() }
    @objc private func cancel() { overlay.cancel() }
    @objc private func quit() { NSApp.terminate(nil) }
    func applicationWillTerminate(_ notification: Notification) { overlay.cancel() }

    private func smokeTest() {
        let result = hotKey.register(Shortcut.choices[0])
        guard result == 0 else { fputs("Hotkey registration failed: \(result)\n", stderr); exit(1) }
        let view = OverlayView(frame: NSRect(x: 0, y: 0, width: 680, height: 380))
        view.wheel = CGPoint(x: 185, y: 190); view.selected = .danger
        view.effect = (CGPoint(x: 505, y: 190), .danger, 0); view.now = 0.35
        guard let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { exit(2) }
        view.cacheDisplay(in: view.bounds, to: bitmap)
        guard let png = bitmap.representation(using: .png, properties: [:]) else { exit(3) }
        let path = ProcessInfo.processInfo.environment["PING_PREVIEW_PATH"] ?? "/tmp/ping-wheel-preview.png"
        do { try png.write(to: URL(fileURLWithPath: path)) } catch { fputs("\(error)\n", stderr); exit(4) }
        overlay.begin()
        DispatchQueue.main.asyncAfter(deadline: .now()+0.2) { [self] in
            overlay.cancel()
            overlay.display(.danger, at: NSEvent.mouseLocation)
            DispatchQueue.main.asyncAfter(deadline: .now()+1.4) {
                print("PASS: hotkey registration, AppKit render, overlay lifecycle, audio playback requested. Preview: \(path)")
                NSApp.terminate(nil)
            }
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
