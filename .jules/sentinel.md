## 2024-05-18 - [Insecure Token Storage via AppStorage]
**Vulnerability:** The authentication token `oasis.authToken` was stored in plaintext using SwiftUI's `@AppStorage`, which writes data unencrypted to `UserDefaults`.
**Learning:** `UserDefaults` should never be used to store sensitive information like passwords or session tokens as it can be easily read on a compromised or backed-up device.
**Prevention:** Always use the `Security` framework (`Keychain`) to persist sensitive credentials. A simple `TokenManager` utilizing `kSecClassGenericPassword` can be implemented to handle secure reads and writes.
## 2026-03-04 - [Insecure State Variable Exposure]
**Vulnerability:** Sensitive state variables like `formPassword` in `ContentView.swift` were being retained in memory after authentication attempts or disconnections, increasing the risk of memory scraping or exposure through core dumps.
**Learning:** In a UI framework like SwiftUI, sensitive state bound to text fields must be explicitly cleared to prevent prolonged memory exposure.
**Prevention:** Use `defer` blocks in authentication functions to ensure password state variables are cleared (e.g., `formPassword = ""`) regardless of the outcome, and always clear them in logout/disconnect handlers.
