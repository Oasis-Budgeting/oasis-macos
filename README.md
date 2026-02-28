# Oasis macOS (`oasis-macos`)

A native SwiftUI macOS app for personal budgeting, connected to a Oasis backend API.

The app provides a desktop-first finance dashboard with account tracking, bucket/category budgeting, transaction management, goals, recurring subscriptions, investments, and debt payoff visibility.

## Highlights

- Native SwiftUI app with a split-view layout and sidebar navigation
- Dashboard with key metrics:
  - Total balance
  - To-be-budgeted
  - Monthly expenses
  - Projected savings
  - Age of money
- Buckets workflow:
  - Create category groups
  - Create categories
  - Assign monthly budget amounts
  - Visualize spending mix with charts
- Transaction workflow:
  - Create transactions inline
  - Search by payee/memo/account/category
  - Filter by cleared/pending
- Asset and liability tracking:
  - Accounts
  - Goals
  - Subscriptions
  - Investments
  - Debts
- Server connection management directly in the app (URL + login/token)
- UI tests including optional live E2E flows

## Tech Stack

- Language: Swift 5
- UI: SwiftUI + Charts
- Networking: async/await with `URLSession`
- Unit testing: Apple `Testing` framework
- UI testing: `XCTest` (XCUI)

## Requirements

- macOS target configured in project: `MACOSX_DEPLOYMENT_TARGET = 26.2`
- Xcode with SwiftUI + Charts support

## Project Layout

```text
Oasis/
├─ Oasis/
│  ├─ OasisApp.swift
│  ├─ ContentView.swift
│  ├─ Item.swift
│  └─ Assets.xcassets/
├─ BucketBudgetAPI.swift
├─ OasisTests/
│  └─ OasisTests.swift
└─ OasisUITests/
   ├─ OasisUITests.swift
   └─ OasisUITestsLaunchTests.swift
```

## Getting Started

### 1. Clone

```bash
git clone https://github.com/Oasis-Budgeting/oasis-macos.git
cd oasis-macos
```

### 2. Open in Xcode

Open:

- `Oasis.xcodeproj`

### 3. Run

- Select the `Oasis` scheme
- Choose a macOS run destination
- Press Run

## App Configuration

The app stores connection settings using `@AppStorage` keys:

- `bb.serverURL`
- `bb.authToken`

Default server URL in current code:

- `http://192.168.0.105:3003`

Connection behavior:

- If server URL has no scheme, the client assumes `http`
- If base URL does not end with `/api`, the client auto-prefixes `/api`

Examples:

- `http://localhost:3003` -> requests sent to `http://localhost:3003/api/...`
- `https://example.com/api` -> requests sent to `https://example.com/api/...`

## Backend API Surface Used by the App

Authentication:

- `POST /auth/login`

Read endpoints:

- `GET /accounts`
- `GET /transactions?limit=...`
- `GET /budget/summary/{yyyy-MM}`
- `GET /settings/age-of-money`
- `GET /reports/spending-by-category?from=...&to=...`
- `GET /goals`
- `GET /insights`
- `GET /reports/income-vs-expense?months=...`
- `GET /subscriptions`
- `GET /investments`
- `GET /debts`
- `GET /category-groups`
- `GET /settings`

Write endpoints:

- `POST /accounts`
- `POST /transactions`
- `POST /goals`
- `POST /subscriptions`
- `POST /investments`
- `POST /debts`
- `POST /category-groups`
- `POST /categories`
- `PUT /budget/{yyyy-MM}/{categoryID}`

Auth header for protected endpoints:

- `Authorization: Bearer <token>`

## Testing

### Unit Tests

Uses Apple `Testing` framework (`OasisTests`).

Run from Xcode test navigator or with the test action for the app scheme.

### UI Tests

UI tests (`OasisUITests`) validate:

- Sidebar navigation rendering
- Presence of inline forms on major screens
- Transactions search/filter interaction
- Optional live server integration scenarios

#### Optional Live E2E UI Test Configuration

Set environment variables before running UI tests:

- `BB_E2E_RUN=1`
- `BB_E2E_SERVER_URL=<server-url>`
- `BB_E2E_TOKEN=<jwt-token>`

If these are missing, live E2E tests are skipped intentionally.

## Troubleshooting

- `Connect to your Oasis server first.`
  - Add a valid token in app Settings, then retry Sync.
- `Server URL is invalid.`
  - Verify host/port format (for example `http://localhost:3003`).
- `Could not decode server response.`
  - Backend payload shape likely differs from client models; verify API contract.
- App appears disconnected after relaunch
  - Confirm `bb.serverURL` and `bb.authToken` are persisted and not empty.

## Development Notes

- Main UI implementation lives in `Oasis/ContentView.swift`.
- API models/client live in `BucketBudgetAPI.swift`.
- The app uses a single-window SwiftUI entry point in `OasisApp.swift`.

## License

This repository includes a `LICENSE` file. See it for terms.
