import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            TransformSettingsView()
                .tabItem { Label("変換", systemImage: "wand.and.stars") }
            NotionSettingsView()
                .tabItem { Label("Notion", systemImage: "paperplane") }
        }
        .frame(width: 560)
    }
}

struct NotionSettingsView: View {
    @AppStorage("notionToken") private var token = ""
    @AppStorage("notionParentPageID") private var parentPageID = ""

    var body: some View {
        Form {
            Section("Notion 連携") {
                SecureField("Integration Token", text: $token)
                TextField("親ページ ID", text: $parentPageID)
            }
            Section {
                Text("""
                1. notion.so/my-integrations で Internal Integration を作成し、トークンを貼り付け
                2. 転記先にしたい Notion ページを開き、右上「…」→「接続」から作成した Integration を追加
                3. そのページの URL 末尾 32 文字(ハイフン除去済みの ID)を「親ページ ID」に貼り付け

                「ファイル → Notion に送る」で、現在のバッファがそのページ配下に新規ページとして作成されます。
                """)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(height: 320)
    }
}
