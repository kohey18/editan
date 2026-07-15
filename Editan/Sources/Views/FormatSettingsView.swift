import SwiftUI

struct FormatSettingsView: View {
    @EnvironmentObject private var formats: FormatStore

    var body: some View {
        Form {
            Section("フォーマット") {
                ForEach($formats.templates) { $template in
                    DisclosureGroup {
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("名前", text: $template.name)
                            TextEditor(text: $template.content)
                                .font(.system(.body, design: .monospaced))
                                .frame(height: 160)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(.quaternary, lineWidth: 1)
                                )
                            HStack {
                                Spacer()
                                Button("削除", role: .destructive) {
                                    formats.removeTemplate(template.id)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    } label: {
                        Text(template.name)
                    }
                }
                Button {
                    formats.addTemplate()
                } label: {
                    Label("フォーマットを追加", systemImage: "plus")
                }
            }
            Section {
                Text("""
                挿入時に置き換わるプレースホルダ:
                {{date}} → 今日の日付(2026-07-15) {{time}} → 現在時刻(14:30)
                {{weekday}} → 曜日(水) {{cursor}} → 挿入後のカーソル位置
                """)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 540, height: 520)
    }
}
