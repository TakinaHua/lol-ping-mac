import AVFoundation

final class SoundBank {
    private var players: [Ping: AVAudioPlayer] = [:]
    init() {
        for ping in Ping.allCases {
            if let player = try? AVAudioPlayer(data: Self.wave(frequency: ping.frequency)) {
                player.prepareToPlay()
                players[ping] = player
            }
        }
    }
    func play(_ ping: Ping) {
        guard let player = players[ping] else { return }
        player.currentTime = 0
        player.volume = 0.45
        player.play()
    }
    static func wave(frequency: Double) -> Data {
        let rate = 22050, count = 6615
        var data = Data()
        func string(_ s: String) { data.append(contentsOf: s.utf8) }
        func u16(_ x: UInt16) { data.append(UInt8(x & 255)); data.append(UInt8(x >> 8)) }
        func u32(_ x: UInt32) { u16(UInt16(x & 65535)); u16(UInt16(x >> 16)) }
        string("RIFF"); u32(UInt32(36 + count * 2)); string("WAVEfmt ")
        u32(16); u16(1); u16(1); u32(UInt32(rate)); u32(UInt32(rate * 2)); u16(2); u16(16)
        string("data"); u32(UInt32(count * 2))
        for i in 0..<count {
            let t = Double(i) / Double(rate)
            let envelope = min(t / 0.012, 1) * pow(max(0, 1 - t / 0.3), 2)
            let tone = sin(2 * .pi * frequency * t) + 0.25 * sin(2 * .pi * frequency * 1.5 * t)
            u16(UInt16(bitPattern: Int16(tone * envelope * 16000)))
        }
        return data
    }
}
