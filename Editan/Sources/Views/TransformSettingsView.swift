import SwiftUI

struct TransformSettingsView: View {
    @EnvironmentObject private var transforms: TransformStore

    var body: some View {
        Form {
            Section("LLM") {
                Picker("モデル", selection: $transforms.model) {
                    Text("Haiku(高速)").tag("haiku")
                    Text("Sonnet(標準)").tag("sonnet")
                    Text("Opus(高品質)").tag("opus")
                }
                Text("変換対象の文章は Claude Code CLI 経由で送信されます。認証・利用枠・課金は CLI の設定に従います。ツール実行と会話履歴の保存は無効です。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("変換テンプレート") {
                ForEach($transforms.templates) { $template in
                    DisclosureGroup {
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("名前", text: $template.name)
                            TextEditor(text: $template.prompt)
                                .font(.body)
                                .frame(height: 90)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(.quaternary, lineWidth: 1)
                                )
                            HStack {
                                Spacer()
                                Button("削除", role: .destructive) {
                                    transforms.removeTemplate(template.id)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    } label: {
                        Text(template.name)
                    }
                }
                Button {
                    transforms.addTemplate()
                } label: {
                    Label("テンプレートを追加", systemImage: "plus")
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 540, height: 520)
    }
}
