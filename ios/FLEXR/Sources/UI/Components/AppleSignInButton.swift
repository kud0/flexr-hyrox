// FLEXR - Apple Sign In Button
// Native Sign in with Apple button

import SwiftUI
import AuthenticationServices

struct AppleSignInButton: View {
    let onSignIn: () async -> Void

    var body: some View {
        SignInWithAppleButton(.signIn) { request in
            request.requestedScopes = [.email, .fullName]
        } onCompletion: { result in
            Task {
                await onSignIn()
            }
        }
        .signInWithAppleButtonStyle(.white)
        .frame(height: 50)
        .cornerRadius(12)
    }
}

// MARK: - Sign In View

struct SignInView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var authService = AppleSignInService.shared
    @Binding var isSignedIn: Bool

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Logo
            Image(systemName: "figure.run")
                .font(.system(size: 80))
                .foregroundColor(.green)

            Text("FLEXR")
                .font(.system(size: 36, weight: .bold))

            Text("HYROX Training")
                .font(.title3)
                .foregroundColor(.secondary)

            Spacer()

            // Sign In Button
            if authService.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            } else {
                Button(action: {
                    Task {
                        do {
                            // Use authService directly - only ONE sign-in prompt
                            try await authService.signIn()
                            isSignedIn = true
                        } catch {
                            print("Sign in error: \(error)")
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "applelogo")
                            .font(.system(size: 20, weight: .semibold))
                        Text("Sign in with Apple")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.white)
                    .cornerRadius(14)
                }
                .padding(.horizontal, 32)
            }

            if let error = authService.error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            Spacer()
                .frame(height: 40)
        }
        .background(Color.black)
    }
}

#Preview {
    SignInView(isSignedIn: .constant(false))
        .environmentObject(AppState())
}
