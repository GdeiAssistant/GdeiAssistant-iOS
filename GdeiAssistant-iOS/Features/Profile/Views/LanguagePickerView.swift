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

struct LanguagePickerView: View {
    @EnvironmentObject private var preferences: UserPreferences

    var body: some View {
        List {
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
                Text("语言 / Language")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("语言")
    }
}

#Preview {
    let container = AppContainer.preview
    NavigationStack {
        LanguagePickerView()
    }
    .environmentObject(container.userPreferences)
}
