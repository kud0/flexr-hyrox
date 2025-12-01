import Foundation
import Combine

@MainActor
class AppState: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    @Published var todayWorkout: Workout?
    @Published var performanceProfile: PerformanceProfile?
    @Published var recentWorkouts: [Workout] = []
    @Published var isLoading: Bool = false
    @Published var error: AppError?

    private var cancellables = Set<AnyCancellable>()

    init() {
        setupMockData()
    }

    // MARK: - User Management

    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }

        // TODO: Implement actual authentication
        // For now, create a mock user
        let user = User(
            id: UUID(),
            email: email,
            name: "Alex Sole",
            createdAt: Date(),
            trainingGoal: .competeRace,
            raceDate: Calendar.current.date(byAdding: .month, value: 3, to: Date()),
            trainingArchitecture: TrainingArchitecture(
                daysPerWeek: 5,
                sessionsPerDay: 1,
                sessionTypes: [.fullSimulation, .stationFocus, .running, .recovery]
            ),
            experienceLevel: .intermediate
        )

        currentUser = user
        isAuthenticated = true
    }

    func signOut() {
        currentUser = nil
        isAuthenticated = false
        todayWorkout = nil
        performanceProfile = nil
        recentWorkouts = []
    }

    // MARK: - Workout Management

    func loadTodayWorkout() async throws {
        guard let userId = currentUser?.id else { return }

        isLoading = true
        defer { isLoading = false }

        // TODO: Fetch from backend/CoreData
        // Mock implementation
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        todayWorkout = Workout(
            id: UUID(),
            userId: userId,
            date: today,
            type: .fullSimulation,
            status: .planned,
            segments: [],
            totalDuration: nil,
            estimatedCalories: 800,
            readinessScore: 85
        )
    }

    func startWorkout(_ workout: Workout) async throws {
        // TODO: Implement workout start logic
        var updatedWorkout = workout
        updatedWorkout.status = .inProgress
        todayWorkout = updatedWorkout
    }

    func completeWorkout(_ workout: Workout) async throws {
        // TODO: Save workout data
        var updatedWorkout = workout
        updatedWorkout.status = .completed

        // Add to recent workouts
        recentWorkouts.insert(updatedWorkout, at: 0)

        // Clear today's workout
        todayWorkout = nil
    }

    // MARK: - Performance Profile

    func loadPerformanceProfile() async throws {
        guard let userId = currentUser?.id else { return }

        isLoading = true
        defer { isLoading = false }

        // TODO: Fetch from backend
        // Mock implementation
        performanceProfile = PerformanceProfile(
            userId: userId,
            freshRunPace: RunPace(
                minPerKm: 4.5,
                minPerMile: 7.25,
                confidenceLevel: 0.85
            ),
            compromisedRunPaces: [:],
            stationBenchmarks: [:],
            recoveryProfile: RecoveryProfile(
                hrRecoveryRate: 25,
                avgRecoveryTime: 120,
                confidenceLevel: 0.7
            ),
            lastUpdated: Date()
        )
    }

    func updatePerformanceProfile(from workout: Workout) async throws {
        // TODO: Send workout data to AI model for profile update
        guard workout.status == .completed else { return }

        // AI model will analyze:
        // - Run paces (fresh vs compromised)
        // - Station performance
        // - Heart rate recovery
        // - Pattern recognition
    }

    // MARK: - Error Handling

    func handleError(_ error: Error) {
        self.error = AppError.from(error)
    }

    func clearError() {
        error = nil
    }

    // MARK: - Mock Data

    private func setupMockData() {
        // Setup mock user for development
        #if DEBUG
        Task {
            try? await signIn(email: "demo@flexr.app", password: "demo")
            try? await loadTodayWorkout()
            try? await loadPerformanceProfile()
        }
        #endif
    }
}

// MARK: - App Error

enum AppError: LocalizedError, Identifiable {
    case authentication(String)
    case network(String)
    case dataSync(String)
    case healthKit(String)
    case unknown(String)

    var id: String {
        errorDescription ?? "unknown"
    }

    var errorDescription: String? {
        switch self {
        case .authentication(let message):
            return "Authentication Error: \(message)"
        case .network(let message):
            return "Network Error: \(message)"
        case .dataSync(let message):
            return "Data Sync Error: \(message)"
        case .healthKit(let message):
            return "HealthKit Error: \(message)"
        case .unknown(let message):
            return "Error: \(message)"
        }
    }

    static func from(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        return .unknown(error.localizedDescription)
    }
}
