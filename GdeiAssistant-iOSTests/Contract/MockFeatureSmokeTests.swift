import XCTest
@testable import GdeiAssistant_iOS

@MainActor
final class MockFeatureSmokeTests: XCTestCase {
    func testHomeCommonServicesKeepAuditedOrderAndPickupDestination() {
        XCTAssertEqual(HomeEntryConfig.commonEntries.map(\.destination), [.card, .grade, .library, .delivery])
        XCTAssertFalse(HomeEntryConfig.commonEntries.contains { $0.destination == .express })
    }

    func testHomeAllFunctionsRetainsOriginalSeventeenDestinationsAndGroups() {
        XCTAssertEqual(HomeEntryConfig.allSections.map(\.section), [.campusServices, .campusLife])
        XCTAssertEqual(HomeEntryConfig.campusServices.map(\.destination), [
            .grade, .schedule, .cet, .graduateExam, .spare, .library, .card, .dataCenter, .evaluate
        ])
        XCTAssertEqual(HomeEntryConfig.campusLife.map(\.destination), [
            .marketplace, .delivery, .lostFound, .secret, .dating, .express, .topic, .photograph
        ])
        XCTAssertEqual(Set(HomeEntryConfig.allEntries.map(\.destination)).count, 17)
    }

    func testHomeDateLabelUsesCampusDayAndWeekdayWithoutYear() throws {
        let date = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-10-12T19:35:00Z"))
        let label = HomeViewModel.campusDateDescription(on: date, locale: Locale(identifier: "en_US"))
        XCTAssertTrue(label.contains("Tuesday"), label)
        XCTAssertTrue(label.contains("13"), label)
        XCTAssertFalse(label.contains("2026"), label)
    }

    func testHomeTodayCoursesUsesCampusDayCurrentWeekAndSectionOrder() throws {
        let mondayInShanghai = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-10-11T16:30:00Z"))
        let courses = [
            homeCourse("later", day: 1, section: 5, weeks: [8]),
            homeCourse("wrong-week", day: 1, section: 1, weeks: [7]),
            homeCourse("early", day: 1, section: 1, weeks: [8]),
            homeCourse("all-weeks", day: 1, section: 3, weeks: []),
            homeCourse("sunday", day: 7, section: 1, weeks: [8])
        ]
        let schedule = homeSchedule(courses)
        XCTAssertEqual(HomeViewModel.todayCourses(in: schedule, on: mondayInShanghai).map(\.id), ["early", "all-weeks", "later"])

        let sundayInShanghai = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-10-10T16:30:00Z"))
        XCTAssertEqual(HomeViewModel.todayCourses(in: schedule, on: sundayInShanghai).map(\.id), ["sunday"])
    }

    func testHomeTodayScheduleFailureIsSeparateFromEmptyAndCanRecover() async throws {
        let date = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-10-11T16:30:00Z"))
        let repository = HomeScheduleStub(schedule: homeSchedule([]))
        repository.shouldFail = true
        let model = HomeViewModel(repository: HomeDashboardStub(), scheduleRepository: repository, now: { date })
        await model.loadTodaySchedule()
        XCTAssertTrue(model.scheduleLoadFailed)
        XCTAssertNil(model.currentSchedule)
        XCTAssertFalse(model.isScheduleLoading)

        repository.shouldFail = false
        await model.loadTodaySchedule()
        XCTAssertFalse(model.scheduleLoadFailed)
        XCTAssertNotNil(model.currentSchedule)
        XCTAssertTrue(model.todayCourses.isEmpty)
        XCTAssertEqual(repository.currentRequests, 2)
        XCTAssertEqual(repository.requestedWeeks, [])
    }

    func testHomeDashboardFailureKeepsLoadedTodayCoursesAndUsesCurrentWeekRequest() async throws {
        let date = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-10-11T16:30:00Z"))
        let repository = HomeScheduleStub(schedule: homeSchedule([homeCourse("today", day: 1, section: 1, weeks: [8])]))
        let model = HomeViewModel(repository: HomeDashboardStub(shouldFail: true), scheduleRepository: repository, now: { date })
        await model.loadIfNeeded()
        XCTAssertNotNil(model.errorMessage)
        XCTAssertNil(model.dashboard)
        XCTAssertEqual(model.todayCourses.map(\.id), ["today"])
        XCTAssertFalse(model.scheduleLoadFailed)
        XCTAssertEqual(repository.currentRequests, 1)
        XCTAssertEqual(repository.requestedWeeks, [])
    }

    func testHomeDropsOutdatedScheduleResponseAfterRefresh() async {
        let old = homeSchedule([homeCourse("old", day: 1, section: 1, weeks: [8])])
        let new = homeSchedule([homeCourse("new", day: 1, section: 1, weeks: [8])])
        let repository = HomeScheduleStub(schedule: new)
        repository.suspendRequestAt = 1
        let model = HomeViewModel(repository: HomeDashboardStub(), scheduleRepository: repository)
        let first = Task { await model.loadTodaySchedule() }
        await repository.waitForFirstRequest()
        await model.loadTodaySchedule()
        repository.suspendedFirstRequest?.resume(returning: old)
        await first.value
        XCTAssertEqual(model.currentSchedule?.days.flatMap(\.courses).map(\.id), ["new"])
        XCTAssertFalse(model.isScheduleLoading)
    }

    func testHomeRefetchesWhenResponseCrossesCampusMidnight() async throws {
        let sunday = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-10-11T15:59:59Z"))
        let monday = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-10-11T16:00:01Z"))
        let clock = HomeClock(date: sunday)
        let repository = HomeScheduleStub(schedule: homeSchedule([homeCourse("monday", day: 1, section: 1, weeks: [8])]))
        repository.onFirstCurrentRequest = { clock.date = monday }
        let model = HomeViewModel(repository: HomeDashboardStub(), scheduleRepository: repository, now: { clock.date })
        await model.loadTodaySchedule()
        XCTAssertEqual(repository.currentRequests, 2)
        XCTAssertEqual(model.todayCourses.map(\.id), ["monday"])
        XCTAssertFalse(model.isScheduleLoading)
        XCTAssertFalse(model.scheduleLoadFailed)
    }

    func testHomeCancelledScheduleCanReloadWithoutShowingFailure() async {
        let repository = HomeScheduleStub(schedule: homeSchedule([]))
        let model = HomeViewModel(repository: HomeDashboardStub(), scheduleRepository: repository)
        await model.loadTodaySchedule()
        repository.suspendRequestAt = 2
        let first = Task { await model.loadTodaySchedule() }
        await repository.waitForFirstRequest()
        first.cancel()
        repository.suspendedFirstRequest?.resume(returning: homeSchedule([]))
        await first.value
        XCTAssertFalse(model.scheduleLoadFailed)
        XCTAssertNil(model.currentSchedule)
        XCTAssertFalse(model.isScheduleLoading)
        await model.loadIfNeeded()
        XCTAssertNotNil(model.currentSchedule)
        XCTAssertEqual(repository.currentRequests, 3)
    }

    func testRemoteCurrentScheduleOmitsWeekQueryAndRejectsUnknownWeek() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [HomeScheduleURLProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        let environment = AppEnvironment(networkEnvironment: .prod, dataSourceMode: .remote, isDebug: false, clientType: "IOS")
        environment.baseURL = try XCTUnwrap(URL(string: "https://synthetic.example"))
        let apiClient = APIClient(environment: environment, session: session, tokenProvider: { nil }, onUnauthorized: {})
        let repository = RemoteScheduleRepository(apiClient: apiClient)
        HomeScheduleURLProtocol.body = #"{"success":true,"data":{"week":8,"scheduleList":[]}}"#
        HomeScheduleURLProtocol.requestedURL = nil
        let schedule = try await repository.fetchCurrentWeeklySchedule()
        XCTAssertEqual(schedule.weekIndex, 8)
        let url = try XCTUnwrap(HomeScheduleURLProtocol.requestedURL)
        XCTAssertEqual(url.path, "/schedule")
        XCTAssertFalse(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.contains(where: { $0.name == "week" }) ?? false)

        HomeScheduleURLProtocol.body = #"{"success":true,"data":{"scheduleList":[]}}"#
        do {
            _ = try await repository.fetchCurrentWeeklySchedule()
            XCTFail("Missing current week must not become a fabricated current-week schedule")
        } catch {
            // Expected: the home card must show unavailable, not an empty guessed week.
        }
        HomeScheduleURLProtocol.body = ""
        HomeScheduleURLProtocol.requestedURL = nil
    }

    func testRemoteCurrentScheduleRejectsIncompleteCourseMetadata() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [HomeScheduleURLProtocol.self]
        let session = URLSession(configuration: configuration)
        defer {
            session.invalidateAndCancel()
            HomeScheduleURLProtocol.body = ""
            HomeScheduleURLProtocol.requestedURL = nil
        }
        let environment = AppEnvironment(networkEnvironment: .prod, dataSourceMode: .remote, isDebug: false, clientType: "IOS")
        environment.baseURL = try XCTUnwrap(URL(string: "https://synthetic.example"))
        let apiClient = APIClient(environment: environment, session: session, tokenProvider: { nil }, onUnauthorized: {})
        let repository = RemoteScheduleRepository(apiClient: apiClient)
        let complete: [String: Any] = [
            "scheduleName": "Synthetic", "column": 0, "row": 2, "scheduleLength": 2,
            "minScheduleWeek": 1, "maxScheduleWeek": 16, "scheduleWeek": "第1周至第16周"
        ]
        for missingKey in ["column", "row", "scheduleLength", "minScheduleWeek", "maxScheduleWeek", "scheduleName"] {
            var incomplete = complete
            incomplete.removeValue(forKey: missingKey)
            HomeScheduleURLProtocol.body = String(decoding: try JSONSerialization.data(withJSONObject: [
                "success": true, "data": ["week": 8, "scheduleList": [incomplete]]
            ]), as: UTF8.self)
            do {
                _ = try await repository.fetchCurrentWeeklySchedule()
                XCTFail("Missing \(missingKey) must be unavailable rather than a fabricated course")
            } catch {
                // Expected: current-home mapping needs actual day, sections and week bounds.
            }
        }
    }

    func testRemoteCurrentScheduleUsesActualGridSectionsAndWeekBoundsWithoutLocationFallback() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [HomeScheduleURLProtocol.self]
        let session = URLSession(configuration: configuration)
        defer {
            session.invalidateAndCancel()
            HomeScheduleURLProtocol.body = ""
            HomeScheduleURLProtocol.requestedURL = nil
        }
        let environment = AppEnvironment(networkEnvironment: .prod, dataSourceMode: .remote, isDebug: false, clientType: "IOS")
        environment.baseURL = try XCTUnwrap(URL(string: "https://synthetic.example"))
        let apiClient = APIClient(environment: environment, session: session, tokenProvider: { nil }, onUnauthorized: {})
        let repository = RemoteScheduleRepository(apiClient: apiClient)
        HomeScheduleURLProtocol.body = #"{"success":true,"data":{"week":8,"scheduleList":[{"id":"synthetic","scheduleName":"Synthetic","column":0,"row":2,"scheduleLength":2,"scheduleLesson":"周一第3,4节","minScheduleWeek":1,"maxScheduleWeek":16,"scheduleWeek":"第1周至第16周"}]}}"#
        let schedule = try await repository.fetchCurrentWeeklySchedule()
        let course = try XCTUnwrap(schedule.days.flatMap(\.courses).first)
        XCTAssertEqual(course.dayOfWeek, 1)
        XCTAssertEqual(course.startSection, 3)
        XCTAssertEqual(course.endSection, 4)
        XCTAssertEqual(course.weekIndices, Array(1...16))
        XCTAssertEqual(course.location, "")
        let monday = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-10-11T16:30:00Z"))
        XCTAssertEqual(HomeViewModel.todayCourses(in: schedule, on: monday).map(\.id), ["synthetic"])
    }

    private func homeCourse(_ id: String, day: Int, section: Int, weeks: [Int]) -> CourseItem {
        CourseItem(id: id, courseName: id, teacherName: "Synthetic", location: "Synthetic", dayOfWeek: day, startSection: section, endSection: section + 1, weekIndices: weeks)
    }

    private func homeSchedule(_ courses: [CourseItem]) -> WeeklySchedule {
        WeeklySchedule(weekIndex: 8, termName: "Synthetic", days: [CourseDaySection(dayOfWeek: 1, dayTitle: "Synthetic", dateText: "", courses: courses)])
    }

    func testGradeYearIsAnIndexAndCourseKeepsActualAcademicYear() throws {
        let json = #"{"year":2,"firstTermGradeList":[{"gradeId":"synthetic","gradeYear":"2023-2024","gradeTerm":"1","gradeName":"Synthetic course","gradeScore":"90","gradeCredit":"2"}]}"#
        let dto = try JSONDecoder().decode(GradeQueryResultDTO.self, from: Data(json.utf8))
        let report = GradeRemoteMapper.mapReport(dto, requestedYearIndex: 1)
        XCTAssertEqual(report.selectedYear, "2")
        XCTAssertEqual(report.yearOptions.map(\.id), ["0", "1", "2", "3"])
        XCTAssertEqual(report.terms[0].items[0].term, "2023-2024-1")
    }

    func testGradeMissingYearDoesNotInventCalendarYearFromIndex() throws {
        let json = #"{"firstTermGradeList":[{"gradeId":"synthetic","gradeTerm":"1"}]}"#
        let dto = try JSONDecoder().decode(GradeQueryResultDTO.self, from: Data(json.utf8))
        let report = GradeRemoteMapper.mapReport(dto, requestedYearIndex: 3)
        XCTAssertEqual(report.selectedYear, "3")
        XCTAssertEqual(report.terms[0].items[0].term, "-1")
    }

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
        let gradeReport = try await MockGradeRepository().fetchGrades(yearIndex: 3)
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

        let socialRepository = MockSocialRepository()
        let me = try await socialRepository.fetchMe()
        XCTAssertEqual(me.relationship, .selfRelation)
        let searched = try await socialRepository.searchUsers(query: "", cursor: nil, limit: 10)
        XCTAssertFalse(searched.items.isEmpty)
        let conversations = try await socialRepository.fetchConversations(cursor: nil, limit: 10)
        XCTAssertFalse(conversations.items.isEmpty)
        let privacy = try await socialRepository.fetchPrivacy()
        XCTAssertEqual(privacy.dmPolicy, .mutual)
        let unread = try await socialRepository.fetchUnreadCount()
        XCTAssertGreaterThanOrEqual(unread.total, 0)
    }
}

@MainActor
private final class HomeClock {
    var date: Date
    init(date: Date) { self.date = date }
}

private enum HomeTestError: Error { case unavailable }

@MainActor
private final class HomeDashboardStub: HomeRepository {
    let shouldFail: Bool
    init(shouldFail: Bool = false) { self.shouldFail = shouldFail }

    func fetchDashboard() async throws -> HomeDashboard {
        if shouldFail { throw HomeTestError.unavailable }
        return HomeDashboard(greeting: "", reminderText: "", quickActions: [], recentItems: [], campusBannerTitle: "", trendingTopics: [])
    }
}

@MainActor
private final class HomeScheduleStub: ScheduleRepository {
    let schedule: WeeklySchedule
    var shouldFail = false
    var currentRequests = 0
    var requestedWeeks: [Int] = []
    var onFirstCurrentRequest: (() -> Void)?
    var suspendRequestAt: Int?
    var suspendedFirstRequest: CheckedContinuation<WeeklySchedule, Error>?
    private var requestStarted: CheckedContinuation<Void, Never>?

    init(schedule: WeeklySchedule) { self.schedule = schedule }

    func fetchWeeklySchedule(weekIndex: Int) async throws -> WeeklySchedule {
        requestedWeeks.append(weekIndex)
        return schedule
    }

    func fetchCurrentWeeklySchedule() async throws -> WeeklySchedule {
        currentRequests += 1
        if shouldFail { throw HomeTestError.unavailable }
        if currentRequests == 1 {
            onFirstCurrentRequest?()
        }
        if currentRequests == suspendRequestAt {
            return try await withCheckedThrowingContinuation { continuation in
                suspendedFirstRequest = continuation
                requestStarted?.resume()
                requestStarted = nil
            }
        }
        return schedule
    }

    func waitForFirstRequest() async {
        if suspendedFirstRequest != nil { return }
        await withCheckedContinuation { requestStarted = $0 }
    }
}

private final class HomeScheduleURLProtocol: URLProtocol {
    static var body = ""
    static var requestedURL: URL?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url,
              let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil) else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        Self.requestedURL = url
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(Self.body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
