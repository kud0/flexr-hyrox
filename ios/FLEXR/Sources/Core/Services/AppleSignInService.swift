// FLEXR - Apple Sign In Service
// Handles Sign in with Apple authentication via Supabase

import Foundation
import AuthenticationServices
import Supabase

@MainActor
class AppleSignInService: NSObject, ObservableObject {
    static let shared = AppleSignInService()

    @Published var isSignedIn = false
    @Published var currentUserId: UUID?
    @Published var userEmail: String?
    @Published var isLoading = false
    @Published var isCheckingSession = true  // Start true to prevent flash
    @Published var error: String?

    private let supabase = SupabaseService.shared

    private override init() {
        super.init()
        checkExistingSession()
    }

    // MARK: - Check Existing Session

    func checkExistingSession() {
        Task {
            defer { isCheckingSession = false }

            if let session = try? await supabase.client.auth.session {
                self.currentUserId = session.user.id
                self.userEmail = session.user.email
                self.isSignedIn = true
                print("AppleSignInService: Existing session found for user \(session.user.id)")
            } else {
                print("AppleSignInService: No existing session found")
            }
        }
    }

    // MARK: - Sign In with Apple

    func signIn() async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }

        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.email, .fullName]

        let result = try await performSignIn(request: request)

        guard let appleIDCredential = result.credential as? ASAuthorizationAppleIDCredential,
              let identityToken = appleIDCredential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            throw AppleSignInError.invalidCredential
        }

        // Sign in to Supabase with the Apple ID token
        let session = try await supabase.client.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: tokenString
            )
        )

        self.currentUserId = session.user.id
        self.userEmail = session.user.email
        self.isSignedIn = true

        print("AppleSignInService: Signed in successfully - User ID: \(session.user.id)")
    }

    // MARK: - Sign Out

    func signOut() async throws {
        try await supabase.client.auth.signOut()
        self.currentUserId = nil
        self.userEmail = nil
        self.isSignedIn = false
        print("AppleSignInService: Signed out")
    }

    // MARK: - Helper: Perform Sign In Request

    private func performSignIn(request: ASAuthorizationAppleIDRequest) async throws -> ASAuthorization {
        try await withCheckedThrowingContinuation { continuation in
            let controller = ASAuthorizationController(authorizationRequests: [request])
            let delegate = SignInDelegate(continuation: continuation)
            controller.delegate = delegate
            controller.performRequests()

            // Keep delegate alive
            objc_setAssociatedObject(controller, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)
        }
    }
}

// MARK: - Sign In Delegate

private class SignInDelegate: NSObject, ASAuthorizationControllerDelegate {
    let continuation: CheckedContinuation<ASAuthorization, Error>

    init(continuation: CheckedContinuation<ASAuthorization, Error>) {
        self.continuation = continuation
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        continuation.resume(returning: authorization)
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation.resume(throwing: error)
    }
}

// MARK: - Errors

enum AppleSignInError: LocalizedError {
    case invalidCredential
    case noIdentityToken

    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "Invalid Apple credential received"
        case .noIdentityToken:
            return "No identity token received from Apple"
        }
    }
}
