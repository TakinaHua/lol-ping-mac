import AppKit
import Carbon

struct Shortcut {
    let name: String
    let key: UInt32
    let modifiers: UInt32
    static let choices = [
        Shortcut(name: "⌃⌥ Space", key: UInt32(kVK_Space), modifiers: UInt32(controlKey | optionKey)),
        Shortcut(name: "⌃⌥ P", key: UInt32(kVK_ANSI_P), modifiers: UInt32(controlKey | optionKey)),
        Shortcut(name: "⌃⇧ Space", key: UInt32(kVK_Space), modifiers: UInt32(controlKey | shiftKey)),
        Shortcut(name: "⌘⇧ G", key: UInt32(kVK_ANSI_G), modifiers: UInt32(cmdKey | shiftKey))
    ]
}

final class HotKey {
    private var reference: EventHotKeyRef?
    private var handler: EventHandlerRef?
    var onPress: (() -> Void)?
    var onRelease: (() -> Void)?
    private(set) var installationStatus: OSStatus = noErr

    init() {
        var types = [EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed)),
                     EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyReleased))]
        installationStatus = InstallEventHandler(GetApplicationEventTarget(), { _, event, context in
            guard let event = event, let context = context else { return OSStatus(eventNotHandledErr) }
            let owner = Unmanaged<HotKey>.fromOpaque(context).takeUnretainedValue()
            if GetEventKind(event) == UInt32(kEventHotKeyPressed) { owner.onPress?() }
            else { owner.onRelease?() }
            return noErr
        }, types.count, &types, Unmanaged.passUnretained(self).toOpaque(), &handler)
    }

    // Register first so a conflict leaves the old shortcut working.
    func register(_ shortcut: Shortcut) -> OSStatus {
        guard installationStatus == noErr else { return installationStatus }
        var next: EventHotKeyRef?
        let status = RegisterEventHotKey(shortcut.key, shortcut.modifiers,
                                        EventHotKeyID(signature: 0x50494E47, id: 1),
                                        GetApplicationEventTarget(), 0, &next)
        if status == noErr {
            if let reference = reference { UnregisterEventHotKey(reference) }
            reference = next
        }
        return status
    }
    deinit {
        if let reference = reference { UnregisterEventHotKey(reference) }
        if let handler = handler { RemoveEventHandler(handler) }
    }
}
