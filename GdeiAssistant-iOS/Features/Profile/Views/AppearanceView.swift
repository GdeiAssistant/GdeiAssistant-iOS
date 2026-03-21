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
                            Text(NSLocalizedString("appearance.theme.\(mode.rawValue)", comment: ""))
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
                Text(NSLocalizedString("appearance.theme.label", comment: ""))
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
                            Text(NSLocalizedString(fontScaleLabels[i], comment: ""))
                                .font(.caption)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .foregroundStyle(DSColor.subtitle)

                    Text(NSLocalizedString("appearance.font.preview", comment: ""))
                        .font(.system(size: 16 * preferences.fontScale))
                        .padding(.top, 4)
                }
                .padding(.vertical, 8)
            } header: {
                Text(NSLocalizedString("appearance.font.label", comment: ""))
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
                Text(NSLocalizedString("appearance.language.label", comment: ""))
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(NSLocalizedString("appearance.title", comment: ""))
    }
}
