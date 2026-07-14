import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: BufferStore
    @EnvironmentObject private var transforms: TransformStore

    var body: some View {
        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 360)
        } detail: {
            detailView
        }
        .sheet(isPresented: $transforms.showSheet) {
            TransformResultView()
                .environmentObject(transforms)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    store.showPreview.toggle()
                } label: {
                    Label("プレビュー", systemImage: "sidebar.trailing")
                }
                .help("プレビューの表示/非表示 (⇧⌘P)")
            }
        }
    }

    @ViewBuilder
    private var detailView: some View {
        if let buffer = store.selectedBuffer {
            let textBinding = Binding(
                get: { store.buffers.first(where: { $0.id == buffer.id })?.content ?? "" },
                set: { store.updateContent(id: buffer.id, $0) }
            )
            HSplitView {
                PlainTextEditor(text: textBinding, highlightsMarkdown: buffer.isMarkdown)
                    .frame(minWidth: 320, maxWidth: .infinity, maxHeight: .infinity)
                if store.showPreview && buffer.isMarkdown {
                    MarkdownPreview(markdown: buffer.content)
                        .frame(minWidth: 280, maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .id(buffer.id)
            .navigationTitle(buffer.title)
            .navigationSubtitle(buffer.fileURL?.path(percentEncoded: false) ?? "スクラッチ")
        } else {
            ContentUnavailableView(
                "バッファがありません",
                systemImage: "note.text",
                description: Text("⌘N で新規バッファを作成できます")
            )
        }
    }
}
