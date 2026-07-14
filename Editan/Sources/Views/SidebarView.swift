import AppKit
import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var store: BufferStore

    var body: some View {
        List(selection: $store.selectedID) {
            Section("バッファ") {
                ForEach(store.buffers) { buffer in
                    row(for: buffer)
                        .tag(buffer.id)
                }
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            Button {
                store.newBuffer()
            } label: {
                Label("新規バッファ", systemImage: "plus")
            }
            .buttonStyle(.borderless)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func row(for buffer: Buffer) -> some View {
        HStack(spacing: 6) {
            Image(systemName: buffer.isScratch ? "note.text" : "doc.text")
                .foregroundStyle(.secondary)
            Text(buffer.title)
                .lineLimit(1)
            Spacer()
            if buffer.hasUnsavedChanges {
                Circle()
                    .fill(.secondary)
                    .frame(width: 6, height: 6)
            }
        }
        .contextMenu {
            if let url = buffer.fileURL {
                Button("Finder で表示") {
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                }
            }
            Button("削除", role: .destructive) {
                store.deleteBuffer(buffer.id)
            }
        }
    }
}
