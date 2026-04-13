import XCTest
@testable import GdeiAssistant_iOS

@MainActor
final class MockFeatureSmokeTests: XCTestCase {
    func testTopicMultipartFilesUseBackendArrayFieldName() {
        let files = TopicRemoteMapper.multipartFiles(from: [
            UploadImageAsset(
                fileName: "topic.jpg",
                mimeType: "image/jpeg",
                data: Data("topic".utf8)
            )
        ])

        XCTAssertEqual(files.map(\.name), ["images"])
    }

    func testAccountAndInformationMockFlows() async throws {
        let authRepository = MockAuthRepository()
        let login = try await authRepository.login(request: LoginRequest(username: "gdeiassistant", password: "gdeiassistant"))
        XCTAssertFalse(login.token.isEmpty)

        let profile = try await authRepository.fetchProfile()
        XCTAssertFalse(profile.username.isEmpty)

        let home = try await MockHomeRepository().fetchDashboard()
        XCTAssertFalse(home.quickActions.isEmpty)

        let profileRepository = MockProfileRepository()
        let currentProfile = try await profileRepository.fetchProfile()
        XCTAssertFalse(currentProfile.nickname.isEmpty)
        let locations = try await profileRepository.fetchLocationRegions()
        XCTAssertFalse(locations.isEmpty)
        let options = try await profileRepository.fetchProfileOptions()
        XCTAssertFalse(options.faculties.isEmpty)

        let accountRepository = MockAccountCenterRepository()
        let privacy = try await accountRepository.fetchPrivacySettings()
        let updatedPrivacy = try await accountRepository.updatePrivacySettings(privacy)
        XCTAssertEqual(updatedPrivacy.cacheAllow, privacy.cacheAllow)
        let loginRecords = try await accountRepository.fetchLoginRecords()
        XCTAssertFalse(loginRecords.isEmpty)
        let phoneAttributions = try await accountRepository.fetchPhoneAttributions()
        XCTAssertFalse(phoneAttributions.isEmpty)
        let phoneStatus = try await accountRepository.fetchPhoneStatus()
        XCTAssertNotNil(phoneStatus.maskedValue)
        let emailStatus = try await accountRepository.fetchEmailStatus()
        XCTAssertNotNil(emailStatus.maskedValue)
        let downloadStatus = try await accountRepository.fetchDownloadStatus()
        XCTAssertEqual(downloadStatus.state, .idle)
        let avatarState = try await accountRepository.fetchAvatarState()
        XCTAssertNotNil(avatarState.url)

        let messagesRepository = MockMessagesRepository()
        let announcements = try await messagesRepository.fetchAnnouncementPage(start: 0, size: 10)
        XCTAssertFalse(announcements.isEmpty)
        let announcementID = announcements[0].targetID ?? announcements[0].id
        let announcementDetail = try await messagesRepository.fetchAnnouncementDetail(id: announcementID)
        XCTAssertEqual(announcementDetail.id, announcementID)
        XCTAssertFalse(announcementDetail.title.isEmpty)

        let interactions = try await messagesRepository.fetchInteractionNotifications(start: 0, size: 10)
        XCTAssertFalse(interactions.isEmpty)
        let unreadBefore = try await messagesRepository.fetchInteractionUnreadCount()
        try await messagesRepository.markNotificationRead(notificationID: interactions[0].id)
        let unreadAfterSingleRead = try await messagesRepository.fetchInteractionUnreadCount()
        XCTAssertLessThanOrEqual(unreadAfterSingleRead, unreadBefore)
        try await messagesRepository.markAllNotificationsRead()
        let unreadAfterReadAll = try await messagesRepository.fetchInteractionUnreadCount()
        XCTAssertEqual(unreadAfterReadAll, 0)
        let festival = try await messagesRepository.fetchFestival()
        XCTAssertFalse(festival?.name.isEmpty ?? true)

        let newsRepository = MockNewsRepository()
        let news = try await newsRepository.fetchNews(start: 0, size: 10)
        XCTAssertFalse(news.isEmpty)
        let newsDetail = try await newsRepository.fetchNewsDetail(id: news[0].id)
        XCTAssertEqual(newsDetail.id, news[0].id)
    }

    func testAcademicAndCampusMockFlows() async throws {
        let gradeReport = try await MockGradeRepository().fetchGrades(academicYear: "2025-2026")
        XCTAssertFalse(gradeReport.terms.isEmpty)

        let schedule = try await MockScheduleRepository().fetchWeeklySchedule(weekIndex: 6)
        XCTAssertFalse(schedule.days.isEmpty)

        let cetRepository = MockCETRepository()
        let captcha = try await cetRepository.fetchCaptchaImageBase64()
        XCTAssertTrue(captcha.count > 20)
        let cetDashboard = try await cetRepository.queryScore(
            request: CETScoreQueryRequest(ticketNumber: "123456789012345", name: "林知远", captchaCode: "gd26")
        )
        XCTAssertFalse(cetDashboard.scoreRecords.isEmpty)

        let spareRooms = try await MockSpareRepository().queryRooms(
            SpareQuery(zone: 0, type: 0, startTime: 1, endTime: 2, minWeek: 0, maxWeek: 0, weekType: 0, classNumber: 1, minSeating: nil, maxSeating: nil)
        )
        XCTAssertFalse(spareRooms.isEmpty)

        let graduateExam = try await MockGraduateExamRepository().queryScore(
            GraduateExamQuery(name: "林知远", examNumber: "441526010203", idNumber: "440101200409160011")
        )
        XCTAssertFalse(graduateExam.totalScore.isEmpty)

        let cardRepository = MockCardRepository()
        let dashboardBeforeLoss = try await cardRepository.fetchDashboard(on: Date())
        XCTAssertEqual(dashboardBeforeLoss.info.status, .normal)
        try await cardRepository.reportLoss(request: CardLossRequest(cardPassword: "246810"))
        let dashboardAfterLoss = try await cardRepository.fetchDashboard(on: Date())
        XCTAssertEqual(dashboardAfterLoss.info.status, .lost)

        let libraryRepository = MockLibraryRepository()
        let libraryBooks = try await libraryRepository.searchBooks(keyword: "Swift", page: 1)
        XCTAssertFalse(libraryBooks.isEmpty)
        let libraryBookDetail = try await libraryRepository.fetchBookDetail(bookID: libraryBooks[0].id)
        XCTAssertEqual(libraryBookDetail.id, libraryBooks[0].id)
        let borrowRecords = try await libraryRepository.fetchBorrowRecords(password: "library123")
        XCTAssertFalse(borrowRecords.isEmpty)
        try await libraryRepository.renewBorrow(
            request: LibraryRenewRequest(
                sn: borrowRecords[0].sn ?? "sn_1001",
                code: borrowRecords[0].code ?? "code_1001",
                password: "library123"
            )
        )

        let collectionRepository = MockCollectionRepository()
        let collectionSearch = try await collectionRepository.search(keyword: "Swift", page: 1)
        XCTAssertFalse(collectionSearch.items.isEmpty)
        let collectionDetail = try await collectionRepository.fetchDetail(detailURL: collectionSearch.items[0].detailURL)
        XCTAssertEqual(collectionDetail.id, collectionSearch.items[0].detailURL)
        let collectionBorrowed = try await collectionRepository.fetchBorrowedBooks(password: "library123")
        XCTAssertFalse(collectionBorrowed.isEmpty)
        try await collectionRepository.renewBorrow(
            sn: collectionBorrowed[0].sn,
            code: collectionBorrowed[0].code,
            password: "library123"
        )

        let chargeRepository = MockChargeRepository()
        let chargeCardInfo = try await chargeRepository.fetchCardInfo()
        XCTAssertFalse(chargeCardInfo.info.cardNumber.isEmpty)
        let chargePayment = try await chargeRepository.submitCharge(amount: 50, password: "charge123")
        XCTAssertTrue(chargePayment.alipayURL.contains("mockCharge=50"))

        let dataCenterRepository = MockDataCenterRepository()
        let electricity = try await dataCenterRepository.queryElectricity(
            ElectricityQuery(year: 2026, name: "林知远", studentNumber: "20231234567")
        )
        XCTAssertFalse(electricity.totalElectricBill.isEmpty)
        let yellowPages = try await dataCenterRepository.fetchYellowPages()
        XCTAssertFalse(yellowPages.isEmpty)

        try await MockEvaluateRepository().submit(EvaluateSubmission(directSubmit: true))
    }

    func testCommunityMockFlows() async throws {
        let communityRepository = MockCommunityRepository()
        let communityPosts = try await communityRepository.fetchPosts(sort: .hot)
        XCTAssertFalse(communityPosts.isEmpty)
        let communityDetail = try await communityRepository.fetchPostDetail(postID: communityPosts[0].id)
        XCTAssertEqual(communityDetail.post.id, communityPosts[0].id)
        _ = try await communityRepository.fetchComments(postID: communityPosts[0].id)

        let marketplaceRepository = MockMarketplaceRepository()
        let marketplaceItems = try await marketplaceRepository.fetchItems(typeID: nil)
        XCTAssertFalse(marketplaceItems.isEmpty)
        let marketplaceDetail = try await marketplaceRepository.fetchItemDetail(itemID: marketplaceItems[0].id)
        XCTAssertEqual(marketplaceDetail.item.id, marketplaceItems[0].id)
        let marketplaceSummary = try await marketplaceRepository.fetchMySummary()
        XCTAssertFalse(marketplaceSummary.doing.isEmpty || marketplaceSummary.sold.isEmpty && marketplaceSummary.off.isEmpty)

        let lostFoundRepository = MockLostFoundRepository()
        let lostFoundItems = try await lostFoundRepository.fetchItems()
        XCTAssertFalse(lostFoundItems.isEmpty)
        let lostFoundDetail = try await lostFoundRepository.fetchDetail(itemID: lostFoundItems[0].id)
        XCTAssertEqual(lostFoundDetail.item.id, lostFoundItems[0].id)
        let lostFoundSummary = try await lostFoundRepository.fetchMySummary()
        XCTAssertFalse(lostFoundSummary.lost.isEmpty || lostFoundSummary.found.isEmpty && lostFoundSummary.didFound.isEmpty)

        let secretRepository = MockSecretRepository()
        let secrets = try await secretRepository.fetchPosts()
        XCTAssertFalse(secrets.isEmpty)
        let secretDetail = try await secretRepository.fetchDetail(postID: secrets[0].id)
        XCTAssertEqual(secretDetail.post.id, secrets[0].id)
        try await secretRepository.submitComment(postID: secrets[0].id, content: "mock smoke")
        try await secretRepository.setLike(postID: secrets[0].id, liked: true)

        let datingRepository = MockDatingRepository()
        let datingProfiles = try await datingRepository.fetchProfiles(filter: DatingFilter(area: .girl))
        XCTAssertFalse(datingProfiles.isEmpty)
        let datingDetail = try await datingRepository.fetchProfileDetail(profileID: datingProfiles[0].id)
        XCTAssertEqual(datingDetail.profile.id, datingProfiles[0].id)
        let receivedPicks = try await datingRepository.fetchReceivedPicks()
        XCTAssertFalse(receivedPicks.isEmpty)
        let sentPicks = try await datingRepository.fetchSentPicks()
        XCTAssertFalse(sentPicks.isEmpty)
        let myPosts = try await datingRepository.fetchMyPosts()
        XCTAssertFalse(myPosts.isEmpty)

        let expressRepository = MockExpressRepository()
        let expressPosts = try await expressRepository.fetchPosts(start: 0, size: 10)
        XCTAssertFalse(expressPosts.isEmpty)
        let expressDetail = try await expressRepository.fetchDetail(postID: expressPosts[0].id)
        XCTAssertEqual(expressDetail.post.id, expressPosts[0].id)
        _ = try await expressRepository.fetchComments(postID: expressPosts[0].id)
        try await expressRepository.like(postID: expressPosts[0].id)

        let topicRepository = MockTopicRepository()
        let topicPosts = try await topicRepository.fetchPosts(start: 0, size: 10)
        XCTAssertFalse(topicPosts.isEmpty)
        let topicDetail = try await topicRepository.fetchDetail(postID: topicPosts[0].id)
        XCTAssertEqual(topicDetail.post.id, topicPosts[0].id)
        try await topicRepository.like(postID: topicPosts[0].id)

        let deliveryRepository = MockDeliveryRepository()
        let deliveryOrders = try await deliveryRepository.fetchOrders(start: 0, size: 10)
        XCTAssertFalse(deliveryOrders.isEmpty)
        let deliveryDetail = try await deliveryRepository.fetchDetail(orderID: deliveryOrders[0].orderID)
        XCTAssertEqual(deliveryDetail.order.orderID, deliveryOrders[0].orderID)
        let deliverySummary = try await deliveryRepository.fetchMine()
        XCTAssertFalse(deliverySummary.published.isEmpty)

        let photographRepository = MockPhotographRepository()
        let photographStats = try await photographRepository.fetchStats()
        XCTAssertGreaterThanOrEqual(photographStats.photoCount, 0)
        let photographPosts = try await photographRepository.fetchPosts(category: .campus, start: 0, size: 10)
        XCTAssertFalse(photographPosts.isEmpty)
        let photographDetail = try await photographRepository.fetchDetail(postID: photographPosts[0].id)
        XCTAssertEqual(photographDetail.post.id, photographPosts[0].id)
        _ = try await photographRepository.fetchComments(postID: photographPosts[0].id)
        try await photographRepository.like(postID: photographPosts[0].id)

        let messages = try await MockMessagesRepository().fetchInteractionNotifications(start: 0, size: 10)
        XCTAssertFalse(messages.isEmpty)
    }
}
