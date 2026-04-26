import SwiftUI

struct CampusCredentialView: View {
    @StateObject private var viewModel: CampusCredentialViewModel
    @EnvironmentObject private var environment: AppEnvironment
    @State private var showRevokeConfirmation = false
    @State private var showDeleteConfirmation = false

    init(viewModel: CampusCredentialViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                statusCard
                actionCard
            }
            .padding(16)
        }
        .background(DSColor.background)
        .navigationTitle(localizedString("campusCredential.title"))
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load()
        }
        .onChange(of: environment.dataSourceMode) { _, _ in
            Task { await viewModel.load() }
        }
        .onChange(of: environment.networkEnvironment) { _, _ in
            Task { await viewModel.load() }
        }
        .confirmationDialog(
            localizedString("campusCredential.revokeTitle"),
            isPresented: $showRevokeConfirmation,
            titleVisibility: .visible
        ) {
            Button(localizedString("campusCredential.revoke"), role: .destructive) {
                Task { await viewModel.revokeConsent() }
            }
            .disabled(!viewModel.canRunAction)

            Button(localizedString("common.cancel"), role: .cancel) {}
        } message: {
            Text(localizedString("campusCredential.revokeMessage"))
        }
        .confirmationDialog(
            localizedString("campusCredential.deleteTitle"),
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(localizedString("campusCredential.delete"), role: .destructive) {
                Task { await viewModel.deleteCredential() }
            }
            .disabled(!viewModel.canRunAction)

            Button(localizedString("common.cancel"), role: .cancel) {}
        } message: {
            Text(localizedString("campusCredential.deleteMessage"))
        }
        .alert(localizedString("common.notice"), isPresented: Binding(
            get: { viewModel.noticeMessage != nil },
            set: { if !$0 { viewModel.noticeMessage = nil } }
        )) {
            Button(localizedString("common.understood")) {
                viewModel.noticeMessage = nil
            }
        } message: {
            Text(viewModel.noticeMessage ?? "")
        }
    }

    private var statusCard: some View {
        DSCard {
            HStack {
                Text(localizedString("campusCredential.title"))
                    .font(.headline)
                    .foregroundStyle(DSColor.title)
                Spacer()
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.85)
                }
            }

            statusRow(
                localizedString("campusCredential.authStatus"),
                viewModel.status.hasActiveConsent
                    ? localizedString("campusCredential.authorized")
                    : localizedString("campusCredential.unauthorized")
            )
            statusRow(
                localizedString("campusCredential.saved"),
                viewModel.status.hasSavedCredential
                    ? localizedString("campusCredential.yes")
                    : localizedString("campusCredential.no")
            )
            statusRow(
                localizedString("campusCredential.quickAuth"),
                viewModel.status.quickAuthEnabled
                    ? localizedString("campusCredential.enabled")
                    : localizedString("campusCredential.disabled")
            )

            if let consentedAt = viewModel.status.consentedAt {
                statusRow(localizedString("campusCredential.consentedAt"), consentedAt)
            }
            if let revokedAt = viewModel.status.revokedAt {
                statusRow(localizedString("campusCredential.revokedAt"), revokedAt)
            }
            if let policyDate = viewModel.status.policyDate {
                statusRow(localizedString("campusCredential.policyDate"), policyDate)
            }
            if let effectiveDate = viewModel.status.effectiveDate {
                statusRow(localizedString("campusCredential.effectiveDate"), effectiveDate)
            }
            if let maskedCampusAccount = viewModel.status.maskedCampusAccount {
                statusRow(localizedString("campusCredential.account"), maskedCampusAccount)
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(DSColor.danger)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var actionCard: some View {
        DSCard {
            Toggle(isOn: quickAuthBinding) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(localizedString("campusCredential.quickAuth"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(DSColor.title)
                    Text(localizedString("campusCredential.quickAuthHint"))
                        .font(.footnote)
                        .foregroundStyle(DSColor.subtitle)
                }
            }
            .disabled(!viewModel.canRunAction)
            .accessibilityIdentifier("campusCredential.quickAuth")

            if !viewModel.status.hasActiveConsent {
                DSButton(
                    title: localizedString("campusCredential.reauthorize"),
                    icon: "checkmark.shield",
                    variant: .primary,
                    isLoading: viewModel.isActionRunning,
                    isDisabled: !viewModel.canRunAction,
                    accessibilityIdentifier: "campusCredential.reauthorize"
                ) {
                    Task { await viewModel.recordConsent() }
                }
            }

            DSButton(
                title: localizedString("campusCredential.revoke"),
                icon: "xmark.shield",
                variant: .secondary,
                isLoading: viewModel.isActionRunning,
                isDisabled: !viewModel.canRunAction,
                accessibilityIdentifier: "campusCredential.revoke"
            ) {
                showRevokeConfirmation = true
            }

            DSButton(
                title: localizedString("campusCredential.delete"),
                icon: "trash",
                variant: .destructive,
                isLoading: viewModel.isActionRunning,
                isDisabled: !viewModel.canRunAction,
                accessibilityIdentifier: "campusCredential.delete"
            ) {
                showDeleteConfirmation = true
            }
        }
    }

    private var quickAuthBinding: Binding<Bool> {
        Binding(
            get: { viewModel.status.quickAuthEnabled },
            set: { enabled in
                Task { await viewModel.setQuickAuthEnabled(enabled) }
            }
        )
    }

    private func statusRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(DSColor.subtitle)
            Spacer(minLength: 12)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(DSColor.title)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
        }
    }
}

#Preview {
    let container = AppContainer.preview
    return NavigationStack {
        CampusCredentialView(viewModel: CampusCredentialViewModel(repository: container.accountCenterRepository))
    }
    .environmentObject(container.environment)
}
