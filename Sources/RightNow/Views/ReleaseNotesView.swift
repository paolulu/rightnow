import SwiftUI

/// 一条版本更新记录（从 GitHub Releases 提炼出的简要说明）。
struct VersionNote: Identifiable {
    let id: String        // tag，如 "v0.0.102"
    let version: String   // 显示用，如 "0.0.102"
    let summary: String
    let dateText: String
}

@MainActor
final class ReleaseNotesLoader: ObservableObject {
    @Published var notes: [VersionNote] = []
    @Published var isLoading = true
    @Published var errorMessage: String?

    private struct APIRelease: Decodable {
        let tagName: String
        let body: String?
        let publishedAt: String?
        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
            case body
            case publishedAt = "published_at"
        }
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        guard let url = URL(string: "https://api.github.com/repos/paolulu/rightnow/releases?per_page=30") else {
            isLoading = false
            return
        }
        do {
            var request = URLRequest(url: url)
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            request.timeoutInterval = 12
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                throw URLError(.badServerResponse)
            }
            let releases = try JSONDecoder().decode([APIRelease].self, from: data)
            notes = releases.map { release in
                VersionNote(
                    id: release.tagName,
                    version: release.tagName.hasPrefix("v") ? String(release.tagName.dropFirst()) : release.tagName,
                    summary: Self.summary(from: release.body ?? ""),
                    dateText: String((release.publishedAt ?? "").prefix(10))
                )
            }
        } catch {
            errorMessage = "无法加载更新内容，请检查网络后重试。"
        }
        isLoading = false
    }

    /// 从 release body 里提炼"更新说明"那段：截到下载/安装等样板前，并去掉标题行。
    private static func summary(from body: String) -> String {
        var text = body.replacingOccurrences(of: "\r\n", with: "\n")
        for marker in ["\n---", "\n###", "\n> "] {
            if let range = text.range(of: marker) {
                text = String(text[..<range.lowerBound])
            }
        }
        let kept = text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .drop { line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                return trimmed.isEmpty || trimmed.hasPrefix("#")
            }
        let result = kept.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return result.isEmpty ? "—" : result
    }
}

/// 在应用内显示「版本更新内容」，数据来自 GitHub Releases。
struct ReleaseNotesView: View {
    let currentVersion: String
    let onBack: () -> Void
    let onOpenInBrowser: () -> Void

    @StateObject private var loader = ReleaseNotesLoader()

    var body: some View {
        VStack(spacing: 0) {
            header
            Rectangle().fill(.black.opacity(0.1)).frame(height: 0.5)
            content
                .frame(maxWidth: .infinity)
                .frame(height: 430)
        }
        .task { await loader.load() }
    }

    private var header: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: 3) {
                    Image(systemName: "chevron.left")
                    Text("返回")
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Text("版本更新内容")
                .font(.system(size: 14, weight: .semibold))

            Spacer()

            Button(action: onOpenInBrowser) {
                Image(systemName: "arrow.up.right.square")
            }
            .buttonStyle(.plain)
            .help("在浏览器中打开")
        }
        .font(.system(size: 13))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var content: some View {
        if loader.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = loader.errorMessage {
            VStack(spacing: 12) {
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 28))
                    .foregroundStyle(.secondary)
                Text(error)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("在浏览器中查看", action: onOpenInBrowser)
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(loader.notes) { note in
                        VStack(alignment: .leading, spacing: 5) {
                            HStack(spacing: 8) {
                                Text("v\(note.version)")
                                    .font(.system(size: 14, weight: .semibold))
                                if note.id == "v\(currentVersion)" {
                                    Text("当前")
                                        .font(.system(size: 10, weight: .semibold))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.accentColor.opacity(0.15))
                                        .foregroundStyle(Color.accentColor)
                                        .clipShape(Capsule())
                                }
                                Spacer()
                                Text(note.dateText)
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                            Text(note.summary)
                                .font(.system(size: 12))
                                .foregroundStyle(.primary.opacity(0.85))
                                .fixedSize(horizontal: false, vertical: true)
                                .textSelection(.enabled)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
