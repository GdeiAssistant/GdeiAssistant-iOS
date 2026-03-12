import SwiftUI

struct AnnouncementDetailView: View {
    @EnvironmentObject private var container: AppContainer

    let navigationTitleText: String
    let announcementID: String
    let fallbackTitle: String
    let fallbackContent: String
    let fallbackCreatedAt: String

    @State private var detail: AnnouncementDetailItem?
    @State private var isLoading = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if isLoading {
                    ProgressView()
                }

                Text(displayedTitle)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(DSColor.title)

                Text(displayedCreatedAt)
                    .font(.caption)
                    .foregroundStyle(DSColor.subtitle)

                Text(displayedContent)
                    .font(.body)
                    .foregroundStyle(DSColor.title)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(20)
        }
        .navigationTitle(navigationTitleText)
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

    private var displayedCreatedAt: String {
        detail?.createdAt ?? fallbackCreatedAt
    }

    private func loadDetail() async {
        guard detail == nil else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            detail = try await container.messagesRepository.fetchAnnouncementDetail(id: announcementID)
        } catch {
            detail = nil
        }
    }
}
