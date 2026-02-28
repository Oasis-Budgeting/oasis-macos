import Foundation

struct OasisConnection {
    var serverURL: String
    var token: String
}

struct OasisLoginRequest {
    let identifier: String
    let password: String
}

struct OasisLoginResponse: Decodable {
    let token: String
}

struct OasisDashboardResponse {
    let accounts: [OasisAccount]
    let transactions: [OasisTransaction]
    let budgetSummary: OasisSummary
    let spendingByCategory: [OasisSpendingCategory]
    let ageOfMoney: OasisAgeOfMoney
}

struct OasisAccount: Decodable, Identifiable {
    let id: Int
    let name: String
    let type: String
    let balance: Double
    let closed: Bool

    private enum CodingKeys: String, CodingKey {
        case id, name, type, balance, closed
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(String.self, forKey: .type)
        balance = try container.decode(FlexibleDouble.self, forKey: .balance).value
        closed = try container.decodeIfPresent(Bool.self, forKey: .closed) ?? false
    }
}

struct OasisTransaction: Decodable, Identifiable {
    let id: Int
    let dateRaw: String
    let payee: String?
    let memo: String?
    let amount: Double
    let cleared: Bool
    let accountName: String?
    let categoryName: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case dateRaw = "date"
        case payee
        case memo
        case amount
        case cleared
        case accountName = "account_name"
        case categoryName = "category_name"
    }

    var date: Date {
        Self.dateFormatter.date(from: dateRaw) ?? .now
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        dateRaw = try container.decode(String.self, forKey: .dateRaw)
        payee = try container.decodeIfPresent(String.self, forKey: .payee)
        memo = try container.decodeIfPresent(String.self, forKey: .memo)
        amount = try container.decode(FlexibleDouble.self, forKey: .amount).value
        cleared = try container.decodeIfPresent(Bool.self, forKey: .cleared) ?? false
        accountName = try container.decodeIfPresent(String.self, forKey: .accountName)
        categoryName = try container.decodeIfPresent(String.self, forKey: .categoryName)
    }
}

struct OasisSummary: Decodable {
    let toBeBudgeted: Double
    let totalIncome: Double
    let totalAssigned: Double
    let monthIncome: Double
    let monthExpenses: Double
    let monthAssigned: Double

    private enum CodingKeys: String, CodingKey {
        case toBeBudgeted = "to_be_budgeted"
        case totalIncome = "total_income"
        case totalAssigned = "total_assigned"
        case monthIncome = "month_income"
        case monthExpenses = "month_expenses"
        case monthAssigned = "month_assigned"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        toBeBudgeted = try container.decode(FlexibleDouble.self, forKey: .toBeBudgeted).value
        totalIncome = try container.decode(FlexibleDouble.self, forKey: .totalIncome).value
        totalAssigned = try container.decode(FlexibleDouble.self, forKey: .totalAssigned).value
        monthIncome = try container.decode(FlexibleDouble.self, forKey: .monthIncome).value
        monthExpenses = try container.decode(FlexibleDouble.self, forKey: .monthExpenses).value
        monthAssigned = try container.decode(FlexibleDouble.self, forKey: .monthAssigned).value
    }
}

struct OasisSpendingCategory: Decodable, Identifiable {
    let id = UUID()
    let category: String?
    let total: Double

    private enum CodingKeys: String, CodingKey {
        case category
        case total
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        total = try container.decode(FlexibleDouble.self, forKey: .total).value
    }
}

struct OasisAgeOfMoney: Decodable {
    let age: Int
}

struct OasisGoal: Decodable, Identifiable {
    let id: Int
    let name: String
    let icon: String?
    let targetAmount: Double
    let savedAmount: Double
    let status: String
    let colorHex: String?
    let targetDate: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case icon
        case targetAmount = "target_amount"
        case savedAmount = "saved_amount"
        case status
        case colorHex = "color"
        case targetDate = "target_date"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        icon = try container.decodeIfPresent(String.self, forKey: .icon)
        targetAmount = try container.decode(FlexibleDouble.self, forKey: .targetAmount).value
        savedAmount = try container.decode(FlexibleDouble.self, forKey: .savedAmount).value
        status = try container.decodeIfPresent(String.self, forKey: .status) ?? "active"
        colorHex = try container.decodeIfPresent(String.self, forKey: .colorHex)
        targetDate = try container.decodeIfPresent(String.self, forKey: .targetDate)
    }
}

struct OasisInsight: Decodable, Identifiable {
    let id = UUID()
    let severity: String
    let title: String
    let description: String
    let icon: String?

    private enum CodingKeys: String, CodingKey {
        case severity
        case title
        case description
        case icon
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        severity = try container.decodeIfPresent(String.self, forKey: .severity) ?? "info"
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? "Insight"
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        icon = try container.decodeIfPresent(String.self, forKey: .icon)
    }
}

struct OasisIncomeExpensePoint: Decodable, Identifiable {
    var id: String { month }
    let month: String
    let income: Double
    let expenses: Double

    private enum CodingKeys: String, CodingKey {
        case month
        case income
        case expenses
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        month = try container.decode(String.self, forKey: .month)
        income = try container.decode(FlexibleDouble.self, forKey: .income).value
        expenses = try container.decode(FlexibleDouble.self, forKey: .expenses).value
    }
}

struct OasisSubscription: Decodable, Identifiable {
    let id: Int
    let accountName: String?
    let categoryName: String?
    let type: String
    let amount: Double
    let payee: String?
    let memo: String?
    let frequency: String
    let nextDate: String
    let status: String

    private enum CodingKeys: String, CodingKey {
        case id
        case accountName = "account_name"
        case categoryName = "category_name"
        case type
        case amount
        case payee
        case memo
        case frequency
        case nextDate = "next_date"
        case status
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        accountName = try container.decodeIfPresent(String.self, forKey: .accountName)
        categoryName = try container.decodeIfPresent(String.self, forKey: .categoryName)
        type = try container.decodeIfPresent(String.self, forKey: .type) ?? "expense"
        amount = try container.decode(FlexibleDouble.self, forKey: .amount).value
        payee = try container.decodeIfPresent(String.self, forKey: .payee)
        memo = try container.decodeIfPresent(String.self, forKey: .memo)
        frequency = try container.decodeIfPresent(String.self, forKey: .frequency) ?? "monthly"
        nextDate = try container.decodeIfPresent(String.self, forKey: .nextDate) ?? ""
        status = try container.decodeIfPresent(String.self, forKey: .status) ?? "active"
    }
}

struct OasisInvestment: Decodable, Identifiable {
    let id: Int
    let ticker: String
    let name: String
    let assetClass: String
    let quantity: Double
    let averagePrice: Double
    let currentPrice: Double
    let xirr: Double?

    private enum CodingKeys: String, CodingKey {
        case id
        case ticker
        case name
        case assetClass = "asset_class"
        case quantity
        case averagePrice = "average_price"
        case currentPrice = "current_price"
        case xirr
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        ticker = try container.decodeIfPresent(String.self, forKey: .ticker) ?? ""
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        assetClass = try container.decodeIfPresent(String.self, forKey: .assetClass) ?? "Stock"
        quantity = try container.decode(FlexibleDouble.self, forKey: .quantity).value
        averagePrice = try container.decode(FlexibleDouble.self, forKey: .averagePrice).value
        currentPrice = try container.decode(FlexibleDouble.self, forKey: .currentPrice).value
        xirr = (try? container.decode(FlexibleDouble.self, forKey: .xirr).value)
    }
}

struct OasisDebt: Decodable, Identifiable {
    let id: Int
    let name: String
    let type: String
    let balance: Double
    let interestRate: Double
    let minimumPayment: Double
    let extraPayment: Double
    let monthsToPayoff: Int?
    let totalInterest: Double?
    let payoffDate: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case type
        case balance
        case interestRate = "interest_rate"
        case minimumPayment = "minimum_payment"
        case extraPayment = "extra_payment"
        case monthsToPayoff = "months_to_payoff"
        case totalInterest = "total_interest"
        case payoffDate = "payoff_date"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        type = try container.decodeIfPresent(String.self, forKey: .type) ?? "debt"
        balance = try container.decode(FlexibleDouble.self, forKey: .balance).value
        interestRate = try container.decode(FlexibleDouble.self, forKey: .interestRate).value
        minimumPayment = try container.decode(FlexibleDouble.self, forKey: .minimumPayment).value
        extraPayment = try container.decode(FlexibleDouble.self, forKey: .extraPayment).value
        monthsToPayoff = try container.decodeIfPresent(Int.self, forKey: .monthsToPayoff)
        totalInterest = (try? container.decode(FlexibleDouble.self, forKey: .totalInterest).value)
        payoffDate = try container.decodeIfPresent(String.self, forKey: .payoffDate)
    }
}

struct FlexibleDouble: Decodable {
    let value: Double

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let double = try? container.decode(Double.self) {
            value = double
            return
        }
        if let int = try? container.decode(Int.self) {
            value = Double(int)
            return
        }
        if let string = try? container.decode(String.self), let double = Double(string) {
            value = double
            return
        }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported numeric format")
    }
}

struct OasisTransactionListResponse: Decodable {
    let data: [OasisTransaction]
}

struct OasisSettings {
    let currency: String
    let locale: String
}

struct OasisCreateAccountRequest: Encodable {
    let name: String
    let type: String
    let balance: Double
    let onBudget: Bool

    private enum CodingKeys: String, CodingKey {
        case name
        case type
        case balance
        case onBudget = "on_budget"
    }
}

struct OasisCreateTransactionRequest: Encodable {
    let accountID: Int
    let date: String
    let payee: String
    let memo: String
    let amount: Double
    let cleared: Bool

    private enum CodingKeys: String, CodingKey {
        case accountID = "account_id"
        case date
        case payee
        case memo
        case amount
        case cleared
    }
}

struct OasisCreateGoalRequest: Encodable {
    let name: String
    let targetAmount: Double
    let savedAmount: Double

    private enum CodingKeys: String, CodingKey {
        case name
        case targetAmount = "target_amount"
        case savedAmount = "saved_amount"
    }
}

struct OasisCreateSubscriptionRequest: Encodable {
    let accountID: Int
    let type: String
    let amount: Double
    let frequency: String
    let nextDate: String
    let payee: String
    let memo: String

    private enum CodingKeys: String, CodingKey {
        case accountID = "account_id"
        case type
        case amount
        case frequency
        case nextDate = "next_date"
        case payee
        case memo
    }
}

struct OasisCreateInvestmentRequest: Encodable {
    let ticker: String
    let name: String
    let assetClass: String
    let quantity: Double
    let averagePrice: Double
    let currentPrice: Double

    private enum CodingKeys: String, CodingKey {
        case ticker
        case name
        case assetClass = "asset_class"
        case quantity
        case averagePrice = "average_price"
        case currentPrice = "current_price"
    }
}

struct OasisCreateDebtRequest: Encodable {
    let name: String
    let type: String
    let balance: Double
    let interestRate: Double
    let minimumPayment: Double
    let extraPayment: Double

    private enum CodingKeys: String, CodingKey {
        case name
        case type
        case balance
        case interestRate = "interest_rate"
        case minimumPayment = "minimum_payment"
        case extraPayment = "extra_payment"
    }
}

struct OasisCategory: Decodable, Identifiable {
    let id: Int
    let name: String
}

struct OasisCategoryGroup: Decodable, Identifiable {
    let id: Int
    let name: String
    let categories: [OasisCategory]
}

struct OasisCreateCategoryGroupRequest: Encodable {
    let name: String
}

struct OasisCreateCategoryRequest: Encodable {
    let groupID: Int
    let name: String

    private enum CodingKeys: String, CodingKey {
        case groupID = "group_id"
        case name
    }
}

struct OasisAssignBudgetRequest: Encodable {
    let assigned: Double
}

enum OasisAPIError: LocalizedError {
    case invalidBaseURL
    case notConnected
    case invalidResponse
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidBaseURL:
            return "Server URL is invalid."
        case .notConnected:
            return "Connect to your Oasis server first."
        case .invalidResponse:
            return "Unexpected response from the server."
        case .server(let message):
            return message
        }
    }
}

struct OasisAPIClient {
    let connection: OasisConnection

    func login(request: OasisLoginRequest) async throws -> OasisLoginResponse {
        let body = [
            "email": request.identifier,
            "username": request.identifier,
            "password": request.password
        ]
        return try await send(path: "/auth/login", method: "POST", body: body, includeToken: false)
    }

    func fetchDashboard(month: String) async throws -> OasisDashboardResponse {
        let accounts: [OasisAccount] = try await send(path: "/accounts")
        let transactionsResponse: OasisTransactionListResponse = try await send(path: "/transactions?limit=12")
        let summary: OasisSummary = try await send(path: "/budget/summary/\(month)")
        let ageOfMoney: OasisAgeOfMoney = try await send(path: "/settings/age-of-money")

        let dateRange = monthDateRange(for: month)
        let spendingPath = "/reports/spending-by-category?from=\(dateRange.from)&to=\(dateRange.to)"
        let spending: [OasisSpendingCategory] = try await send(path: spendingPath)

        return OasisDashboardResponse(
            accounts: accounts,
            transactions: transactionsResponse.data,
            budgetSummary: summary,
            spendingByCategory: spending,
            ageOfMoney: ageOfMoney
        )
    }

    func fetchTransactions(limit: Int = 200) async throws -> [OasisTransaction] {
        let response: OasisTransactionListResponse = try await send(path: "/transactions?limit=\(limit)")
        return response.data
    }

    func fetchGoals() async throws -> [OasisGoal] {
        try await send(path: "/goals")
    }

    func fetchInsights() async throws -> [OasisInsight] {
        try await send(path: "/insights")
    }

    func fetchIncomeVsExpense(months: Int = 6) async throws -> [OasisIncomeExpensePoint] {
        try await send(path: "/reports/income-vs-expense?months=\(months)")
    }

    func fetchSubscriptions() async throws -> [OasisSubscription] {
        try await send(path: "/subscriptions")
    }

    func fetchInvestments() async throws -> [OasisInvestment] {
        try await send(path: "/investments")
    }

    func fetchDebts() async throws -> [OasisDebt] {
        try await send(path: "/debts")
    }

    func fetchCategoryGroups() async throws -> [OasisCategoryGroup] {
        try await send(path: "/category-groups")
    }

    func fetchSettings() async throws -> OasisSettings {
        let raw: [String: String] = try await send(path: "/settings")
        return OasisSettings(
            currency: raw["currency"] ?? "USD",
            locale: raw["locale"] ?? "en-US"
        )
    }

    func createAccount(_ requestBody: OasisCreateAccountRequest) async throws -> OasisAccount {
        try await send(path: "/accounts", method: "POST", body: requestBody)
    }

    func createTransaction(_ requestBody: OasisCreateTransactionRequest) async throws -> OasisTransaction {
        try await send(path: "/transactions", method: "POST", body: requestBody)
    }

    func createGoal(_ requestBody: OasisCreateGoalRequest) async throws -> OasisGoal {
        try await send(path: "/goals", method: "POST", body: requestBody)
    }

    func createSubscription(_ requestBody: OasisCreateSubscriptionRequest) async throws -> OasisSubscription {
        try await send(path: "/subscriptions", method: "POST", body: requestBody)
    }

    func createInvestment(_ requestBody: OasisCreateInvestmentRequest) async throws -> OasisInvestment {
        try await send(path: "/investments", method: "POST", body: requestBody)
    }

    func createDebt(_ requestBody: OasisCreateDebtRequest) async throws -> OasisDebt {
        try await send(path: "/debts", method: "POST", body: requestBody)
    }

    func createCategoryGroup(name: String) async throws -> OasisCategoryGroup {
        try await send(path: "/category-groups", method: "POST", body: OasisCreateCategoryGroupRequest(name: name))
    }

    func createCategory(groupID: Int, name: String) async throws -> OasisCategory {
        try await send(path: "/categories", method: "POST", body: OasisCreateCategoryRequest(groupID: groupID, name: name))
    }

    func assignBudget(month: String, categoryID: Int, assigned: Double) async throws {
        let _: OasisAssignBudgetResponse = try await send(
            path: "/budget/\(month)/\(categoryID)",
            method: "PUT",
            body: OasisAssignBudgetRequest(assigned: assigned)
        )
    }

    private func send<Response: Decodable>(
        path: String,
        method: String = "GET",
        includeToken: Bool = true
    ) async throws -> Response {
        try await send(path: path, method: method, body: EmptyRequestBody(), includeToken: includeToken, includeBody: false)
    }

    private func send<Response: Decodable, Body: Encodable>(
        path: String,
        method: String = "GET",
        body: Body,
        includeToken: Bool = true,
        includeBody: Bool = true
    ) async throws -> Response {
        guard let url = makeURL(path: path) else {
            throw OasisAPIError.invalidBaseURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if includeToken {
            guard !connection.token.isEmpty else {
                throw OasisAPIError.notConnected
            }
            request.setValue("Bearer \(connection.token)", forHTTPHeaderField: "Authorization")
        }

        if includeBody {
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OasisAPIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let apiError = try? JSONDecoder().decode(APIErrorMessage.self, from: data) {
                throw OasisAPIError.server(apiError.error)
            }
            throw OasisAPIError.server("Request failed with status code \(httpResponse.statusCode).")
        }

        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw OasisAPIError.server("Could not decode server response.")
        }
    }

    private func makeURL(path: String) -> URL? {
        guard var components = URLComponents(string: connection.serverURL.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return nil
        }

        if components.scheme == nil {
            components.scheme = "http"
        }

        guard var baseURL = components.url else {
            return nil
        }

        if baseURL.path.hasSuffix("/") {
            baseURL.deleteLastPathComponent()
        }

        let basePath: String
        if baseURL.path.hasSuffix("/api") {
            basePath = ""
        } else {
            basePath = "/api"
        }

        return URL(string: "\(baseURL.absoluteString)\(basePath)\(path)")
    }

    private func monthDateRange(for month: String) -> (from: String, to: String) {
        let from = "\(month)-01"
        let to = "\(month)-31"
        return (from, to)
    }
}

private struct APIErrorMessage: Decodable {
    let error: String
}

private struct OasisAssignBudgetResponse: Decodable {
    let categoryID: Int

    private enum CodingKeys: String, CodingKey {
        case categoryID = "category_id"
    }
}

private struct EmptyRequestBody: Encodable {}
