// FLEXR - Gym Creation View
// Create a new gym with comprehensive details and validation

import SwiftUI

struct GymCreationView: View {
    @StateObject private var supabase = SupabaseService.shared
    @Environment(\.dismiss) private var dismiss

    // Basic Information
    @State private var gymName = ""
    @State private var gymType: GymType = .hyroxAffiliate
    @State private var description = ""

    // Location
    @State private var address = ""
    @State private var city = ""
    @State private var state = ""
    @State private var country = ""
    @State private var postalCode = ""

    // Contact Information
    @State private var website = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var instagram = ""

    // Privacy & Access
    @State private var isPublic = true
    @State private var allowAutoJoin = false

    // UI State
    @State private var isCreating = false
    @State private var errorMessage: String?
    @State private var showSuccessAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()

                Form {
                    basicInfoSection
                    locationSection
                    contactInfoSection
                    privacySection
                    createButtonSection
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Create Gym")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Gym Created", isPresented: $showSuccessAlert) {
                Button("Done") {
                    dismiss()
                }
            } message: {
                Text("Your gym has been created successfully. You can now invite members!")
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }

    // MARK: - Form Sections

    private var basicInfoSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Gym Name")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.text.secondary)

                TextField("Enter gym name", text: $gymName)
                    .font(DesignSystem.Typography.body)
                    .textInputAutocapitalization(.words)
            }
            .listRowBackground(DesignSystem.Colors.surface)

            VStack(alignment: .leading, spacing: 8) {
                Text("Gym Type")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.text.secondary)

                Picker("Gym Type", selection: $gymType) {
                    ForEach(GymType.allCases, id: \.self) { type in
                        HStack {
                            Image(systemName: type.icon)
                            Text(type.displayName)
                        }
                        .tag(type)
                    }
                }
                .pickerStyle(.menu)
            }
            .listRowBackground(DesignSystem.Colors.surface)

            VStack(alignment: .leading, spacing: 8) {
                Text("Description (Optional)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.text.secondary)

                TextField("Tell us about your gym", text: $description, axis: .vertical)
                    .font(DesignSystem.Typography.body)
                    .lineLimit(3...5)
            }
            .listRowBackground(DesignSystem.Colors.surface)
        } header: {
            Text("Basic Information")
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.text.primary)
        }
    }

    private var locationSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Street Address (Optional)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.text.secondary)

                TextField("123 Main St", text: $address)
                    .font(DesignSystem.Typography.body)
                    .textInputAutocapitalization(.words)
            }
            .listRowBackground(DesignSystem.Colors.surface)

            VStack(alignment: .leading, spacing: 8) {
                Text("City")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.text.secondary)

                TextField("City", text: $city)
                    .font(DesignSystem.Typography.body)
                    .textInputAutocapitalization(.words)
            }
            .listRowBackground(DesignSystem.Colors.surface)

            VStack(alignment: .leading, spacing: 8) {
                Text("State/Province (Optional)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.text.secondary)

                TextField("State or Province", text: $state)
                    .font(DesignSystem.Typography.body)
                    .textInputAutocapitalization(.words)
            }
            .listRowBackground(DesignSystem.Colors.surface)

            VStack(alignment: .leading, spacing: 8) {
                Text("Country (Optional)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.text.secondary)

                TextField("Country", text: $country)
                    .font(DesignSystem.Typography.body)
                    .textInputAutocapitalization(.words)
            }
            .listRowBackground(DesignSystem.Colors.surface)

            VStack(alignment: .leading, spacing: 8) {
                Text("Postal Code (Optional)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.text.secondary)

                TextField("12345", text: $postalCode)
                    .font(DesignSystem.Typography.body)
                    .keyboardType(.numbersAndPunctuation)
            }
            .listRowBackground(DesignSystem.Colors.surface)
        } header: {
            Text("Location")
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.text.primary)
        }
    }

    private var contactInfoSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Website (Optional)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.text.secondary)

                TextField("https://example.com", text: $website)
                    .font(DesignSystem.Typography.body)
                    .textContentType(.URL)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
            }
            .listRowBackground(DesignSystem.Colors.surface)

            VStack(alignment: .leading, spacing: 8) {
                Text("Phone (Optional)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.text.secondary)

                TextField("+1 (555) 123-4567", text: $phone)
                    .font(DesignSystem.Typography.body)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
            }
            .listRowBackground(DesignSystem.Colors.surface)

            VStack(alignment: .leading, spacing: 8) {
                Text("Email (Optional)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.text.secondary)

                TextField("contact@gym.com", text: $email)
                    .font(DesignSystem.Typography.body)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
            }
            .listRowBackground(DesignSystem.Colors.surface)

            VStack(alignment: .leading, spacing: 8) {
                Text("Instagram (Optional)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.text.secondary)

                TextField("@yourgym", text: $instagram)
                    .font(DesignSystem.Typography.body)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .listRowBackground(DesignSystem.Colors.surface)
        } header: {
            Text("Contact Information")
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.text.primary)
        }
    }

    private var privacySection: some View {
        Section {
            Toggle(isOn: $isPublic) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Public Gym")
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.text.primary)

                    Text("Visible in search results")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.text.secondary)
                }
            }
            .tint(DesignSystem.Colors.primary)
            .listRowBackground(DesignSystem.Colors.surface)

            Toggle(isOn: $allowAutoJoin) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Auto-approve Members")
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.text.primary)

                    Text(allowAutoJoin ? "Members can join immediately" : "You'll manually approve each member")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.text.secondary)
                }
            }
            .tint(DesignSystem.Colors.primary)
            .listRowBackground(DesignSystem.Colors.surface)
        } header: {
            Text("Privacy & Access")
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.text.primary)
        } footer: {
            if !allowAutoJoin {
                Text("You'll be notified when members request to join and can approve or decline each request.")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.text.tertiary)
            }
        }
    }

    private var createButtonSection: some View {
        Section {
            Button {
                Task { await createGym() }
            } label: {
                HStack {
                    Spacer()

                    if isCreating {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Create Gym")
                            .font(DesignSystem.Typography.bodyEmphasized)
                            .foregroundStyle(.white)
                    }

                    Spacer()
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(
                (isFormValid && !isCreating)
                    ? DesignSystem.Colors.primary
                    : DesignSystem.Colors.text.tertiary
            )
            .disabled(!isFormValid || isCreating)
        }
    }

    // MARK: - Validation

    private var isFormValid: Bool {
        !gymName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !city.trimmingCharacters(in: .whitespaces).isEmpty &&
        gymName.count >= 3 &&
        city.count >= 2
    }

    // MARK: - Actions

    private func createGym() async {
        isCreating = true
        errorMessage = nil
        defer { isCreating = false }

        // Validate email format if provided
        if !email.isEmpty && !isValidEmail(email) {
            errorMessage = "Please enter a valid email address"
            return
        }

        // Validate website format if provided
        if !website.isEmpty && !isValidURL(website) {
            errorMessage = "Please enter a valid website URL (e.g., https://example.com)"
            return
        }

        do {
            // TODO: Call Supabase service to create gym
            // For now, simulate network call
            try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds

            // Success - show alert and dismiss
            showSuccessAlert = true

            // Note: In production, you would call:
            // let gym = try await supabase.createGym(
            //     name: gymName.trimmingCharacters(in: .whitespaces),
            //     gymType: gymType,
            //     description: description.isEmpty ? nil : description,
            //     address: address.isEmpty ? nil : address,
            //     city: city.trimmingCharacters(in: .whitespaces),
            //     state: state.isEmpty ? nil : state,
            //     country: country.isEmpty ? nil : country,
            //     postalCode: postalCode.isEmpty ? nil : postalCode,
            //     website: website.isEmpty ? nil : website,
            //     phone: phone.isEmpty ? nil : phone,
            //     email: email.isEmpty ? nil : email,
            //     instagram: instagram.isEmpty ? nil : instagram,
            //     isPublic: isPublic,
            //     allowAutoJoin: allowAutoJoin
            // )
        } catch {
            errorMessage = "Failed to create gym. Please try again."
            print("Failed to create gym: \(error)")
        }
    }

    // MARK: - Helper Functions

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    private func isValidURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString),
              let scheme = url.scheme else {
            return false
        }
        return scheme == "http" || scheme == "https"
    }
}

#Preview {
    GymCreationView()
}
