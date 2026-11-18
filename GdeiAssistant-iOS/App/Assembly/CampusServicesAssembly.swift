import Foundation

/// Owns repository construction for campus service features:
/// schedule, grade, card, library, CET, evaluate, spare, graduate exam,
/// news, and data center.
@MainActor
struct CampusServicesAssembly {
    private let environment: AppEnvironment
    private let remoteScheduleRepository: RemoteScheduleRepository
    private let remoteGradeRepository: RemoteGradeRepository
    private let remoteCardRepository: RemoteCardRepository
    private let remoteChargeRepository: RemoteChargeRepository
    private let remoteLibraryRepository: RemoteLibraryRepository
    private let remoteCETRepository: RemoteCETRepository
    private let remoteEvaluateRepository: RemoteEvaluateRepository
    private let remoteSpareRepository: RemoteSpareRepository
    private let remoteGraduateExamRepository: RemoteGraduateExamRepository
    private let remoteNewsRepository: RemoteNewsRepository
    private let remoteDataCenterRepository: RemoteDataCenterRepository
    #if DEBUG
    private let mockScheduleRepository: MockScheduleRepository
    private let mockGradeRepository: MockGradeRepository
    private let mockCardRepository: MockCardRepository
    private let mockChargeRepository: MockChargeRepository
    private let mockLibraryRepository: MockLibraryRepository
    private let mockCETRepository: MockCETRepository
    private let mockEvaluateRepository: MockEvaluateRepository
    private let mockSpareRepository: MockSpareRepository
    private let mockGraduateExamRepository: MockGraduateExamRepository
    private let mockNewsRepository: MockNewsRepository
    private let mockDataCenterRepository: MockDataCenterRepository
    #endif

    func scheduleRepository(for mode: DataSourceMode) -> any ScheduleRepository {
        #if DEBUG
        return mode == .mock ? mockScheduleRepository : remoteScheduleRepository
        #else
        return remoteScheduleRepository
        #endif
    }

    var scheduleRepository: any ScheduleRepository {
        scheduleRepository(for: environment.dataSourceMode)
    }
    var gradeRepository: any GradeRepository {
        #if DEBUG
        return environment.dataSourceMode == .mock ? mockGradeRepository : remoteGradeRepository
        #else
        return remoteGradeRepository
        #endif
    }
    var cardRepository: any CardRepository {
        #if DEBUG
        return environment.dataSourceMode == .mock ? mockCardRepository : remoteCardRepository
        #else
        return remoteCardRepository
        #endif
    }
    var chargeRepository: any ChargeRepository {
        #if DEBUG
        return environment.dataSourceMode == .mock ? mockChargeRepository : remoteChargeRepository
        #else
        return remoteChargeRepository
        #endif
    }
    var libraryRepository: any LibraryRepository {
        #if DEBUG
        return environment.dataSourceMode == .mock ? mockLibraryRepository : remoteLibraryRepository
        #else
        return remoteLibraryRepository
        #endif
    }
    var cetRepository: any CETRepository {
        #if DEBUG
        return environment.dataSourceMode == .mock ? mockCETRepository : remoteCETRepository
        #else
        return remoteCETRepository
        #endif
    }
    var evaluateRepository: any EvaluateRepository {
        #if DEBUG
        return environment.dataSourceMode == .mock ? mockEvaluateRepository : remoteEvaluateRepository
        #else
        return remoteEvaluateRepository
        #endif
    }
    var spareRepository: any SpareRepository {
        #if DEBUG
        return environment.dataSourceMode == .mock ? mockSpareRepository : remoteSpareRepository
        #else
        return remoteSpareRepository
        #endif
    }
    var graduateExamRepository: any GraduateExamRepository {
        #if DEBUG
        return environment.dataSourceMode == .mock ? mockGraduateExamRepository : remoteGraduateExamRepository
        #else
        return remoteGraduateExamRepository
        #endif
    }
    func newsRepository(for mode: DataSourceMode) -> any NewsRepository {
        #if DEBUG
        return mode == .mock ? mockNewsRepository : remoteNewsRepository
        #else
        return remoteNewsRepository
        #endif
    }

    var newsRepository: any NewsRepository {
        newsRepository(for: environment.dataSourceMode)
    }
    var dataCenterRepository: any DataCenterRepository {
        #if DEBUG
        return environment.dataSourceMode == .mock ? mockDataCenterRepository : remoteDataCenterRepository
        #else
        return remoteDataCenterRepository
        #endif
    }

    init(apiClient: APIClient, environment: AppEnvironment) {
        self.environment = environment
        self.remoteScheduleRepository = RemoteScheduleRepository(apiClient: apiClient)
        self.remoteGradeRepository = RemoteGradeRepository(apiClient: apiClient)
        self.remoteCardRepository = RemoteCardRepository(apiClient: apiClient)
        self.remoteChargeRepository = RemoteChargeRepository(apiClient: apiClient)
        self.remoteLibraryRepository = RemoteLibraryRepository(apiClient: apiClient)
        self.remoteCETRepository = RemoteCETRepository(apiClient: apiClient)
        self.remoteEvaluateRepository = RemoteEvaluateRepository(apiClient: apiClient)
        self.remoteSpareRepository = RemoteSpareRepository(apiClient: apiClient)
        self.remoteGraduateExamRepository = RemoteGraduateExamRepository(apiClient: apiClient)
        self.remoteNewsRepository = RemoteNewsRepository(apiClient: apiClient)
        self.remoteDataCenterRepository = RemoteDataCenterRepository(apiClient: apiClient)
        #if DEBUG
        self.mockScheduleRepository = MockScheduleRepository()
        self.mockGradeRepository = MockGradeRepository()
        self.mockCardRepository = MockCardRepository()
        self.mockChargeRepository = MockChargeRepository()
        self.mockLibraryRepository = MockLibraryRepository()
        self.mockCETRepository = MockCETRepository()
        self.mockEvaluateRepository = MockEvaluateRepository()
        self.mockSpareRepository = MockSpareRepository()
        self.mockGraduateExamRepository = MockGraduateExamRepository()
        self.mockNewsRepository = MockNewsRepository()
        self.mockDataCenterRepository = MockDataCenterRepository()
        #endif
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
