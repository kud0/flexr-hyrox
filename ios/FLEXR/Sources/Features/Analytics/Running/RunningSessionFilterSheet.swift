//
//  RunningSessionFilterSheet.swift
//  FLEXR
//
//  Created by Claude on 2025-12-06.
//

import SwiftUI

// MARK: - Filter Options Model

struct RunningSessionFilterOptions: Equatable {
    var sessionTypes: Set<RunningSessionType>
    var dateRange: DateRangeOption
    var customStartDate: Date?
    var customEndDate: Date?
    var minDistance: Double?
    var maxDistance: Double?
    var sortBy: RunningSortOption

    init(
        sessionTypes: Set<RunningSessionType> = Set(RunningSessionType.allCases),
        dateRange: DateRangeOption = .allTime,
        customStartDate: Date? = nil,
        customEndDate: Date? = nil,
        minDistance: Double? = nil,
        maxDistance: Double? = nil,
        sortBy: RunningSortOption = .dateNewest
    ) {
        self.sessionTypes = sessionTypes
        self.dateRange = dateRange
        self.customStartDate = customStartDate
        self.customEndDate = customEndDate
        self.minDistance = minDistance
        self.maxDistance = maxDistance
        self.sortBy = sortBy
    }

    static var `default`: RunningSessionFilterOptions {
        RunningSessionFilterOptions()
    }

    var isDefault: Bool {
        self == .default
    }
}

// MARK: - Supporting Enums

enum DateRangeOption: String, CaseIterable, Identifiable {
    case last7Days = "Last 7 Days"
    case last30Days = "Last 30 Days"
    case last90Days = "Last 90 Days"
    case thisYear = "This Year"
    case allTime = "All Time"
    case custom = "Custom Range"

    var id: String { rawValue }

    func getDateRange() -> (start: Date?, end: Date?) {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .last7Days:
            return (calendar.date(byAdding: .day, value: -7, to: now), now)
        case .last30Days:
            return (calendar.date(byAdding: .day, value: -30, to: now), now)
        case .last90Days:
            return (calendar.date(byAdding: .day, value: -90, to: now), now)
        case .thisYear:
            let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: now))
            return (startOfYear, now)
        case .allTime:
            return (nil, nil)
        case .custom:
            return (nil, nil)
        }
    }
}

enum DistancePreset: String, CaseIterable, Identifiable {
    case under5km = "Under 5km"
    case between5And10 = "5-10km"
    case between10And20 = "10-20km"
    case over20km = "Over 20km"
    case custom = "Custom Range"

    var id: String { rawValue }

    var range: (min: Double?, max: Double?) {
        switch self {
        case .under5km:
            return (nil, 5.0)
        case .between5And10:
            return (5.0, 10.0)
        case .between10And20:
            return (10.0, 20.0)
        case .over20km:
            return (20.0, nil)
        case .custom:
            return (nil, nil)
        }
    }
}

enum RunningSortOption: String, CaseIterable, Identifiable {
    case dateNewest = "Date (Newest First)"
    case dateOldest = "Date (Oldest First)"
    case paceFastest = "Pace (Fastest First)"
    case paceSlowest = "Pace (Slowest First)"
    case distanceLongest = "Distance (Longest First)"
    case distanceShortest = "Distance (Shortest First)"
    case durationLongest = "Duration (Longest First)"

    var id: String { rawValue }
}

// MARK: - Filter Sheet View

struct RunningSessionFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var filterOptions: RunningSessionFilterOptions

    @State private var tempOptions: RunningSessionFilterOptions
    @State private var selectedDistancePreset: DistancePreset = .custom

    init(filterOptions: Binding<RunningSessionFilterOptions>) {
        self._filterOptions = filterOptions
        self._tempOptions = State(initialValue: filterOptions.wrappedValue)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    sessionTypeSection
                    dateRangeSection
                    distanceSection
                    sortSection
                }
                .padding(DesignSystem.Spacing.md)
            }
            .background(DesignSystem.Colors.background)
            .navigationTitle("Filter Sessions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear All") {
                        resetFilters()
                    }
                    .foregroundColor(DesignSystem.Colors.primary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        applyFilters()
                    }
                    .foregroundColor(DesignSystem.Colors.primary)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Session Type Section

    private var sessionTypeSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Session Type")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(.white)

            VStack(spacing: DesignSystem.Spacing.xs) {
                allTypesToggle

                ForEach(RunningSessionType.allCases, id: \.self) { type in
                    sessionTypeRow(type)
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.CornerRadius.md)
    }

    private var allTypesToggle: some View {
        Button(action: toggleAllTypes) {
            HStack {
                Image(systemName: isAllTypesSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(isAllTypesSelected ? DesignSystem.Colors.primary : .gray)

                Text("All Types")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(.white)

                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func sessionTypeRow(_ type: RunningSessionType) -> some View {
        Button(action: { toggleSessionType(type) }) {
            HStack {
                Image(systemName: tempOptions.sessionTypes.contains(type) ? "checkmark.square.fill" : "square")
                    .foregroundColor(tempOptions.sessionTypes.contains(type) ? DesignSystem.Colors.primary : .gray)

                Text(type.displayName)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(.white)

                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.leading, DesignSystem.Spacing.md)
    }

    // MARK: - Date Range Section

    private var dateRangeSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Date Range")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(.white)

            VStack(spacing: DesignSystem.Spacing.xs) {
                ForEach(DateRangeOption.allCases) { option in
                    dateRangeRow(option)
                }
            }

            if tempOptions.dateRange == .custom {
                customDateRangePickers
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.CornerRadius.md)
    }

    private func dateRangeRow(_ option: DateRangeOption) -> some View {
        Button(action: { selectDateRange(option) }) {
            HStack {
                Image(systemName: tempOptions.dateRange == option ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(tempOptions.dateRange == option ? DesignSystem.Colors.primary : .gray)

                Text(option.rawValue)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(.white)

                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var customDateRangePickers: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            DatePicker(
                "Start Date",
                selection: Binding(
                    get: { tempOptions.customStartDate ?? Date() },
                    set: { tempOptions.customStartDate = $0 }
                ),
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .accentColor(DesignSystem.Colors.primary)

            DatePicker(
                "End Date",
                selection: Binding(
                    get: { tempOptions.customEndDate ?? Date() },
                    set: { tempOptions.customEndDate = $0 }
                ),
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .accentColor(DesignSystem.Colors.primary)
        }
        .padding(.top, DesignSystem.Spacing.sm)
    }

    // MARK: - Distance Section

    private var distanceSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Distance")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(.white)

            VStack(spacing: DesignSystem.Spacing.xs) {
                ForEach(DistancePreset.allCases) { preset in
                    distancePresetRow(preset)
                }
            }

            if selectedDistancePreset == .custom {
                customDistanceInputs
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.CornerRadius.md)
    }

    private func distancePresetRow(_ preset: DistancePreset) -> some View {
        Button(action: { selectDistancePreset(preset) }) {
            HStack {
                Image(systemName: selectedDistancePreset == preset ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(selectedDistancePreset == preset ? DesignSystem.Colors.primary : .gray)

                Text(preset.rawValue)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(.white)

                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var customDistanceInputs: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            HStack {
                Text("Min:")
                    .foregroundColor(.gray)

                TextField("0.0", value: Binding(
                    get: { tempOptions.minDistance ?? 0 },
                    set: { tempOptions.minDistance = $0 > 0 ? $0 : nil }
                ), format: .number)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)

                Text("km")
                    .foregroundColor(.gray)
            }

            HStack {
                Text("Max:")
                    .foregroundColor(.gray)

                TextField("0.0", value: Binding(
                    get: { tempOptions.maxDistance ?? 0 },
                    set: { tempOptions.maxDistance = $0 > 0 ? $0 : nil }
                ), format: .number)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)

                Text("km")
                    .foregroundColor(.gray)
            }
        }
        .padding(.top, DesignSystem.Spacing.sm)
    }

    // MARK: - Sort Section

    private var sortSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Sort By")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(.white)

            VStack(spacing: DesignSystem.Spacing.xs) {
                ForEach(SortOption.allCases) { option in
                    sortOptionRow(option)
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.CornerRadius.md)
    }

    private func sortOptionRow(_ option: SortOption) -> some View {
        Button(action: { tempOptions.sortBy = option }) {
            HStack {
                Image(systemName: tempOptions.sortBy == option ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(tempOptions.sortBy == option ? DesignSystem.Colors.primary : .gray)

                Text(option.rawValue)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(.white)

                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Helper Properties

    private var isAllTypesSelected: Bool {
        tempOptions.sessionTypes.count == RunningSessionType.allCases.count
    }

    // MARK: - Actions

    private func toggleAllTypes() {
        if isAllTypesSelected {
            tempOptions.sessionTypes.removeAll()
        } else {
            tempOptions.sessionTypes = Set(RunningSessionType.allCases)
        }
    }

    private func toggleSessionType(_ type: RunningSessionType) {
        if tempOptions.sessionTypes.contains(type) {
            tempOptions.sessionTypes.remove(type)
        } else {
            tempOptions.sessionTypes.insert(type)
        }
    }

    private func selectDateRange(_ option: DateRangeOption) {
        tempOptions.dateRange = option
        if option != .custom {
            let range = option.getDateRange()
            tempOptions.customStartDate = range.start
            tempOptions.customEndDate = range.end
        }
    }

    private func selectDistancePreset(_ preset: DistancePreset) {
        selectedDistancePreset = preset
        if preset != .custom {
            let range = preset.range
            tempOptions.minDistance = range.min
            tempOptions.maxDistance = range.max
        }
    }

    private func resetFilters() {
        tempOptions = .default
        selectedDistancePreset = .custom
    }

    private func applyFilters() {
        filterOptions = tempOptions
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var filterOptions = RunningSessionFilterOptions.default

        var body: some View {
            RunningSessionFilterSheet(filterOptions: $filterOptions)
        }
    }

    return PreviewWrapper()
}
