//
//  AllRunsListView.swift
//  FLEXR
//
//  Created by Claude on 2025-12-06.
//

import SwiftUI
import Charts

struct AllRunsListView: View {
    @StateObject private var viewModel = AllRunsListViewModel()
    @State private var showFilterSheet = false
    @State private var selectedSession: RunningSession?

    var body: some View {
        ZStack {
            Color(hex: "#000000")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Search Bar
                searchBar

                // Sort & Filter Bar
                sortFilterBar

                if viewModel.isLoading && viewModel.groupedSessions.isEmpty {
                    loadingView
                } else if viewModel.groupedSessions.isEmpty {
                    emptyStateView
                } else {
                    runsList
                }
            }
        }
        .navigationTitle("All Runs")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showFilterSheet) {
            AllRunsFilterSheet(
                selectedTypes: $viewModel.selectedTypes,
                dateRange: $viewModel.dateRange,
                minDistance: $viewModel.minDistance,
                maxDistance: $viewModel.maxDistance,
                onApply: {
                    viewModel.applyFilters()
                    showFilterSheet = false
                }
            )
        }
        .sheet(item: $selectedSession) { session in
            NavigationView {
                RunningSessionDetailView(session: session)
            }
        }
        .task {
            await viewModel.loadInitialSessions()
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .font(.system(size: 16, weight: .medium))

                TextField("Search runs...", text: $viewModel.searchText)
                    .foregroundColor(.white)
                    .font(.system(size: 16))

                if !viewModel.searchText.isEmpty {
                    Button(action: {
                        viewModel.searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(hex: "#1C1C1E"))
            .cornerRadius(10)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Sort & Filter Bar

    private var sortFilterBar: some View {
        HStack(spacing: 12) {
            // Sort Menu
            Menu {
                Button(action: { viewModel.sortOption = .date }) {
                    Label("Date", systemImage: viewModel.sortOption == .date ? "checkmark" : "")
                }
                Button(action: { viewModel.sortOption = .pace }) {
                    Label("Pace", systemImage: viewModel.sortOption == .pace ? "checkmark" : "")
                }
                Button(action: { viewModel.sortOption = .distance }) {
                    Label("Distance", systemImage: viewModel.sortOption == .distance ? "checkmark" : "")
                }
                Button(action: { viewModel.sortOption = .duration }) {
                    Label("Duration", systemImage: viewModel.sortOption == .duration ? "checkmark" : "")
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 14, weight: .medium))
                    Text(viewModel.sortOption.displayName)
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(hex: "#1C1C1E"))
                .cornerRadius(8)
            }

            Spacer()

            // Filter Button
            Button(action: { showFilterSheet = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "line.3.horizontal.decrease.circle\(viewModel.hasActiveFilters ? ".fill" : "")")
                        .font(.system(size: 14, weight: .medium))
                    Text("Filter")
                        .font(.system(size: 14, weight: .medium))

                    if viewModel.hasActiveFilters {
                        Circle()
                            .fill(Color(hex: "#00C7BE"))
                            .frame(width: 8, height: 8)
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(hex: "#1C1C1E"))
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    // MARK: - Runs List

    private var runsList: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                ForEach(Array(viewModel.groupedSessions.keys.sorted(by: >)), id: \.self) { monthKey in
                    Section(header: sectionHeader(for: monthKey)) {
                        ForEach(viewModel.groupedSessions[monthKey] ?? []) { session in
                            RunCardView(session: session)
                                .onTapGesture {
                                    selectedSession = session
                                }
                                .onAppear {
                                    viewModel.loadMoreIfNeeded(currentSession: session)
                                }
                        }
                    }
                }

                if viewModel.isLoadingMore {
                    ProgressView()
                        .tint(.white)
                        .padding(.vertical, 20)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func sectionHeader(for monthKey: String) -> some View {
        Text(monthKey)
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(hex: "#000000"))
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(.white)
                .scaleEffect(1.2)
            Text("Loading runs...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.run")
                .font(.system(size: 60, weight: .light))
                .foregroundColor(.gray)

            VStack(spacing: 8) {
                Text("No Runs Yet")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)

                Text(viewModel.hasActiveFilters ? "Try adjusting your filters" : "Start your first run to see it here")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }

            if viewModel.hasActiveFilters {
                Button(action: {
                    viewModel.clearFilters()
                }) {
                    Text("Clear Filters")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color(hex: "#00C7BE"))
                        .cornerRadius(10)
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
    }
}

// MARK: - Run Card View

struct RunCardView: View {
    let session: RunningSession

    private var sessionType: RunningSessionType {
        session.sessionType
    }

    private var typeColor: Color {
        switch sessionType.color {
        case "blue": return DesignSystem.Colors.primary
        case "red": return DesignSystem.Colors.error
        case "orange": return DesignSystem.Colors.warning
        case "purple": return Color.purple
        case "green": return DesignSystem.Colors.success
        default: return DesignSystem.Colors.text.secondary
        }
    }

    private var isPR: Bool {
        // TODO: Implement PR logic based on session type and distance
        false
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Session Type Icon
                Circle()
                    .fill(typeColor.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: sessionType.icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(typeColor)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(sessionType.displayName)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)

                        if isPR {
                            HStack(spacing: 4) {
                                Image(systemName: "trophy.fill")
                                    .font(.system(size: 10))
                                Text("PR")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color(hex: "#FFD700"))
                            .cornerRadius(4)
                        }
                    }

                    Text(session.relativeDate)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            // Stats Grid
            HStack(spacing: 16) {
                StatItemView(
                    icon: "ruler",
                    value: session.distanceFormatted,
                    label: "Distance"
                )

                StatItemView(
                    icon: "clock",
                    value: session.durationFormatted,
                    label: "Duration"
                )

                StatItemView(
                    icon: "gauge.with.dots.needle.67percent",
                    value: session.paceFormatted,
                    label: "Pace"
                )
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            // HR Zone Mini-Bar
            if let heartRateZones = session.heartRateZones {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Heart Rate Zones")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)

                    HRZoneMiniBar(zones: heartRateZones)
                        .frame(height: 8)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }

            Divider()
                .background(Color(hex: "#3A3A3C"))
                .padding(.top, 16)
        }
        .background(Color(hex: "#2C2C2E"))
        .cornerRadius(12)
        .padding(.vertical, 6)
    }
}

// MARK: - Stat Item View

struct StatItemView: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                Text(value)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            }

            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - HR Zone Mini-Bar

struct HRZoneMiniBar: View {
    let zones: HeartRateZones

    private var totalSeconds: Double {
        zones.zone1Seconds + zones.zone2Seconds + zones.zone3Seconds + zones.zone4Seconds + zones.zone5Seconds
    }

    private func percentage(for zoneSeconds: TimeInterval) -> Double {
        guard totalSeconds > 0 else { return 0 }
        return zoneSeconds / totalSeconds
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 1) {
                if zones.zone1Seconds > 0 {
                    Rectangle()
                        .fill(Color.gray)
                        .frame(width: geometry.size.width * percentage(for: zones.zone1Seconds))
                }

                if zones.zone2Seconds > 0 {
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * percentage(for: zones.zone2Seconds))
                }

                if zones.zone3Seconds > 0 {
                    Rectangle()
                        .fill(Color.green)
                        .frame(width: geometry.size.width * percentage(for: zones.zone3Seconds))
                }

                if zones.zone4Seconds > 0 {
                    Rectangle()
                        .fill(Color.orange)
                        .frame(width: geometry.size.width * percentage(for: zones.zone4Seconds))
                }

                if zones.zone5Seconds > 0 {
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: geometry.size.width * percentage(for: zones.zone5Seconds))
                }
            }
            .cornerRadius(4)
        }
    }
}

// MARK: - View Model

@MainActor
class AllRunsListViewModel: ObservableObject {
    @Published var sessions: [RunningSession] = []
    @Published var groupedSessions: [String: [RunningSession]] = [:]
    @Published var searchText = ""
    @Published var sortOption: SortOption = .date
    @Published var isLoading = false
    @Published var isLoadingMore = false

    // Filter properties
    @Published var selectedTypes: Set<RunningSessionType> = []
    @Published var dateRange: DateRange?
    @Published var minDistance: Double?
    @Published var maxDistance: Double?

    private var currentOffset = 0
    private let pageSize = 20
    private var hasMoreData = true

    var hasActiveFilters: Bool {
        !selectedTypes.isEmpty || dateRange != nil || minDistance != nil || maxDistance != nil
    }

    func loadInitialSessions() async {
        guard !isLoading else { return }
        isLoading = true
        currentOffset = 0
        hasMoreData = true

        await loadSessions()

        isLoading = false
    }

    func loadMoreIfNeeded(currentSession: RunningSession) {
        guard let lastSession = sessions.last,
              lastSession.id == currentSession.id,
              !isLoadingMore,
              hasMoreData else {
            return
        }

        Task {
            await loadMore()
        }
    }

    private func loadMore() async {
        guard !isLoadingMore, hasMoreData else { return }
        isLoadingMore = true
        currentOffset += pageSize

        await loadSessions()

        isLoadingMore = false
    }

    private func loadSessions() async {
        do {
            let newSessions = try await SupabaseService.shared.getRunningSessionsFor(
                limit: pageSize,
                offset: currentOffset
            )

            if newSessions.count < pageSize {
                hasMoreData = false
            }

            if currentOffset == 0 {
                sessions = newSessions
            } else {
                sessions.append(contentsOf: newSessions)
            }

            applyFiltersAndSort()
        } catch {
            print("Error loading sessions: \(error)")
        }
    }

    func applyFilters() {
        currentOffset = 0
        hasMoreData = true
        Task {
            await loadInitialSessions()
        }
    }

    func clearFilters() {
        selectedTypes.removeAll()
        dateRange = nil
        minDistance = nil
        maxDistance = nil
        searchText = ""
        applyFilters()
    }

    private func applyFiltersAndSort() {
        var filtered = sessions

        // Apply search
        if !searchText.isEmpty {
            filtered = filtered.filter { session in
                session.sessionType.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Apply type filter
        if !selectedTypes.isEmpty {
            filtered = filtered.filter { selectedTypes.contains($0.sessionType) }
        }

        // Apply date range filter
        if let dateRange = dateRange {
            filtered = filtered.filter { session in
                let date = session.startedAt ?? session.createdAt
                return date >= dateRange.start && date <= dateRange.end
            }
        }

        // Apply distance filters
        if let minDistance = minDistance {
            filtered = filtered.filter { $0.distanceMeters >= Int(minDistance * 1000) }
        }
        if let maxDistance = maxDistance {
            filtered = filtered.filter { $0.distanceMeters <= Int(maxDistance * 1000) }
        }

        // Apply sort
        switch sortOption {
        case .date:
            filtered.sort { ($0.startedAt ?? $0.createdAt) > ($1.startedAt ?? $1.createdAt) }
        case .pace:
            filtered.sort { $0.avgPacePerKm < $1.avgPacePerKm }
        case .distance:
            filtered.sort { $0.distanceMeters > $1.distanceMeters }
        case .duration:
            filtered.sort { $0.durationSeconds > $1.durationSeconds }
        }

        // Group by month
        groupedSessions = Dictionary(grouping: filtered) { session in
            session.monthYearKey
        }
    }
}

// MARK: - Supporting Types

enum SortOption {
    case date, pace, distance, duration

    var displayName: String {
        switch self {
        case .date: return "Date"
        case .pace: return "Pace"
        case .distance: return "Distance"
        case .duration: return "Duration"
        }
    }
}

struct DateRange {
    let start: Date
    let end: Date
}

// MARK: - Filter Sheet (simple inline version)

struct AllRunsFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTypes: Set<RunningSessionType>
    @Binding var dateRange: DateRange?
    @Binding var minDistance: Double?
    @Binding var maxDistance: Double?

    let onApply: () -> Void

    @State private var tempMinDistance = ""
    @State private var tempMaxDistance = ""

    var body: some View {
        NavigationView {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Session Types
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Session Type")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(RunningSessionType.allCases, id: \.self) { type in
                                    AllRunsTypeFilterButton(
                                        type: type,
                                        isSelected: selectedTypes.contains(type),
                                        action: {
                                            if selectedTypes.contains(type) {
                                                selectedTypes.remove(type)
                                            } else {
                                                selectedTypes.insert(type)
                                            }
                                        }
                                    )
                                }
                            }
                        }

                        Divider().background(DesignSystem.Colors.divider)

                        // Distance Range
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Distance Range (km)")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)

                            HStack(spacing: 12) {
                                TextField("Min", text: $tempMinDistance)
                                    .keyboardType(.decimalPad)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(DesignSystem.Colors.surface)
                                    .cornerRadius(10)

                                Text("to")
                                    .foregroundColor(.gray)

                                TextField("Max", text: $tempMaxDistance)
                                    .keyboardType(.decimalPad)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(DesignSystem.Colors.surface)
                                    .cornerRadius(10)
                            }
                        }

                        Divider().background(DesignSystem.Colors.divider)

                        // Clear All Button
                        Button(action: {
                            selectedTypes.removeAll()
                            dateRange = nil
                            minDistance = nil
                            maxDistance = nil
                            tempMinDistance = ""
                            tempMaxDistance = ""
                        }) {
                            Text("Clear All Filters")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(DesignSystem.Colors.accent)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(DesignSystem.Colors.surface)
                                .cornerRadius(10)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(DesignSystem.Colors.accent)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        if let min = Double(tempMinDistance) {
                            minDistance = min
                        }
                        if let max = Double(tempMaxDistance) {
                            maxDistance = max
                        }
                        onApply()
                    }
                    .foregroundColor(DesignSystem.Colors.accent)
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            tempMinDistance = minDistance.map { String($0) } ?? ""
            tempMaxDistance = maxDistance.map { String($0) } ?? ""
        }
    }
}

struct AllRunsTypeFilterButton: View {
    let type: RunningSessionType
    let isSelected: Bool
    let action: () -> Void

    private var typeColor: Color {
        switch type.color {
        case "blue": return DesignSystem.Colors.primary
        case "red": return DesignSystem.Colors.error
        case "orange": return DesignSystem.Colors.warning
        case "purple": return Color.purple
        case "green": return DesignSystem.Colors.success
        default: return DesignSystem.Colors.text.secondary
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.system(size: 16, weight: .semibold))

                Text(type.displayName)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : .gray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? typeColor : DesignSystem.Colors.surface)
            .cornerRadius(10)
        }
    }
}

// MARK: - Extensions

extension RunningSession {
    var relativeDate: String {
        let calendar = Calendar.current
        let now = Date()
        let date = startedAt ?? createdAt

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let components = calendar.dateComponents([.day], from: date, to: now)
            if let days = components.day, days < 7 {
                return "\(days) days ago"
            } else if let days = components.day, days < 14 {
                return "1 week ago"
            } else if let days = components.day, days < 30 {
                let weeks = days / 7
                return "\(weeks) weeks ago"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d, yyyy"
                return formatter.string(from: date)
            }
        }
    }

    var monthYearKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: startedAt ?? createdAt)
    }

    var startedAtOrCreated: Date {
        startedAt ?? createdAt
    }

    var distanceFormatted: String {
        let km = Double(distanceMeters) / 1000.0
        return String(format: "%.2f km", km)
    }

    var durationFormatted: String {
        let totalSeconds = Int(durationSeconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    var paceFormatted: String {
        let minutes = Int(avgPacePerKm) / 60
        let seconds = Int(avgPacePerKm) % 60
        return String(format: "%d:%02d /km", minutes, seconds)
    }
}

// RunningSessionType already conforms to CaseIterable in its definition
// Note: Color(hex:) extension is defined in DesignSystem.swift

// MARK: - Preview

#Preview {
    NavigationView {
        AllRunsListView()
    }
}
