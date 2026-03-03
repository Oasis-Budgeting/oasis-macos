## 2024-05-18 - [Insecure Token Storage via AppStorage]
**Vulnerability:** The authentication token `oasis.authToken` was stored in plaintext using SwiftUI's `@AppStorage`, which writes data unencrypted to `UserDefaults`.
**Learning:** `UserDefaults` should never be used to store sensitive information like passwords or session tokens as it can be easily read on a compromised or backed-up device.
**Prevention:** Always use the `Security` framework (`Keychain`) to persist sensitive credentials. A simple `TokenManager` utilizing `kSecClassGenericPassword` can be implemented to handle secure reads and writes.

## 2024-05-24 - [Insecure Default Protocol Fallback]
**Vulnerability:** The `OasisAPIClient` automatically prepended `http://` instead of `https://` to server URLs if the scheme was omitted, potentially sending credentials and JWTs over unencrypted channels. Further, user inputted passwords remained in the UI state after logging out.
**Learning:** Defaulting to unencrypted transmission mechanisms introduces silent degradation of security for end users. Leaving secrets in memory state extends vulnerability lifespan.
**Prevention:** Always enforce secure defaults. `https://` should be the fallback schema. Any state-holding variables corresponding to credentials should be explicitly zeroed out when they are no longer required (e.g. following authentication or upon sign out).