import SwiftUI

// MARK: - Step 4: Equipment Access
// Gym type selection with smart defaults, home gym equipment (conditional)

struct OnboardingStep4_EquipmentAccess: View {
    @ObservedObject var onboardingData: OnboardingData
    let onNext: () -> Void
    let onBack: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxLarge) {
                // Header
                header

                // Equipment Location Selection
                equipmentLocationSelection

                // Home Gym Equipment (conditional)
                if onboardingData.equipmentLocation == .homeGym {
                    homeGymEquipmentSelection
                }

                // Info box about smart defaults
                smartDefaultsInfo

                Spacer(minLength: DesignSystem.Spacing.xxxLarge)

                // Navigation buttons
                navigationButtons
            }
            .padding(DesignSystem.Spacing.large)
        }
        .background(DesignSystem.Colors.background)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            Text("Where will you train?")
                .font(DesignSystem.Typography.title1)
                .foregroundColor(DesignSystem.Colors.text.primary)

            Text("The AI will suggest exercises based on your equipment")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.text.secondary)
        }
    }

    // MARK: - Equipment Location Selection

    private var equipmentLocationSelection: some View {
        VStack(spacing: DesignSystem.Spacing.small) {
            ForEach(OnboardingData.EquipmentLocation.allCases, id: \.self) { location in
                EquipmentLocationCard(
                    location: location,
                    isSelected: onboardingData.equipmentLocation == location
                ) {
                    withAnimation(DesignSystem.Animation.normal) {
                        onboardingData.equipmentLocation = location
                        // Reset home gym equipment if not home gym
                        if location != .homeGym {
                            onboardingData.homeGymEquipment = []
                        }
                    }
                }
            }
        }
    }

    // MARK: - Home Gym Equipment Selection

    private var homeGymEquipmentSelection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("Select Your Equipment")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.text.primary)

            Text("Tap to select equipment you have")
                .font(DesignSystem.Typography.caption1)
                .foregroundColor(DesignSystem.Colors.text.secondary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: DesignSystem.Spacing.small) {
                ForEach(OnboardingData.HomeEquipment.allCases, id: \.self) { equipment in
                    HomeEquipmentButton(
                        equipment: equipment,
                        isSelected: onboardingData.homeGymEquipment.contains(equipment)
                    ) {
                        toggleEquipment(equipment)
                    }
                }
            }
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func toggleEquipment(_ equipment: OnboardingData.HomeEquipment) {
        if onboardingData.homeGymEquipment.contains(equipment) {
            onboardingData.homeGymEquipment.remove(equipment)
        } else {
            onboardingData.homeGymEquipment.insert(equipment)
        }
    }

    // MARK: - Smart Defaults Info

    private var smartDefaultsInfo: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            Image(systemName: "lightbulb.fill")
                .font(.title3)
                .foregroundColor(DesignSystem.Colors.primary)

            VStack(alignment: .leading, spacing: 4) {
                Text("Smart Defaults")
                    .font(DesignSystem.Typography.caption1.weight(.semibold))
                    .foregroundColor(DesignSystem.Colors.text.primary)

                Text(smartDefaultsDescription)
                    .font(DesignSystem.Typography.caption2)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(DesignSystem.Colors.backgroundSecondary.opacity(0.5))
        .cornerRadius(DesignSystem.Radius.medium)
    }

    private var smartDefaultsDescription: String {
        guard let location = onboardingData.equipmentLocation else {
            return "The AI will automatically suggest exercises based on your gym type"
        }

        switch location {
        case .hyroxGym:
            return "All 8 HYROX stations available - perfect for race-specific training"
        case .crossfitGym:
            return "Most functional equipment available - great for HYROX training"
        case .commercialGym:
            return "Standard gym equipment - the AI will adapt exercises accordingly"
        case .homeGym:
            return "Custom setup - select your equipment above"
        case .minimal:
            return "Bodyweight + running focused - no equipment needed"
        }
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            Button(action: onBack) {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.text.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(DesignSystem.Colors.backgroundSecondary)
                .cornerRadius(DesignSystem.Radius.medium)
            }

            Button(action: onNext) {
                Text("Continue")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        onboardingData.isStepComplete(4)
                            ? DesignSystem.Colors.primary
                            : DesignSystem.Colors.backgroundSecondary
                    )
                    .cornerRadius(DesignSystem.Radius.medium)
            }
            .disabled(!onboardingData.isStepComplete(4))
        }
    }
}

// MARK: - Equipment Location Card Component

struct EquipmentLocationCard: View {
    let location: OnboardingData.EquipmentLocation
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.medium) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(location.displayName)
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.text.primary)

                    Text(location.description)
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
            .padding()
            .background(
                isSelected
                    ? DesignSystem.Colors.backgroundSecondary.opacity(1.5)
                    : DesignSystem.Colors.backgroundSecondary
            )
            .cornerRadius(DesignSystem.Radius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                    .stroke(
                        isSelected ? DesignSystem.Colors.primary : Color.clear,
                        lineWidth: 2
                    )
            )
        }
    }
}

// MARK: - Home Equipment Button Component

struct HomeEquipmentButton: View {
    let equipment: OnboardingData.HomeEquipment
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.text.secondary)

                Text(equipment.displayName)
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(DesignSystem.Colors.text.primary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .padding(.vertical, DesignSystem.Spacing.small)
            .background(
                isSelected
                    ? DesignSystem.Colors.backgroundSecondary.opacity(1.5)
                    : DesignSystem.Colors.backgroundSecondary
            )
            .cornerRadius(DesignSystem.Radius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                    .stroke(
                        isSelected ? DesignSystem.Colors.primary : Color.clear,
                        lineWidth: 2
                    )
            )
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingStep4_EquipmentAccess(
        onboardingData: OnboardingData(),
        onNext: {},
        onBack: {}
    )
}
