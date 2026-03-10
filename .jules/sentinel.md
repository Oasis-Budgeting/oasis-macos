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
## 2025-03-08 - [Insecure Keychain Query Filtering]
**Vulnerability:** Adding the `kSecAttrAccessible` attribute to Keychain read (`SecItemCopyMatching`) or delete (`SecItemDelete`) queries acts as a strict search filter, not a security enforcement mechanism. It will fail to match existing items saved with different default accessibility levels, breaking backward compatibility and potentially preventing users from logging in.
**Learning:** Security constraints (like `kSecAttrAccessibleWhenUnlocked`) must be strictly enforced during the *write* operation (`SecItemAdd` or `SecItemUpdate`), not during the read or delete operations, to preserve functionality across different OS defaults or legacy saved states.
**Prevention:** Do not include `kSecAttrAccessible` in `kSecClassGenericPassword` read/delete queries unless you explicitly intend to filter out existing items saved with different access policies.

## 2025-03-08 - [UI State Exposing Sensitive Data]
**Vulnerability:** Rehydrating sensitive authentication tokens (`storedAuthToken`) into view state variables (`formToken`) upon view appearance (`.onAppear`) exposes credentials in plain text in the UI and keeps them lingering in memory.
**Learning:** Sensitive tokens used for backend authentication should not be bound to UI text fields for editing or display after initial entry.
**Prevention:** Remove UI rehydration logic for credentials, only update underlying stored tokens if the user actively inputs a new one, and ensure sensitive view states are cleared (e.g., using `defer`) immediately after use.
