import SwiftUI

struct NewsDetailView: View {
    @EnvironmentObject private var container: AppContainer
    @Environment(\.openURL) private var openURL

    let newsID: String
    let fallbackTitle: String
    let fallbackContent: String
    let fallbackPublishDate: String
    let fallbackType: Int
    let fallbackSourceURL: String?

    @State private var detail: NewsItem?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(DSColor.danger)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if isLoading && detail == nil {
                    ProgressView()
                }

                Text(displayedTitle)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(DSColor.title)

                HStack(spacing: 10) {
                    Text(displayedSourceTitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DSColor.primary)
                    Text(displayedPublishDate)
                        .font(.caption)
                        .foregroundStyle(DSColor.subtitle)
                }

                if let sourceURL = displayedSourceURL, let url = URL(string: sourceURL) {
                    Button {
                        openURL(url)
                    } label: {
                        Label("打开原文链接", systemImage: "safari")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(DSColor.primary)
                    }
                    .buttonStyle(.plain)
                }

                Text(displayedContent)
                    .font(.body)
                    .foregroundStyle(DSColor.title)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(20)
        }
        .navigationTitle(displayedSourceTitle)
        .task {
            await loadDetail()
        }
    }

    private var displayedTitle: String {
        detail?.title ?? fallbackTitle
    }

    private var displayedContent: String {
        detail?.content ?? fallbackContent
    }

    private var displayedPublishDate: String {
        detail?.publishDate ?? fallbackPublishDate
    }

    private var displayedSourceURL: String? {
        detail?.sourceURL ?? fallbackSourceURL
    }

    private var displayedSourceTitle: String {
        detail?.sourceTitle ?? NewsItem(
            id: newsID,
            type: fallbackType,
            title: fallbackTitle,
            publishDate: fallbackPublishDate,
            content: fallbackContent,
            sourceURL: fallbackSourceURL
        ).sourceTitle
    }

    private func loadDetail() async {
        guard detail == nil else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            detail = try await container.newsRepository.fetchNewsDetail(id: newsID)
        } catch {
            detail = nil
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "新闻加载失败"
        }
    }
}
