// FLEXR - Supabase Auth Extension
// Provides currentSession computed property for backward compatibility
// Works around Supabase SDK API changes between versions

import Foundation
import Auth

extension AuthClient {
    /// Computed property to get current session synchronously
    /// Returns nil if no session exists or if session is expired
    ///
    /// Note: In Supabase 2.5.1, session access is async.
    /// This uses a Task to bridge to sync context.
    /// For new code, prefer `try await try? await client.auth.session`
    var currentSession: Session? {
        get {
            // Use Task to bridge async to sync
            // This is a temporary workaround
            var session: Session?
            let semaphore = DispatchSemaphore(value: 0)

            Task {
                do {
                    session = try await self.session
                } catch {
                    session = nil
                }
                semaphore.signal()
            }

            // Wait briefly for the session check
            _ = semaphore.wait(timeout: .now() + 0.5)
            return session
        }
    }
}
