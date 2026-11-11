import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: BufferStore
    @EnvironmentObject private var transforms: TransformStore
    @EnvironmentObject private var find: FindController
    @State private var zoomHUDVisible = false
    @State private var zoomHUDTask: Task<Void, Never>?

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
                if let url = store.selectedBuffer?.fileURL {
                    Button {
                        NSWorkspace.shared.activateFileViewerSelecting([url])
                    } label: {
                        Label("Finder で表示", systemImage: "folder")
                    }
                    .help("このファイルを Finder で表示")
                }
            }
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

    private func showZoomHUD() {
        withAnimation(.easeOut(duration: 0.12)) { zoomHUDVisible = true }
        zoomHUDTask?.cancel()
        zoomHUDTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.2))
            guard !Task.isCancelled else { return }
            withAnimation(.easeIn(duration: 0.25)) { zoomHUDVisible = false }
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
                PlainTextEditor(
                    text: textBinding,
                    highlightsMarkdown: buffer.isMarkdown,
                    fontSize: (MarkdownHighlighter.defaultFontSize * store.zoom).rounded(),
                    onFormatSelection: { store.formatMarkdown() },
                    onKeigoSelection: { transforms.runKeigo() }
                )
                    .frame(minWidth: 320, maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(alignment: .topTrailing) {
                        if find.isVisible {
                            FindBar(find: find)
                                .padding(.top, 8)
                                .padding(.trailing, 20)
                        }
                    }
                if store.showPreview && buffer.isMarkdown {
                    MarkdownPreview(markdown: buffer.content, zoom: store.zoom)
                        .frame(minWidth: 280, maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .id(buffer.id)
            .overlay(alignment: .top) {
                if zoomHUDVisible {
                    Text("\(Int((store.zoom * 100).rounded()))%")
                        .font(.system(size: 13, weight: .medium).monospacedDigit())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.regularMaterial, in: Capsule())
                        .overlay(Capsule().stroke(.quaternary, lineWidth: 1))
                        .padding(.top, 10)
                        .transition(.opacity)
                        .allowsHitTesting(false)
                }
            }
            .onChange(of: buffer.content) { find.textDidChange() }
            .onChange(of: buffer.id) {
                // 新しいエディタが作られてから数え直す
                DispatchQueue.main.async { find.textDidChange() }
            }
            .onChange(of: store.zoom) { showZoomHUD() }
            .navigationTitle(buffer.title)
            .navigationSubtitle(buffer.fileURL?.path(percentEncoded: false) ?? "下書き(自動保存)")
        } else {
            ContentUnavailableView(
                "バッファがありません",
                systemImage: "note.text",
                description: Text("⌘N で新規バッファを作成できます")
            )
        }
    }
}
