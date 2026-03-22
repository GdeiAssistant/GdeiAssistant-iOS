import SwiftUI

struct CETView: View {
    @StateObject private var viewModel: CETViewModel

    init(viewModel: CETViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            if let errorMessage = viewModel.errorMessage, viewModel.dashboard == nil {
                DSErrorStateView(message: errorMessage) {
                    Task {
                        await viewModel.refreshCaptcha()
                    }
                }
            } else {
                content(viewModel.dashboard ?? CETRemoteMapper.emptyDashboard())
            }
        }
        .navigationTitle(localizedString("cet.title"))
        .task {
            await viewModel.loadIfNeeded()
        }
        .alert(localizedString("cet.alertTitle"), isPresented: Binding(
            get: { viewModel.queryState.message != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.clearQueryState()
                }
            }
        )) {
            Button(localizedString("cet.alertDismiss")) {
                viewModel.clearQueryState()
            }
        } message: {
            Text(viewModel.queryState.message ?? "")
        }
    }

    private func content(_ dashboard: CETDashboard) -> some View {
        ScrollView {
            VStack(spacing: 14) {
                DSCard {
                    Text(LocalizedStringKey("cet.queryInfo"))
                        .font(.headline)
                        .foregroundStyle(DSColor.title)

                    DSInputField(
                        title: localizedString("cet.ticketNumber"),
                        placeholder: localizedString("cet.ticketPlaceholder"),
                        text: $viewModel.ticketNumber,
                        keyboardType: .numberPad
                    )

                    DSInputField(
                        title: localizedString("cet.candidateName"),
                        placeholder: localizedString("cet.namePlaceholder"),
                        text: $viewModel.candidateName
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizedStringKey("cet.captcha"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(DSColor.subtitle)

                        HStack(spacing: 12) {
                            TextField(localizedString("cet.captchaPlaceholder"), text: $viewModel.captchaCode)
                                .textFieldStyle(.roundedBorder)
                                .textInputAutocapitalization(.never)

                            CaptchaImageView(
                                base64String: viewModel.captchaImageBase64,
                                isLoading: viewModel.isCaptchaLoading,
                                refreshAction: {
                                    Task { await viewModel.refreshCaptcha() }
                                }
                            )
                        }
                    }

                    Text(LocalizedStringKey("cet.captchaHint"))
                        .font(.caption)
                        .foregroundStyle(DSColor.subtitle)

                    DSButton(
                        title: localizedString("cet.queryScore"),
                        icon: "doc.text.magnifyingglass",
                        isLoading: viewModel.queryState.isSubmitting
                    ) {
                        Task { await viewModel.queryScore() }
                    }
                }

                DSCard {
                    Text(LocalizedStringKey("cet.scoreRecords"))
                        .font(.headline)
                        .foregroundStyle(DSColor.title)

                    if dashboard.scoreRecords.isEmpty {
                        Text(LocalizedStringKey("cet.scoreEmptyHint"))
                            .font(.subheadline)
                            .foregroundStyle(DSColor.subtitle)
                    } else {
                        infoRow(title: localizedString("cet.name"), value: dashboard.profile.candidateName)
                        infoRow(title: localizedString("cet.school"), value: dashboard.profile.schoolName)
                        infoRow(title: localizedString("cet.level"), value: dashboard.profile.examLevel)
                        infoRow(title: localizedString("cet.ticketNumber"), value: dashboard.profile.admissionTicket)

                        ForEach(dashboard.scoreRecords) { record in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("\(record.examSession) · \(record.level)")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(DSColor.title)
                                    Spacer()
                                    Text(localizedString("cet.totalScore") + " \(record.totalScore)")
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(record.passed ? DSColor.secondary : DSColor.danger)
                                }

                                Text("\(localizedString("cet.listening")) \(record.listeningScore)  \(localizedString("cet.reading")) \(record.readingScore)  \(localizedString("cet.writing")) \(record.writingScore)")
                                    .font(.caption)
                                    .foregroundStyle(DSColor.subtitle)

                                if let speaking = record.speakingScore {
                                    Text("\(localizedString("cet.speaking")) \(speaking)")
                                        .font(.caption)
                                        .foregroundStyle(DSColor.subtitle)
                                }
                            }
                            .padding(.vertical, 6)
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(DSColor.background)
        .refreshable {
            await viewModel.refreshCaptcha()
        }
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(DSColor.subtitle)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(DSColor.title)
        }
    }
}

#Preview {
    NavigationStack {
        CETView(viewModel: CETViewModel(repository: MockCETRepository()))
    }
}
