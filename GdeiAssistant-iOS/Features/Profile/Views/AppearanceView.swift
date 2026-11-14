import SwiftUI

private let fontScaleLabels = [
    "appearance.font.small",
    "appearance.font.standard",
    "appearance.font.large",
    "appearance.font.xlarge"
]

struct AppearanceView: View {
    @EnvironmentObject private var preferences: UserPreferences
    @Environment(\.dsCampusAccent) private var campusAccent

    var body: some View {
        List {
            Section {
                ForEach(UserPreferences.ThemeMode.allCases, id: \.self) { mode in
                    Button {
                        preferences.selectedTheme = mode
                    } label: {
                        HStack {
                            Text(localizedString(mode.localizationKey))
                                .foregroundStyle(DSColor.title)
                            Spacer()
                            if preferences.selectedTheme == mode {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(campusAccent.primary)
                                    .fontWeight(.semibold)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text(LocalizedStringKey("appearance.theme.label"))
            }

            Section {
                ForEach(DSCampusAccent.allCases) { accent in
                    Button {
                        preferences.selectedAccent = accent
                    } label: {
                        HStack(spacing: DSSpacing.sm) {
                            ZStack {
                                Circle()
                                    .fill(accent.primarySoft)
                                    .frame(width: 28, height: 28)
                                Circle()
                                    .fill(accent.primary)
                                    .frame(width: 14, height: 14)
                            }
                            .overlay(
                                Circle()
                                    .stroke(accent.primary.opacity(0.32), lineWidth: 1)
                            )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(localizedString(accent.localizationKey))
                                    .font(.body)
                                    .foregroundStyle(DSColor.title)
                                Text(localizedString(accent.subtitleKey))
                                    .font(.caption)
                                    .foregroundStyle(DSColor.subtitle)
                            }

                            Spacer()

                            if preferences.selectedAccent == accent {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(accent.primary)
                                    .fontWeight(.semibold)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("appearance.accent.\(accent.rawValue)")
                }
            } header: {
                Text(LocalizedStringKey("appearance.accent.label"))
            }

            Section {
                VStack(spacing: 12) {
                    Slider(
                        value: Binding(
                            get: { Double(preferences.fontScaleStep) },
                            set: { preferences.fontScaleStep = Int($0) }
                        ),
                        in: 0...3,
                        step: 1
                    )
                    .tint(campusAccent.primary)

                    HStack {
                        ForEach(fontScaleLabels.indices, id: \.self) { i in
                            Text(LocalizedStringKey(fontScaleLabels[i]))
                                .font(.caption)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .foregroundStyle(DSColor.subtitle)

                    Text(LocalizedStringKey("appearance.font.preview"))
                        .font(.system(size: 16 * preferences.fontScale, design: .serif))
                        .foregroundStyle(DSColor.title)
                        .padding(.top, 4)
                }
                .padding(.vertical, 8)
            } header: {
                Text(LocalizedStringKey("appearance.font.label"))
            }

            Section {
                ForEach(AppLanguage.allCases) { option in
                    Button {
                        preferences.selectedLocale = option.localeIdentifier
                    } label: {
                        HStack {
                            Text(option.nativeName)
                                .foregroundStyle(DSColor.title)
                            Spacer()
                            if preferences.selectedLocale == option.localeIdentifier {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(campusAccent.primary)
                                    .fontWeight(.semibold)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("appearance.language.\(option.localeIdentifier)")
                }
            } header: {
                Text(LocalizedStringKey("appearance.language.label"))
            }
        }
        .dsListBackground()
        .listStyle(.insetGrouped)
        .navigationTitle(localizedString("appearance.title"))
    }
}

private extension UserPreferences.ThemeMode {
    var localizationKey: String {
        switch self {
        case .system:
            return "appearance.theme.system"
        case .light:
            return "appearance.theme.light"
        case .dark:
            return "appearance.theme.dark"
        }
    }
}
