# Third-Party Notices

This repository (`GdeiAssistant-iOS`) is licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) and [NOTICE](NOTICE).

## Application Runtime Dependencies

`GdeiAssistant-iOS` currently has **no third-party Swift Package Manager, CocoaPods, or Carthage runtime dependencies**. The iOS application and test targets link solely against Apple system frameworks provided by the Xcode / iOS SDK (such as SwiftUI, Foundation, Security, Combine, and UIKit).

## CI / Development Tooling

The repository's GitHub Actions workflows reference third-party actions (for example `actions/checkout`, `actions/upload-artifact`, `github/codeql-action`, `gitleaks/gitleaks-action`, and `rhysd/actionlint`) solely during CI execution. Those actions are governed by their respective upstream licenses and are not bundled into the compiled iOS application.

## Updating This File

If any third-party Swift package, binary framework, or vendored source component is added to the iOS app or test targets in the future, record its component name, version, license, and required attribution notice in this file.
