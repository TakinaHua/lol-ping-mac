import Foundation
import AVFoundation

var checks = 0
func check(_ condition: @autoclosure () -> Bool, _ message: String) {
    checks += 1
    if !condition() { fputs("FAIL: \(message)\n", stderr); exit(1) }
}
check(Selection.ping(dx: 0, dy: 0) == nil, "center cancels")
check(Selection.ping(dx: 29.99, dy: 0) == nil, "inside dead zone")
check(Selection.ping(dx: 30, dy: 0) == .onMyWay, "dead zone edge selects")
check(Selection.ping(dx: .infinity, dy: 0) == nil, "invalid coordinates")
for ping in Ping.allCases {
    let a = CGFloat(ping.rawValue) * .pi / 4
    for offset in [-0.38, 0.0, 0.38] {
        check(Selection.ping(dx: cos(a+offset)*100, dy: sin(a+offset)*100) == ping, "sector \(ping) offset \(offset)")
    }
    let data = SoundBank.wave(frequency: ping.frequency)
    check(data.count == 13274, "WAV length")
    let player = try AVAudioPlayer(data: data)
    check(abs(player.duration-0.3) < 0.001, "WAV decodes with expected duration")
}
let screen = CGRect(x: -1920, y: -200, width: 1920, height: 1080)
check(Selection.wheelCenter(CGPoint(x: -1919, y: -199), in: screen) == CGPoint(x: -1765, y: -45), "secondary display edge clamp")
check(Selection.wheelCenter(CGPoint(x: -900, y: 400), in: screen) == CGPoint(x: -900, y: 400), "center unchanged")
print("PASS: \(checks) geometry and audio assertions")
