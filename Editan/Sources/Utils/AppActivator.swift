import AppKit
import Carbon.HIToolbox

@MainActor
enum AppActivator {
    static func activate(focusEditor: Bool = true) {
        NSApp.activate(ignoringOtherApps: true)
        let window = NSApp.windows.first { $0.identifier?.rawValue == "main" }
            ?? NSApp.windows.first { $0.canBecomeKey }
        guard let window else { return }
        window.makeKeyAndOrderFront(nil)
        if focusEditor, let textView = EditorAccess.currentTextView() {
            window.makeFirstResponder(textView)
        }
    }
}

/// ⌥⌘E でどのアプリからでも Editan を前面に出すグローバルホットキー。
/// RegisterEventHotKey はアクセシビリティ権限が不要。
final class HotKeyManager {
    static let shared = HotKeyManager()
    private var registered = false
    private var hotKeyRef: EventHotKeyRef?

    func register() {
        guard !registered else { return }
        registered = true
        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        InstallEventHandler(GetApplicationEventTarget(), { _, _, _ in
            Task { @MainActor in
                AppActivator.activate()
            }
            return noErr
        }, 1, &spec, nil, nil)

        let hotKeyID = EventHotKeyID(signature: 0x4544_544E, id: 1) // "EDTN"
        RegisterEventHotKey(
            UInt32(kVK_ANSI_E),
            UInt32(cmdKey | optionKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }
}
