import AppKit

extension Ping {
    var color: NSColor {
        [NSColor.systemCyan, .systemGreen, .systemRed, .systemYellow,
         .systemPurple, .systemOrange, .systemTeal, .systemBlue][rawValue]
    }
}

final class OverlayPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

final class OverlayView: NSView {
    var wheel: CGPoint?
    var selected: Ping?
    var effect: (point: CGPoint, ping: Ping, start: TimeInterval)?
    var now: TimeInterval = 0
    override var isOpaque: Bool { false }

    func circle(_ center: CGPoint, radius: CGFloat, color: NSColor, stroke: Bool = false, width: CGFloat = 2) {
        let path = NSBezierPath(ovalIn: NSRect(x: center.x-radius, y: center.y-radius, width: radius*2, height: radius*2))
        color.set()
        path.lineWidth = width
        if stroke { path.stroke() } else { path.fill() }
    }
    func text(_ value: String, at point: CGPoint, size: CGFloat, color: NSColor) {
        let attributes: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: size, weight: .bold), .foregroundColor: color]
        let dimensions = (value as NSString).size(withAttributes: attributes)
        (value as NSString).draw(at: CGPoint(x: point.x-dimensions.width/2, y: point.y-dimensions.height/2), withAttributes: attributes)
    }
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        if let center = wheel {
            circle(center, radius: 143, color: NSColor(calibratedRed: 0.025, green: 0.055, blue: 0.09, alpha: 0.94))
            circle(center, radius: 142, color: NSColor.systemTeal.withAlphaComponent(0.6), stroke: true)
            for ping in Ping.allCases {
                let angle = CGFloat(ping.rawValue) * .pi / 4
                let point = CGPoint(x: center.x + cos(angle)*100, y: center.y + sin(angle)*100)
                let active = selected == ping
                circle(point, radius: active ? 28 : 23, color: ping.color.withAlphaComponent(active ? 0.9 : 0.12))
                circle(point, radius: active ? 28 : 23, color: ping.color.withAlphaComponent(active ? 1 : 0.4), stroke: true)
                text(ping.glyph, at: point, size: 27, color: active ? .black : ping.color)
                text(ping.label, at: CGPoint(x: point.x, y: point.y-36), size: 9, color: .white)
            }
            circle(center, radius: 31, color: .white.withAlphaComponent(0.06))
            text(selected?.glyph ?? "·", at: CGPoint(x: center.x, y: center.y+4), size: 24, color: selected?.color ?? .white)
            text(selected == nil ? "CANCEL" : "RELEASE", at: CGPoint(x: center.x, y: center.y-17), size: 8, color: .white)
        }
        if let effect = effect {
            let progress = CGFloat(min(1, max(0, (now-effect.start)/1.15)))
            let alpha = 1-progress
            for offset in [CGFloat(0), 0.22] {
                let p = max(0, progress-offset)
                circle(effect.point, radius: 24+p*100, color: effect.ping.color.withAlphaComponent(alpha*0.8), stroke: true, width: 3)
            }
            circle(effect.point, radius: 27, color: NSColor.black.withAlphaComponent(alpha*0.85))
            text(effect.ping.glyph, at: effect.point, size: 34, color: effect.ping.color.withAlphaComponent(alpha))
            text(effect.ping.label, at: CGPoint(x: effect.point.x, y: effect.point.y-45), size: 12, color: .white.withAlphaComponent(alpha))
        }
    }
}

final class OverlayController {
    private var panels: [OverlayPanel] = []
    private var timer: Timer?
    private var anchor: CGPoint?
    private var started: TimeInterval = 0
    private var selected: Ping?
    private var effect: (point: CGPoint, ping: Ping, start: TimeInterval)?
    var onPing: ((Ping) -> Void)?
    var active: Bool { anchor != nil }

    func rebuild() {
        cancel()
        panels.forEach { $0.close() }
        panels = NSScreen.screens.map { screen in
            let panel = OverlayPanel(contentRect: screen.frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
            panel.setFrame(screen.frame, display: false)
            panel.isReleasedWhenClosed = false
            panel.backgroundColor = .clear
            panel.isOpaque = false
            panel.hasShadow = false
            panel.ignoresMouseEvents = true
            panel.hidesOnDeactivate = false
            panel.level = .statusBar
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
            panel.contentView = OverlayView(frame: CGRect(origin: .zero, size: screen.frame.size))
            return panel
        }
    }
    func begin() {
        guard anchor == nil else { return }
        anchor = NSEvent.mouseLocation
        started = ProcessInfo.processInfo.systemUptime
        effect = nil
        selected = nil
        show()
    }
    func release() {
        guard let origin = anchor else { return }
        let mouse = NSEvent.mouseLocation
        let ping = Selection.ping(dx: mouse.x-origin.x, dy: mouse.y-origin.y)
        anchor = nil
        if let ping = ping { display(ping, at: origin) } else { cancel() }
    }
    func display(_ ping: Ping, at point: CGPoint) {
        anchor = nil
        effect = (point, ping, ProcessInfo.processInfo.systemUptime)
        onPing?(ping)
        show()
    }
    func cancel() {
        anchor = nil; effect = nil; selected = nil
        timer?.invalidate(); timer = nil
        panels.forEach { $0.orderOut(nil) }
    }
    private func show() {
        panels.forEach { $0.orderFrontRegardless() }
        if timer == nil {
            let timer = Timer(timeInterval: 1.0/60, repeats: true) { [weak self] _ in self?.tick() }
            RunLoop.main.add(timer, forMode: .common)
            self.timer = timer
        }
        tick()
    }
    private func tick() {
        let now = ProcessInfo.processInfo.systemUptime
        if let origin = anchor {
            // Safety timeout handles interrupted sessions or a missing release event.
            if now-started > 12 { cancel(); return }
            let mouse = NSEvent.mouseLocation
            selected = Selection.ping(dx: mouse.x-origin.x, dy: mouse.y-origin.y)
        } else if let effect = effect, now-effect.start > 1.15 { cancel(); return }
        for panel in panels {
            guard let view = panel.contentView as? OverlayView else { continue }
            let frame = panel.frame
            func local(_ p: CGPoint) -> CGPoint { CGPoint(x: p.x-frame.minX, y: p.y-frame.minY) }
            view.wheel = anchor.flatMap { frame.contains($0) ? local(Selection.wheelCenter($0, in: frame)) : nil }
            view.selected = selected
            view.effect = effect.map { (local($0.point), $0.ping, $0.start) }
            view.now = now
            view.needsDisplay = true
        }
    }
}
