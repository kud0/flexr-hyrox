// FLEXR Watch - Auth Service
// Handles Sign in with Apple on watchOS

import Foundation
import AuthenticationServices
import Supabase
import Observation

@Observable
@MainActor
final class WatchAuthService: NSObject {
    static let shared = WatchAuthService()

    var isSignedIn = false
    var currentUserId: UUID?
    var isLoading = false
    var error: String?

    private let client: SupabaseClient

    private override init() {
        let url = URL(string: "https://umvwmoxikxxxmxpwrsgc.supabase.co")!
        let key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVtdndtb3hpa3h4eG14cHdyc2djIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ2MDcyMDEsImV4cCI6MjA4MDE4MzIwMX0.ZGskBgfbsQD2uRZZJLCoAsXM4w87qNoF8PSZAXcSSyk"
        self.client = SupabaseClient(supabaseURL: url, supabaseKey: key)

        super.init()
        checkExistingSession()
    }

    // MARK: - Check Existing Session

    func checkExistingSession() {
        Task {
            do {
                let session = try await client.auth.session
                self.currentUserId = session.user.id
                self.isSignedIn = true
                // Update WatchPlanService with the user ID
                WatchPlanService.shared.setUserId(session.user.id)
                print("WatchAuthService: Existing session - User ID: \(session.user.id)")
            } catch {
                print("WatchAuthService: No existing session")
                self.isSignedIn = false
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
        request.requestedScopes = [.email]

        let result = try await performSignIn(request: request)

        guard let appleIDCredential = result.credential as? ASAuthorizationAppleIDCredential,
              let identityToken = appleIDCredential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            throw WatchAuthError.invalidCredential
        }

        // Sign in to Supabase
        let session = try await client.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: tokenString
            )
        )

        self.currentUserId = session.user.id
        self.isSignedIn = true

        // Update WatchPlanService with the authenticated user ID
        WatchPlanService.shared.setUserId(session.user.id)

        print("WatchAuthService: Signed in - User ID: \(session.user.id)")
    }

    // MARK: - Sign Out

    func signOut() async throws {
        try await client.auth.signOut()
        self.currentUserId = nil
        self.isSignedIn = false
        print("WatchAuthService: Signed out")
    }

    // MARK: - Simulator Bypass

    #if targetEnvironment(simulator)
    func simulatorSignIn() {
        // Use the same user ID from iPhone's Apple Sign-in for testing
        // This should match the userId you see in iPhone logs
        let testUserId = UUID(uuidString: "B638AD42-9C9D-40E1-9BF6-0DFFD6304761")!
        self.currentUserId = testUserId
        self.isSignedIn = true
        WatchPlanService.shared.setUserId(testUserId)
        print("WatchAuthService: Simulator sign-in with test user ID: \(testUserId)")
    }
    #endif

    // MARK: - Helper

    private func performSignIn(request: ASAuthorizationAppleIDRequest) async throws -> ASAuthorization {
        try await withCheckedThrowingContinuation { continuation in
            let controller = ASAuthorizationController(authorizationRequests: [request])
            let delegate = WatchSignInDelegate(continuation: continuation)
            controller.delegate = delegate
            controller.performRequests()
            objc_setAssociatedObject(controller, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)
        }
    }
}

// MARK: - Delegate

private class WatchSignInDelegate: NSObject, ASAuthorizationControllerDelegate {
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

enum WatchAuthError: LocalizedError {
    case invalidCredential

    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "Invalid Apple credential"
        }
    }
}
