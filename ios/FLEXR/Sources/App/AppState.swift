import Foundation
import Combine

@MainActor
class AppState: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    @Published var todayWorkout: Workout? // Deprecated: Use todaysPlannedWorkouts instead
    @Published var performanceProfile: PerformanceProfile?
    @Published var recentWorkouts: [Workout] = []
    @Published var isLoading: Bool = false
    @Published var error: AppError?

    // MARK: - Active Workout (persists across navigation)
    @Published var activeWorkoutViewModel: WorkoutExecutionViewModel?
    @Published var isShowingActiveWorkout: Bool = false

    /// Check if there's a workout in progress
    var hasActiveWorkout: Bool {
        activeWorkoutViewModel != nil && !(activeWorkoutViewModel?.isWorkoutComplete ?? true)
    }

    // MARK: - AI-Generated Training Plan
    @Published var currentPlan: TrainingPlan?
    @Published var todaysPlannedWorkouts: [PlannedWorkout] = []
    @Published var weeklyPlan: WeeklyPlan?
    @Published var isGeneratingPlan: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private let planService = PlanService.shared
    private let authService = AppleSignInService.shared
    private let analyticsService = AnalyticsService.shared

    init() {
        checkExistingSession()
        setupWorkoutSummaryObserver()
    }

    // MARK: - Watch Connectivity Integration

    private func setupWorkoutSummaryObserver() {
        // Listen for workout summaries from Apple Watch
        NotificationCenter.default.addObserver(
            forName: .watchWorkoutSummaryReceived,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleWorkoutSummaryFromWatch(notification)
        }
    }

    private func handleWorkoutSummaryFromWatch(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let data = userInfo["data"] as? Data else {
            print("❌ Failed to extract workout summary data from notification")
            return
        }

        do {
            let decoder = JSONDecoder()
            let summary = try decoder.decode(WorkoutSummary.self, from: data)

            print("✅ Received workout summary from Watch: \(summary.workoutName)")

            // Save to Core Data via AnalyticsService
            Task {
                await analyticsService.saveWorkout(summary)
                print("✅ Workout summary saved successfully")
            }
        } catch {
            print("❌ Failed to decode workout summary: \(error)")
        }
    }

    // MARK: - Session Check

    private func checkExistingSession() {
        // Check if user is already signed in via Apple
        if authService.isSignedIn, let userId = authService.currentUserId {
            setupUserFromAuth(userId: userId, email: authService.userEmail)
        } else {
            #if DEBUG
            // Only auto-login with mock in DEBUG if not already signed in
            Task {
                try? await signIn(email: "demo@flexr.app", password: "demo")
            }
            #endif
        }
    }

    // MARK: - User Management

    // Fixed mock user ID - must be consistent across sessions for data to persist
    private static let mockUserId = UUID(uuidString: "931951FC-66BA-486D-BE6D-02CFA6E48E85")!

    /// Signs in with Apple - the REAL authentication method
    func signInWithApple() async throws {
        isLoading = true
        defer { isLoading = false }

        try await authService.signIn()

        guard let userId = authService.currentUserId else {
            throw AppError.authentication("Failed to get user ID from Apple Sign-in")
        }

        setupUserFromAuth(userId: userId, email: authService.userEmail)
    }

    /// Sets up user from authenticated session (Apple Sign-in)
    private func setupUserFromAuth(userId: UUID, email: String?) {
        let user = User(
            id: userId,
            email: email ?? "user@flexr.app",
            name: "FLEXR Athlete",
            createdAt: Date(),
            trainingGoal: .competeRace,
            raceDate: Calendar.current.date(byAdding: .month, value: 3, to: Date()),
            trainingPreferences: UserTrainingPreferences(
                daysPerWeek: 5,
                sessionsPerDay: 1,
                preferredTypes: [.fullSimulation, .stationFocus, .running, .recovery]
            ),
            experienceLevel: .intermediate
        )

        currentUser = user
        isAuthenticated = true
        planService.setUserId(user.id)

        // Load data
        Task {
            await loadTodaysPlannedWorkouts()
            await loadWeeklyPlan()
        }
    }

    /// Mock sign in for DEBUG only
    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }

        // Create a mock user with FIXED ID (so data persists across sessions)
        let user = User(
            id: Self.mockUserId,
            email: email,
            name: "Alex Sole",
            createdAt: Date(),
            trainingGoal: .competeRace,
            raceDate: Calendar.current.date(byAdding: .month, value: 3, to: Date()),
            trainingPreferences: UserTrainingPreferences(
                daysPerWeek: 5,
                sessionsPerDay: 1,
                preferredTypes: [.fullSimulation, .stationFocus, .running, .recovery]
            ),
            experienceLevel: .intermediate
        )

        currentUser = user
        isAuthenticated = true

        // Set user ID in PlanService for fetching data
        planService.setUserId(user.id)
    }

    func signOut() {
        // Sign out from Supabase
        Task {
            try? await authService.signOut()
        }

        currentUser = nil
        isAuthenticated = false
        todayWorkout = nil
        performanceProfile = nil
        recentWorkouts = []
        currentPlan = nil
        todaysPlannedWorkouts = []
        weeklyPlan = nil
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

    // MARK: - Active Workout Management

    /// Start a new workout - creates view model and shows it
    func beginWorkout(_ workout: Workout) {
        activeWorkoutViewModel = WorkoutExecutionViewModel(workout: workout)
        isShowingActiveWorkout = true
    }

    /// Return to an active workout
    func returnToActiveWorkout() {
        guard hasActiveWorkout else { return }
        isShowingActiveWorkout = true
    }

    /// Dismiss workout screen (workout keeps running in background)
    func minimizeWorkout() {
        isShowingActiveWorkout = false
    }

    /// End the active workout completely
    func endActiveWorkout() {
        activeWorkoutViewModel = nil
        isShowingActiveWorkout = false
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

    // MARK: - AI Training Plan Management

    /// Generates initial AI-powered training plan after onboarding
    func generateInitialPlan() async throws {
        guard let user = currentUser else { return }
        isGeneratingPlan = true
        defer { isGeneratingPlan = false }

        try await planService.generateInitialPlan(for: user)
        currentPlan = planService.currentPlan
        todaysPlannedWorkouts = planService.todaysWorkouts
        weeklyPlan = planService.weeklyPlan
    }

    /// Loads today's AI-generated workouts
    func loadTodaysPlannedWorkouts() async {
        await planService.fetchTodaysWorkouts()
        todaysPlannedWorkouts = planService.todaysWorkouts
    }

    /// Loads the current weekly plan
    func loadWeeklyPlan() async {
        await planService.fetchWeeklyPlan()
        weeklyPlan = planService.weeklyPlan
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
