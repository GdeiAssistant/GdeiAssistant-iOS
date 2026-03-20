import SwiftUI

struct ThemePickerView: View {
    @EnvironmentObject private var preferences: UserPreferences

    var body: some View {
        List {
            Section {
                ForEach(DSTheme.allCases) { theme in
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            preferences.selectedThemeKey = theme.rawValue
                        }
                    } label: {
                        HStack(spacing: 14) {
                            Circle()
                                .fill(theme.primaryColor)
                                .frame(width: 28, height: 28)

                            Text(theme.displayName)
                                .foregroundStyle(DSColor.title)

                            Spacer()

                            if preferences.currentTheme == theme {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(theme.primaryColor)
                                    .fontWeight(.semibold)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("主题色")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("主题设置")
    }
}

#Preview {
    let container = AppContainer.preview
    NavigationStack {
        ThemePickerView()
    }
    .environmentObject(container.userPreferences)
}
