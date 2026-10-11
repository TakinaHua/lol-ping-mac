import Foundation

// Counterclockwise from east, in AppKit's bottom-left coordinate system.
enum Ping: Int, CaseIterable {
    case onMyWay, assist, danger, missing, vision, retreat, push, hold
    var label: String { ["ON MY WAY", "ASSIST", "DANGER", "MISSING", "VISION", "RETREAT", "PUSH", "HOLD"][rawValue] }
    var glyph: String { ["➜", "+", "!", "?", "◎", "«", "↑", "Ⅱ"][rawValue] }
    var frequency: Double { [660, 784, 440, 880, 1047, 392, 587, 523][rawValue] }
}

struct Selection {
    static let deadZone: CGFloat = 30
    static func ping(dx: CGFloat, dy: CGFloat) -> Ping? {
        guard dx.isFinite, dy.isFinite, hypot(dx, dy) >= deadZone else { return nil }
        let angle = atan2(dy, dx)
        let sector = Int(floor((angle + .pi / 8 + 2 * .pi) / (.pi / 4))) % 8
        return Ping(rawValue: sector)
    }
    static func wheelCenter(_ point: CGPoint, in rect: CGRect) -> CGPoint {
        let margin: CGFloat = 155
        return CGPoint(x: min(max(point.x, rect.minX + margin), max(rect.minX + margin, rect.maxX - margin)),
                       y: min(max(point.y, rect.minY + margin), max(rect.minY + margin, rect.maxY - margin)))
    }
}
