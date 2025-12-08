// FLEXR - Feedback View
// Let users share thoughts, requests, and report issues

import SwiftUI

struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var feedbackService = UserFeedbackService.shared

    @State private var selectedCategory: UserFeedbackCategory = .general
    @State private var message = ""
    @State private var showSuccess = false

    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("We're Listening")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(DesignSystem.Colors.text.primary)

                            Text("Your feedback shapes FLEXR. What's on your mind?")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.text.secondary)
                        }

                        // Category Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("TYPE")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(DesignSystem.Colors.text.tertiary)

                            HStack(spacing: 12) {
                                ForEach([UserFeedbackCategory.featureRequest, .bugReport, .general], id: \.self) { category in
                                    CategoryButton(
                                        category: category,
                                        isSelected: selectedCategory == category
                                    ) {
                                        withAnimation(.spring(response: 0.3)) {
                                            selectedCategory = category
                                        }
                                    }
                                }
                            }
                        }

                        // Message Input
                        VStack(alignment: .leading, spacing: 12) {
                            Text("YOUR MESSAGE")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(DesignSystem.Colors.text.tertiary)

                            ZStack(alignment: .topLeading) {
                                if message.isEmpty {
                                    Text(selectedCategory.placeholder)
                                        .font(DesignSystem.Typography.body)
                                        .foregroundColor(DesignSystem.Colors.text.tertiary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 14)
                                }

                                TextEditor(text: $message)
                                    .font(DesignSystem.Typography.body)
                                    .foregroundColor(DesignSystem.Colors.text.primary)
                                    .scrollContentBackground(.hidden)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .focused($isTextFieldFocused)
                            }
                            .frame(minHeight: 150)
                            .background(DesignSystem.Colors.surface)
                            .cornerRadius(DesignSystem.Radius.medium)
                        }

                        // Submit Button
                        Button {
                            submitFeedback()
                        } label: {
                            HStack {
                                if feedbackService.isSubmitting {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "paperplane.fill")
                                    Text("Send Feedback")
                                }
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                    ? DesignSystem.Colors.text.tertiary
                                    : DesignSystem.Colors.primary
                            )
                            .cornerRadius(DesignSystem.Radius.medium)
                        }
                        .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || feedbackService.isSubmitting)

                        Spacer()
                    }
                    .padding(24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(DesignSystem.Colors.text.secondary)
                    }
                }
            }
            .alert("Thank You!", isPresented: $showSuccess) {
                Button("Done") {
                    dismiss()
                }
            } message: {
                Text("Your feedback has been received. We read every message.")
            }
        }
    }

    private func submitFeedback() {
        isTextFieldFocused = false

        Task {
            do {
                try await feedbackService.submitFeedback(
                    category: selectedCategory,
                    message: message,
                    appContext: "profile_feedback"
                )
                showSuccess = true
            } catch {
                print("Failed to submit feedback: \(error)")
            }
        }
    }
}

// MARK: - Category Button

struct CategoryButton: View {
    let category: UserFeedbackCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 20))

                Text(category.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .multilineTextAlignment(.center)
            }
            .foregroundColor(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.text.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isSelected
                    ? DesignSystem.Colors.primary.opacity(0.15)
                    : DesignSystem.Colors.surface
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

// MARK: - Quick Pulse Prompt (Modal)

struct QuickPulsePrompt: View {
    @Binding var isPresented: Bool
    @StateObject private var feedbackService = UserFeedbackService.shared

    @State private var message = ""
    @State private var showThankYou = false
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Spacer()
                Button {
                    feedbackService.dismissPulsePrompt()
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(DesignSystem.Colors.text.tertiary)
                }
            }

            VStack(spacing: 12) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [DesignSystem.Colors.primary, DesignSystem.Colors.accent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Quick Thought")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(DesignSystem.Colors.text.primary)

                Text("One thing you'd improve about FLEXR?")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
                    .multilineTextAlignment(.center)
            }

            // Input
            TextField("Type here...", text: $message, axis: .vertical)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.text.primary)
                .padding(16)
                .background(DesignSystem.Colors.surface)
                .cornerRadius(DesignSystem.Radius.medium)
                .lineLimit(3...6)
                .focused($isTextFieldFocused)

            // Buttons
            HStack(spacing: 12) {
                Button {
                    feedbackService.dismissPulsePrompt()
                    isPresented = false
                } label: {
                    Text("Skip")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(DesignSystem.Colors.surface)
                        .cornerRadius(DesignSystem.Radius.medium)
                }

                Button {
                    submitPulse()
                } label: {
                    HStack {
                        if feedbackService.isSubmitting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Send")
                        }
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? DesignSystem.Colors.text.tertiary
                            : DesignSystem.Colors.primary
                    )
                    .cornerRadius(DesignSystem.Radius.medium)
                }
                .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .background(DesignSystem.Colors.background)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.3), radius: 20)
        .padding(24)
        .alert("Thanks!", isPresented: $showThankYou) {
            Button("OK") {
                isPresented = false
            }
        } message: {
            Text("Your input helps us build a better FLEXR.")
        }
    }

    private func submitPulse() {
        isTextFieldFocused = false

        Task {
            do {
                try await feedbackService.submitFeedback(
                    category: .pulseCheck,
                    message: message,
                    appContext: "pulse_prompt"
                )
                showThankYou = true
            } catch {
                print("Failed to submit pulse: \(error)")
            }
        }
    }
}

#Preview {
    FeedbackView()
}
