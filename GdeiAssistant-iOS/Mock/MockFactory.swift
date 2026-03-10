import Foundation

enum MockFactory {
    static func makeLoginResponse(username: String) -> LoginResponse {
        LoginResponse(token: "mock-jwt-token-\(username)-\(UUID().uuidString)")
    }

    static func makeUserProfile() -> UserProfile {
        MockSeedData.demoProfile
    }

    static func makeHomeDashboard() -> HomeDashboard {
        MockSeedData.dashboard
    }

    static func makeCommunityPosts(sort: CommunityFeedSort) -> [CommunityPost] {
        switch sort {
        case .hot:
            return MockSeedData.communityHotPosts
        case .latest:
            return MockSeedData.communityLatestPosts
        }
    }

    static func makeCommunityTopic(topicID: String) -> CommunityTopic {
        MockSeedData.communityTopic(topicID: topicID)
    }

    static func makeCommunityPostContent(postID: String) -> String {
        MockSeedData.communityPostContent(postID: postID)
    }

    static func makeWeeklySchedule(weekIndex: Int) -> WeeklySchedule {
        MockSeedData.weeklySchedule(weekIndex: weekIndex)
    }

    static func makeGradeReport(academicYear: String) -> GradeReport {
        MockSeedData.gradeReport(academicYear: academicYear)
    }

    static func makeCardDashboard(isLoss: Bool, queryDate: Date) -> CampusCardDashboard {
        MockSeedData.cardDashboard(isLoss: isLoss, queryDate: queryDate)
    }

    static func makeLibraryBooks(keyword: String) -> [LibraryBook] {
        let trimmedKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKeyword.isEmpty else { return MockSeedData.libraryBooks }

        return MockSeedData.libraryBooks.filter {
            $0.title.localizedCaseInsensitiveContains(trimmedKeyword) ||
            $0.author.localizedCaseInsensitiveContains(trimmedKeyword)
        }
    }

    static func makeLibraryBookDetail(bookID: String) -> LibraryBookDetail {
        MockSeedData.libraryBookDetail(bookID: bookID)
    }

    static func makeBorrowRecords(renewedRecordIDs: Set<String>) -> [BorrowRecord] {
        MockSeedData.borrowRecords(renewedRecordIDs: renewedRecordIDs)
    }

    static func makeCETDashboard(ticketNumber: String = MockSeedData.cetDashboard.profile.admissionTicket, candidateName: String = MockSeedData.cetDashboard.profile.candidateName) -> CETDashboard {
        MockSeedData.cetDashboard(ticketNumber: ticketNumber, candidateName: candidateName)
    }
}
