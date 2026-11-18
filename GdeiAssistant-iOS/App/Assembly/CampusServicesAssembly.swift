import Foundation

/// Owns repository construction for campus service features:
/// schedule, grade, card, library, CET, evaluate, spare, graduate exam,
/// news, and data center.
@MainActor
struct CampusServicesAssembly {
    private let environment: AppEnvironment
    private let remoteScheduleRepository: RemoteScheduleRepository
    private let mockScheduleRepository: MockScheduleRepository
    private let remoteGradeRepository: RemoteGradeRepository
    private let mockGradeRepository: MockGradeRepository
    private let remoteCardRepository: RemoteCardRepository
    private let mockCardRepository: MockCardRepository
    private let remoteChargeRepository: RemoteChargeRepository
    private let mockChargeRepository: MockChargeRepository
    private let remoteLibraryRepository: RemoteLibraryRepository
    private let mockLibraryRepository: MockLibraryRepository
    private let remoteCETRepository: RemoteCETRepository
    private let mockCETRepository: MockCETRepository
    private let remoteEvaluateRepository: RemoteEvaluateRepository
    private let mockEvaluateRepository: MockEvaluateRepository
    private let remoteSpareRepository: RemoteSpareRepository
    private let mockSpareRepository: MockSpareRepository
    private let remoteGraduateExamRepository: RemoteGraduateExamRepository
    private let mockGraduateExamRepository: MockGraduateExamRepository
    private let remoteNewsRepository: RemoteNewsRepository
    private let mockNewsRepository: MockNewsRepository
    private let remoteDataCenterRepository: RemoteDataCenterRepository
    private let mockDataCenterRepository: MockDataCenterRepository

    func scheduleRepository(for mode: DataSourceMode) -> any ScheduleRepository {
        mode == .mock ? mockScheduleRepository : remoteScheduleRepository
    }

    var scheduleRepository: any ScheduleRepository {
        scheduleRepository(for: environment.dataSourceMode)
    }
    var gradeRepository: any GradeRepository {
        environment.dataSourceMode == .mock ? mockGradeRepository : remoteGradeRepository
    }
    var cardRepository: any CardRepository {
        environment.dataSourceMode == .mock ? mockCardRepository : remoteCardRepository
    }
    var chargeRepository: any ChargeRepository {
        environment.dataSourceMode == .mock ? mockChargeRepository : remoteChargeRepository
    }
    var libraryRepository: any LibraryRepository {
        environment.dataSourceMode == .mock ? mockLibraryRepository : remoteLibraryRepository
    }
    var cetRepository: any CETRepository {
        environment.dataSourceMode == .mock ? mockCETRepository : remoteCETRepository
    }
    var evaluateRepository: any EvaluateRepository {
        environment.dataSourceMode == .mock ? mockEvaluateRepository : remoteEvaluateRepository
    }
    var spareRepository: any SpareRepository {
        environment.dataSourceMode == .mock ? mockSpareRepository : remoteSpareRepository
    }
    var graduateExamRepository: any GraduateExamRepository {
        environment.dataSourceMode == .mock ? mockGraduateExamRepository : remoteGraduateExamRepository
    }
    func newsRepository(for mode: DataSourceMode) -> any NewsRepository {
        mode == .mock ? mockNewsRepository : remoteNewsRepository
    }

    var newsRepository: any NewsRepository {
        newsRepository(for: environment.dataSourceMode)
    }
    var dataCenterRepository: any DataCenterRepository {
        environment.dataSourceMode == .mock ? mockDataCenterRepository : remoteDataCenterRepository
    }

    init(apiClient: APIClient, environment: AppEnvironment) {
        self.environment = environment
        self.remoteScheduleRepository = RemoteScheduleRepository(apiClient: apiClient)
        self.mockScheduleRepository = MockScheduleRepository()
        self.remoteGradeRepository = RemoteGradeRepository(apiClient: apiClient)
        self.mockGradeRepository = MockGradeRepository()
        self.remoteCardRepository = RemoteCardRepository(apiClient: apiClient)
        self.mockCardRepository = MockCardRepository()
        self.remoteChargeRepository = RemoteChargeRepository(apiClient: apiClient)
        self.mockChargeRepository = MockChargeRepository()
        self.remoteLibraryRepository = RemoteLibraryRepository(apiClient: apiClient)
        self.mockLibraryRepository = MockLibraryRepository()
        self.remoteCETRepository = RemoteCETRepository(apiClient: apiClient)
        self.mockCETRepository = MockCETRepository()
        self.remoteEvaluateRepository = RemoteEvaluateRepository(apiClient: apiClient)
        self.mockEvaluateRepository = MockEvaluateRepository()
        self.remoteSpareRepository = RemoteSpareRepository(apiClient: apiClient)
        self.mockSpareRepository = MockSpareRepository()
        self.remoteGraduateExamRepository = RemoteGraduateExamRepository(apiClient: apiClient)
        self.mockGraduateExamRepository = MockGraduateExamRepository()
        self.remoteNewsRepository = RemoteNewsRepository(apiClient: apiClient)
        self.mockNewsRepository = MockNewsRepository()
        self.remoteDataCenterRepository = RemoteDataCenterRepository(apiClient: apiClient)
        self.mockDataCenterRepository = MockDataCenterRepository()
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
