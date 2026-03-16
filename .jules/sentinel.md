## 2026-03-07 - [Insecure Default URL Scheme]
**Vulnerability:** The API client defaulted to `http` for network requests when a URL scheme was omitted, risking unencrypted transmission of sensitive data and credentials.
**Learning:** Defaulting to plaintext HTTP can easily expose authentication tokens and financial data over insecure networks. Clients should strictly enforce HTTPS by default.
**Prevention:** Always default to `https` when constructing URLs from user input or configuration that lacks an explicit scheme to ensure secure communication by default.
## 2024-05-18 - [Insecure Token Storage via AppStorage]
**Vulnerability:** The authentication token `oasis.authToken` was stored in plaintext using SwiftUI's `@AppStorage`, which writes data unencrypted to `UserDefaults`.
**Learning:** `UserDefaults` should never be used to store sensitive information like passwords or session tokens as it can be easily read on a compromised or backed-up device.
**Prevention:** Always use the `Security` framework (`Keychain`) to persist sensitive credentials. A simple `TokenManager` utilizing `kSecClassGenericPassword` can be implemented to handle secure reads and writes.
## 2024-03-05 - Secure Memory Management for SwiftUI State
**Vulnerability:** Sensitive `@State` variables (like `formPassword`) retaining credentials in memory post-usage.
**Learning:** SwiftUI's declarative nature doesn't guarantee timely memory clearing of `@State` string properties. Passwords lingered in `formPassword` after login success/failure and after user disconnection, increasing memory exposure risk.
**Prevention:** Explicitly clear sensitive state variables immediately after their necessary scope (e.g., using `defer` blocks in authentication methods, or explicitly during `disconnect`).
## 2025-03-08 - [Insecure Keychain Token Storage via Missing Accessibility Key]
**Vulnerability:** The authentication token `oasis.authToken` was stored in the Keychain without specifying an accessibility attribute (`kSecAttrAccessible`). This could allow the token to be accessed when the device is locked or compromised.
**Learning:** When saving items to the Keychain, it's crucial to specify an accessibility attribute to ensure the data is only available when necessary (e.g., when the device is unlocked).
**Prevention:** Always include the `kSecAttrAccessible` key in Keychain storage queries for sensitive data, and set it to `kSecAttrAccessibleWhenUnlocked` (or an appropriate stricter value) to enforce data protection.
## 2026-03-08 - [Insecure UI State Rehydration]
**Vulnerability:** The authentication token `formToken` was exposed in memory and potentially the UI by being unconditionally hydrated from `storedAuthToken` in `.onAppear`, and left lingering after use.
**Learning:** Rehydrating sensitive credentials into active view state variables merely for UI convenience defeats the purpose of secure storage and increases the surface area for data leakage.
**Prevention:** Avoid populating view state (`@State`) with sensitive data on load. Instead, read from secure storage (like Keychain) only at the exact moment the data is required for an API call, and clear input fields immediately after login or submission.
