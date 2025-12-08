// FLEXR Watch - Sign In View
// Sign in with Apple for watchOS

import SwiftUI
import AuthenticationServices

struct WatchSignInView: View {
    @Environment(WatchAuthService.self) var authService

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.run")
                .font(.system(size: 40))
                .foregroundColor(.green)

            Text("FLEXR")
                .font(.title3.bold())

            Text("HYROX Training")
                .font(.caption2)
                .foregroundColor(.secondary)

            Spacer()

            if authService.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
            } else {
                Button {
                    Task {
                        do {
                            try await authService.signIn()
                        } catch {
                            print("Sign in error: \(error)")
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "apple.logo")
                        Text("Sign In")
                    }
                    .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .foregroundColor(.black)

                #if targetEnvironment(simulator)
                Button {
                    // Simulator bypass - use test user ID
                    authService.simulatorSignIn()
                } label: {
                    Text("Simulator Test")
                        .font(.caption2)
                }
                .buttonStyle(.plain)
                .foregroundColor(.gray)
                #endif
            }

            if let error = authService.error {
                Text(error)
                    .font(.caption2)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }
}

#Preview {
    WatchSignInView()
        .environment(WatchAuthService.shared)
}
