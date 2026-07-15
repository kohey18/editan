import SwiftUI

struct TransformResultView: View {
    @EnvironmentObject private var transforms: TransformStore
    @State private var copied = false
    @State private var copiedResetTask: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Divider()
            footer
        }
        .frame(width: 580, height: 440)
    }

    private var header: some View {
        HStack {
            Text(transforms.session?.template.name ?? "変換")
                .font(.headline)
            Spacer()
            if case .running = transforms.session?.status {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .padding(14)
    }

    @ViewBuilder
    private var content: some View {
        switch transforms.session?.status {
        case .running, nil:
            VStack(spacing: 10) {
                ProgressView()
                Text("Claude で変換中…")
                    .foregroundStyle(.secondary)
            }
        case .failed(let message):
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.title2)
                    .foregroundStyle(.orange)
                Text(message)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .padding(.horizontal, 24)
            }
        case .done(let result):
            ScrollView {
                Text(result)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
            }
        }
    }

    private var footer: some View {
        HStack {
            Button("閉じる") { transforms.dismiss() }
                .keyboardShortcut(.cancelAction)
            Spacer()
            Button {
                transforms.copyResult()
                copied = true
                copiedResetTask?.cancel()
                copiedResetTask = Task {
                    try? await Task.sleep(for: .seconds(1.5))
                    if !Task.isCancelled { copied = false }
                }
            } label: {
                if copied {
                    Label("コピーしました", systemImage: "checkmark")
                } else {
                    Text("コピー")
                }
            }
            .disabled(!isDone)
            Button("置き換える") { transforms.applyReplacement() }
                .keyboardShortcut(.defaultAction)
                .disabled(!isDone)
        }
        .padding(14)
    }

    private var isDone: Bool {
        if case .done = transforms.session?.status { return true }
        return false
    }
}
