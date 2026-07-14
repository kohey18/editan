import AppKit

/// メニューコマンドからエディタの NSTextView へアクセスするためのヘルパー。
@MainActor
enum EditorAccess {
    static func currentTextView() -> NSTextView? {
        if let key = NSApp.keyWindow, let found = findTextView(in: key.contentView) {
            return found
        }
        for window in NSApp.windows where window.isVisible {
            if let found = findTextView(in: window.contentView) { return found }
        }
        return nil
    }

    private static func findTextView(in view: NSView?) -> NSTextView? {
        guard let view else { return nil }
        if let textView = view as? PlainTextView { return textView }
        for subview in view.subviews {
            if let found = findTextView(in: subview) { return found }
        }
        return nil
    }

    /// Undo に載せた状態で全文を置き換える。
    static func replaceAllText(with newText: String, in textView: NSTextView) {
        let full = NSRange(location: 0, length: (textView.string as NSString).length)
        guard textView.shouldChangeText(in: full, replacementString: newText) else { return }
        textView.textStorage?.replaceCharacters(in: full, with: newText)
        textView.didChangeText()
    }
}
