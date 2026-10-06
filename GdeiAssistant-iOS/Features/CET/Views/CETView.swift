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
        Form {
            Section {
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

                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    Text(LocalizedStringKey("cet.captcha"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(DSColor.subtitle)

                    HStack(spacing: DSSpacing.sm) {
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
            } header: {
                Text(LocalizedStringKey("cet.queryInfo"))
            } footer: {
                Text(LocalizedStringKey("cet.captchaHint"))
            }

            Section {
                DSButton(
                    title: localizedString("cet.queryScore"),
                    icon: "doc.text.magnifyingglass",
                    isLoading: viewModel.queryState.isSubmitting
                ) {
                    Task { await viewModel.queryScore() }
                }
                .dsActionRow()
            }

            Section {
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
                        VStack(alignment: .leading, spacing: DSSpacing.xs) {
                            HStack(alignment: .firstTextBaseline) {
                                Text("\(record.examSession) · \(record.level)")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(DSColor.title)
                                Spacer()
                                Text(localizedString("cet.totalScore") + " \(record.totalScore)")
                                    .font(.title3.weight(.bold))
                                    .monospacedDigit()
                                    .foregroundStyle(record.passed ? DSColor.primary : DSColor.danger)
                            }

                            Text("\(localizedString("cet.listening")) \(record.listeningScore)  \(localizedString("cet.reading")) \(record.readingScore)  \(localizedString("cet.writing")) \(record.writingScore)")
                                .font(.footnote)
                                .monospacedDigit()
                                .foregroundStyle(DSColor.subtitle)

                            if let speaking = record.speakingScore {
                                Text("\(localizedString("cet.speaking")) \(speaking)")
                                    .font(.footnote)
                                    .foregroundStyle(DSColor.subtitle)
                            }
                        }
                        .padding(.vertical, DSSpacing.xxs)
                    }
                }
            } header: {
                Text(LocalizedStringKey("cet.scoreRecords"))
            }
        }
        .dsForm()
        .refreshable {
            await viewModel.refreshCaptcha()
        }
    }

    private func infoRow(title: String, value: String) -> some View {
        LabeledContent(title, value: value)
            .foregroundStyle(DSColor.title)
    }
}

#Preview {
    NavigationStack {
        CETView(viewModel: CETViewModel(repository: MockCETRepository()))
    }
}
