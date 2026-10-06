import SwiftUI

struct DSEmptyStateView: View {
    var icon: String = "tray"
    var title: String
    var message: String

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: icon)
        } description: {
            Text(message)
        }
        .symbolRenderingMode(.hierarchical)
        .foregroundStyle(DSColor.title, DSColor.primary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct DSStateLayout<Actions: View>: View {
    let icon: String
    let tint: Color
    let tileBackground: Color
    let title: String
    let message: String
    private let actions: Actions

    init(
        icon: String,
        tint: Color,
        tileBackground: Color,
        title: String,
        message: String,
        @ViewBuilder actions: () -> Actions
    ) {
        self.icon = icon
        self.tint = tint
        self.tileBackground = tileBackground
        self.title = title
        self.message = message
        self.actions = actions()
    }

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: icon)
        } description: {
            Text(message)
        } actions: {
            actions
        }
        .symbolRenderingMode(.hierarchical)
        .foregroundStyle(DSColor.title, tint)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
    }
}

extension DSStateLayout where Actions == EmptyView {
    init(icon: String, tint: Color, tileBackground: Color, title: String, message: String) {
        self.init(icon: icon, tint: tint, tileBackground: tileBackground, title: title, message: message) {
            EmptyView()
        }
    }
}
