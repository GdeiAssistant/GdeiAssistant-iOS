import SwiftUI

private struct LanguageOption: Identifiable {
    let code: String
    let nativeName: String
    var id: String { code }
}

private let languageOptions = [
    LanguageOption(code: "zh-CN", nativeName: "简体中文"),
    LanguageOption(code: "zh-HK", nativeName: "繁體中文（香港）"),
    LanguageOption(code: "zh-TW", nativeName: "繁體中文（台灣）"),
    LanguageOption(code: "en", nativeName: "English"),
    LanguageOption(code: "ja", nativeName: "日本語"),
    LanguageOption(code: "ko", nativeName: "한국어")
]

private let fontScaleLabels = [
    "appearance.font.small",
    "appearance.font.standard",
    "appearance.font.large",
    "appearance.font.xlarge"
]

struct AppearanceView: View {
    @EnvironmentObject private var preferences: UserPreferences

    var body: some View {
        List {
            // Theme
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
                                    .foregroundStyle(DSColor.primary)
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

            // Font Size
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
                    .tint(DSColor.primary)

                    HStack {
                        ForEach(fontScaleLabels.indices, id: \.self) { i in
                            Text(LocalizedStringKey(fontScaleLabels[i]))
                                .font(.caption)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .foregroundStyle(DSColor.subtitle)

                    Text(LocalizedStringKey("appearance.font.preview"))
                        .font(.system(size: 16 * preferences.fontScale))
                        .padding(.top, 4)
                }
                .padding(.vertical, 8)
            } header: {
                Text(LocalizedStringKey("appearance.font.label"))
            }

            // Language
            Section {
                ForEach(languageOptions) { option in
                    Button {
                        preferences.selectedLocale = option.code
                    } label: {
                        HStack {
                            Text(option.nativeName)
                                .foregroundStyle(DSColor.title)
                            Spacer()
                            if preferences.selectedLocale == option.code {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(DSColor.primary)
                                    .fontWeight(.semibold)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text(LocalizedStringKey("appearance.language.label"))
            }
        }
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
