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
            VStack(alignment: .leading, spacing: DSSpacing.md) {
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
                    .font(.title2.weight(.bold))
                    .foregroundStyle(DSColor.title)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)

                HStack(spacing: DSSpacing.xs) {
                    DSTag(text: displayedSourceTitle)
                    Text(displayedPublishDate)
                        .font(.footnote)
                        .monospacedDigit()
                        .foregroundStyle(DSColor.subtitle)
                }

                if let sourceURL = displayedSourceURL, let url = URL(string: sourceURL) {
                    Button {
                        openURL(url)
                    } label: {
                        Label(localizedString("news.openOriginal"), systemImage: "safari")
                            .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.roundedRectangle(radius: DSRadius.control))
                    .tint(DSColor.primary)
                }

                Rectangle()
                    .fill(DSColor.divider)
                    .frame(height: 0.5)

                Text(displayedContent)
                    .font(.body)
                    .lineSpacing(6)
                    .foregroundStyle(DSColor.title)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, DSSpacing.lg)
            .padding(.vertical, DSSpacing.md)
            .frame(maxWidth: 720, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .dsScreenBackground()
        .navigationTitle(displayedSourceTitle)
        .navigationBarTitleDisplayMode(.inline)
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
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("news.loadFailed")
        }
    }
}
