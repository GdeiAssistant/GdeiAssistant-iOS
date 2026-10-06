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
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                if isLoading {
                    ProgressView()
                }

                Text(displayedTitle)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(DSColor.title)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)

                Label(displayedCreatedAt, systemImage: "clock")
                    .font(.footnote)
                    .monospacedDigit()
                    .foregroundStyle(DSColor.subtitle)

                Rectangle()
                    .fill(DSColor.divider)
                    .frame(height: 0.5)
                    .padding(.vertical, DSSpacing.xxs)

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
        .navigationTitle(navigationTitleText)
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
