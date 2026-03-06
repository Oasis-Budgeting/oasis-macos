## 2024-05-18 - [Insecure Token Storage via AppStorage]
**Vulnerability:** The authentication token `oasis.authToken` was stored in plaintext using SwiftUI's `@AppStorage`, which writes data unencrypted to `UserDefaults`.
**Learning:** `UserDefaults` should never be used to store sensitive information like passwords or session tokens as it can be easily read on a compromised or backed-up device.
**Prevention:** Always use the `Security` framework (`Keychain`) to persist sensitive credentials. A simple `TokenManager` utilizing `kSecClassGenericPassword` can be implemented to handle secure reads and writes.
## 2024-03-05 - Secure Memory Management for SwiftUI State
**Vulnerability:** Sensitive `@State` variables (like `formPassword`) retaining credentials in memory post-usage.
**Learning:** SwiftUI's declarative nature doesn't guarantee timely memory clearing of `@State` string properties. Passwords lingered in `formPassword` after login success/failure and after user disconnection, increasing memory exposure risk.
**Prevention:** Explicitly clear sensitive state variables immediately after their necessary scope (e.g., using `defer` blocks in authentication methods, or explicitly during `disconnect`).
## 2024-05-20 - [Insecure Default URL Scheme]
**Vulnerability:** The API client defaulted to `http` for backend connections when the user provided a URL without a scheme. This could result in sensitive data (auth tokens, financial data) being transmitted in plaintext if the user omitted `https://`.
**Learning:** Network clients should always "fail securely" or default to secure protocols. Assuming `http` for local or unspecified environments introduces unnecessary risk of man-in-the-middle (MITM) attacks if the app connects to remote servers.
**Prevention:** Default all schema-less network URLs to `https`. If explicit testing against local environments requires plaintext, it must be explicitly specified (e.g., `http://192.168.0.x`).
