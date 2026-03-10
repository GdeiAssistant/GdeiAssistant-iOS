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
        .navigationTitle("四六级查询")
        .task {
            await viewModel.loadIfNeeded()
        }
        .alert("提示", isPresented: Binding(
            get: { viewModel.queryState.message != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.clearQueryState()
                }
            }
        )) {
            Button("知道了") {
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
                    Text("查询信息")
                        .font(.headline)
                        .foregroundStyle(DSColor.title)

                    DSInputField(
                        title: "准考证号",
                        placeholder: "请输入15位准考证号",
                        text: $viewModel.ticketNumber,
                        keyboardType: .numberPad
                    )

                    DSInputField(
                        title: "姓名",
                        placeholder: "姓名超过3个字可只输入前3个",
                        text: $viewModel.candidateName
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text("验证码")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(DSColor.subtitle)

                        HStack(spacing: 12) {
                            TextField("请输入验证码", text: $viewModel.captchaCode)
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

                    Text("验证码图片来自后端 `/cet/checkcode`，点击图片可刷新。")
                        .font(.caption)
                        .foregroundStyle(DSColor.subtitle)

                    DSButton(
                        title: "查询成绩",
                        icon: "doc.text.magnifyingglass",
                        isLoading: viewModel.queryState.isSubmitting
                    ) {
                        Task { await viewModel.queryScore() }
                    }
                }

                DSCard {
                    Text("成绩记录")
                        .font(.headline)
                        .foregroundStyle(DSColor.title)

                    if dashboard.scoreRecords.isEmpty {
                        Text("请输入准考证号、姓名和验证码后查询。")
                            .font(.subheadline)
                            .foregroundStyle(DSColor.subtitle)
                    } else {
                        infoRow(title: "姓名", value: dashboard.profile.candidateName)
                        infoRow(title: "学校", value: dashboard.profile.schoolName)
                        infoRow(title: "级别", value: dashboard.profile.examLevel)
                        infoRow(title: "准考证号", value: dashboard.profile.admissionTicket)

                        ForEach(dashboard.scoreRecords) { record in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("\(record.examSession) · \(record.level)")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(DSColor.title)
                                    Spacer()
                                    Text("总分 \(record.totalScore)")
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(record.passed ? DSColor.secondary : DSColor.danger)
                                }

                                Text("听力 \(record.listeningScore)  阅读 \(record.readingScore)  写作 \(record.writingScore)")
                                    .font(.caption)
                                    .foregroundStyle(DSColor.subtitle)

                                if let speaking = record.speakingScore {
                                    Text("口语 \(speaking)")
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
