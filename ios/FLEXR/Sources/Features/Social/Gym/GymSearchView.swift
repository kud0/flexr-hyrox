// FLEXR - Gym Search View
// Search and discover gyms

import SwiftUI

struct GymSearchView: View {
    @StateObject private var supabase = SupabaseService.shared
    @State private var searchQuery = ""
    @State private var gyms: [Gym] = []
    @State private var isLoading = false
    @State private var selectedGymType: GymType?
    @State private var showVerifiedOnly = false

    #if DEBUG
    var useMockData: Bool = true
    #else
    var useMockData: Bool = false
    #endif

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Search bar
                        searchBar

                        // Filters
                        filters

                        // Results
                        if isLoading {
                            loadingView
                        } else if gyms.isEmpty {
                            emptyState
                        } else {
                            gymList
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Find Gym")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        GymCreationView()
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(DesignSystem.Colors.primary)
                    }
                }
            }
            .task {
                await searchGyms()
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(DesignSystem.Colors.text.secondary)

            TextField("Search gyms...", text: $searchQuery)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.text.primary)
                .onChange(of: searchQuery) { _, _ in
                    Task {
                        await searchGyms()
                    }
                }

            if !searchQuery.isEmpty {
                Button {
                    searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(DesignSystem.Colors.text.tertiary)
                }
            }
        }
        .padding()
        .background(DesignSystem.Colors.surface)
        .cornerRadius(12)
    }

    // MARK: - Filters

    private var filters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Verified filter
                FilterChip(
                    title: "Verified",
                    icon: "checkmark.seal.fill",
                    isSelected: showVerifiedOnly
                ) {
                    showVerifiedOnly.toggle()
                    Task { await searchGyms() }
                }

                // Gym type filters
                ForEach(GymType.allCases, id: \.self) { type in
                    FilterChip(
                        title: type.displayName,
                        icon: type.icon,
                        isSelected: selectedGymType == type
                    ) {
                        selectedGymType = selectedGymType == type ? nil : type
                        Task { await searchGyms() }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Gym List

    private var gymList: some View {
        LazyVStack(spacing: 12) {
            ForEach(gyms) { gym in
                NavigationLink(destination: GymDetailView(gymId: gym.id)) {
                    GymCard(gym: gym)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "building.2")
                .font(.system(size: 64))
                .foregroundStyle(DesignSystem.Colors.text.tertiary)

            Text("No gyms found")
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(DesignSystem.Colors.text.primary)

            Text("Try adjusting your search or filters")
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.text.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack {
            ProgressView()
                .tint(DesignSystem.Colors.primary)
                .scaleEffect(1.2)

            Text("Searching...")
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.text.secondary)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }

    // MARK: - Actions

    private func searchGyms() async {
        isLoading = true
        defer { isLoading = false }

        #if DEBUG
        if useMockData {
            // Simulate network delay
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

            // Filter mock gyms based on search criteria
            var filteredGyms = Gym.mockGyms

            // Apply search query filter
            if !searchQuery.isEmpty {
                filteredGyms = filteredGyms.filter { gym in
                    gym.name.localizedCaseInsensitiveContains(searchQuery) ||
                    gym.locationCity?.localizedCaseInsensitiveContains(searchQuery) ?? false
                }
            }

            // Apply gym type filter
            if let selectedGymType = selectedGymType {
                filteredGyms = filteredGyms.filter { $0.gymType == selectedGymType }
            }

            // Apply verified filter
            if showVerifiedOnly {
                filteredGyms = filteredGyms.filter { $0.isVerified }
            }

            gyms = filteredGyms
            return
        }
        #endif

        do {
            gyms = try await supabase.searchGyms(
                query: searchQuery.isEmpty ? nil : searchQuery,
                gymType: selectedGymType,
                isVerified: showVerifiedOnly ? true : nil,
                limit: 50
            )
        } catch {
            print("Failed to search gyms: \(error)")
        }
    }
}

// MARK: - Filter Chip Component

private struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))

                Text(title)
                    .font(DesignSystem.Typography.subheadline)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.surface
            )
            .foregroundStyle(
                isSelected ? .white : DesignSystem.Colors.text.primary
            )
            .cornerRadius(20)
        }
    }
}

// MARK: - Gym Card Component

private struct GymCard: View {
    let gym: Gym

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.surface)
                    .frame(width: 56, height: 56)

                Image(systemName: gym.gymType.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(DesignSystem.Colors.primary)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(gym.name)
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(DesignSystem.Colors.text.primary)

                    if gym.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(DesignSystem.Colors.primary)
                    }

                    Spacer()
                }

                Text(gym.gymType.displayName)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.text.secondary)

                if let city = gym.locationCity {
                    Text(city)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.text.tertiary)
                }

                HStack(spacing: 12) {
                    Label("\(gym.memberCount)", systemImage: "person.2.fill")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.text.secondary)

                    if gym.activityLevel != .new {
                        HStack(spacing: 4) {
                            Image(systemName: gym.activityLevel.icon)
                            Text(gym.activityLevel.rawValue)
                        }
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.secondary)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundStyle(DesignSystem.Colors.text.tertiary)
        }
        .padding()
        .background(DesignSystem.Colors.surface)
        .cornerRadius(16)
    }
}

#Preview {
    GymSearchView()
}
