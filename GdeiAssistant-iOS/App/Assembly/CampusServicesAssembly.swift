import Foundation

/// Owns repository construction for campus service features:
/// schedule, grade, card, library, CET, evaluate, spare, graduate exam,
/// news, and data center.
struct CampusServicesAssembly {
    let scheduleRepository: any ScheduleRepository
    let gradeRepository: any GradeRepository
    let cardRepository: any CardRepository
    let chargeRepository: any ChargeRepository
    let libraryRepository: any LibraryRepository
    let cetRepository: any CETRepository
    let evaluateRepository: any EvaluateRepository
    let spareRepository: any SpareRepository
    let graduateExamRepository: any GraduateExamRepository
    let newsRepository: any NewsRepository
    let dataCenterRepository: any DataCenterRepository

    init(apiClient: APIClient, environment: AppEnvironment) {
        let remoteScheduleRepository = RemoteScheduleRepository(apiClient: apiClient)
        let mockScheduleRepository = MockScheduleRepository()
        self.scheduleRepository = SwitchingScheduleRepository(
            environment: environment,
            remoteRepository: remoteScheduleRepository,
            mockRepository: mockScheduleRepository
        )

        let remoteGradeRepository = RemoteGradeRepository(apiClient: apiClient)
        let mockGradeRepository = MockGradeRepository()
        self.gradeRepository = SwitchingGradeRepository(
            environment: environment,
            remoteRepository: remoteGradeRepository,
            mockRepository: mockGradeRepository
        )

        let remoteCardRepository = RemoteCardRepository(apiClient: apiClient)
        let mockCardRepository = MockCardRepository()
        self.cardRepository = SwitchingCardRepository(
            environment: environment,
            remoteRepository: remoteCardRepository,
            mockRepository: mockCardRepository
        )

        let remoteChargeRepository = RemoteChargeRepository(apiClient: apiClient)
        let mockChargeRepository = MockChargeRepository()
        self.chargeRepository = SwitchingChargeRepository(
            environment: environment,
            remoteRepository: remoteChargeRepository,
            mockRepository: mockChargeRepository
        )

        let remoteLibraryRepository = RemoteLibraryRepository(apiClient: apiClient)
        let mockLibraryRepository = MockLibraryRepository()
        self.libraryRepository = SwitchingLibraryRepository(
            environment: environment,
            remoteRepository: remoteLibraryRepository,
            mockRepository: mockLibraryRepository
        )

        let remoteCETRepository = RemoteCETRepository(apiClient: apiClient)
        let mockCETRepository = MockCETRepository()
        self.cetRepository = SwitchingCETRepository(
            environment: environment,
            remoteRepository: remoteCETRepository,
            mockRepository: mockCETRepository
        )

        let remoteEvaluateRepository = RemoteEvaluateRepository(apiClient: apiClient)
        let mockEvaluateRepository = MockEvaluateRepository()
        self.evaluateRepository = SwitchingEvaluateRepository(
            environment: environment,
            remoteRepository: remoteEvaluateRepository,
            mockRepository: mockEvaluateRepository
        )

        let remoteSpareRepository = RemoteSpareRepository(apiClient: apiClient)
        let mockSpareRepository = MockSpareRepository()
        self.spareRepository = SwitchingSpareRepository(
            environment: environment,
            remoteRepository: remoteSpareRepository,
            mockRepository: mockSpareRepository
        )

        let remoteGraduateExamRepository = RemoteGraduateExamRepository(apiClient: apiClient)
        let mockGraduateExamRepository = MockGraduateExamRepository()
        self.graduateExamRepository = SwitchingGraduateExamRepository(
            environment: environment,
            remoteRepository: remoteGraduateExamRepository,
            mockRepository: mockGraduateExamRepository
        )

        let remoteNewsRepository = RemoteNewsRepository(apiClient: apiClient)
        let mockNewsRepository = MockNewsRepository()
        self.newsRepository = SwitchingNewsRepository(
            environment: environment,
            remoteRepository: remoteNewsRepository,
            mockRepository: mockNewsRepository
        )

        let remoteDataCenterRepository = RemoteDataCenterRepository(apiClient: apiClient)
        let mockDataCenterRepository = MockDataCenterRepository()
        self.dataCenterRepository = SwitchingDataCenterRepository(
            environment: environment,
            remoteRepository: remoteDataCenterRepository,
            mockRepository: mockDataCenterRepository
        )
    }

    // MARK: - ViewModel Factories

    func makeScheduleViewModel() -> ScheduleViewModel {
        ScheduleViewModel(repository: scheduleRepository)
    }

    func makeGradeViewModel() -> GradeViewModel {
        GradeViewModel(repository: gradeRepository)
    }

    func makeCardViewModel() -> CardViewModel {
        CardViewModel(repository: cardRepository)
    }

    func makeChargeViewModel() -> ChargeViewModel {
        ChargeViewModel(repository: chargeRepository)
    }

    func makeLibraryViewModel() -> LibraryViewModel {
        LibraryViewModel(repository: libraryRepository)
    }

    func makeCETViewModel() -> CETViewModel {
        CETViewModel(repository: cetRepository)
    }

    func makeEvaluateViewModel() -> EvaluateViewModel {
        EvaluateViewModel(repository: evaluateRepository)
    }

    func makeSpareViewModel() -> SpareViewModel {
        SpareViewModel(repository: spareRepository)
    }

    func makeGraduateExamViewModel() -> GraduateExamViewModel {
        GraduateExamViewModel(repository: graduateExamRepository)
    }

    func makeNewsViewModel() -> NewsViewModel {
        NewsViewModel(repository: newsRepository)
    }
}
