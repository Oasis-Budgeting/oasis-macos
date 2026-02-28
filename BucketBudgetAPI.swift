import Foundation

struct BucketBudgetConnection {
    var serverURL: String
    var token: String
}

struct BucketBudgetLoginRequest {
    let identifier: String
    let password: String
}

struct BucketBudgetLoginResponse: Decodable {
    let token: String
}

struct BucketBudgetDashboardResponse {
    let accounts: [BucketBudgetAccount]
    let transactions: [BucketBudgetTransaction]
    let budgetSummary: BucketBudgetSummary
    let spendingByCategory: [BucketBudgetSpendingCategory]
    let ageOfMoney: BucketBudgetAgeOfMoney
}

struct BucketBudgetAccount: Decodable, Identifiable {
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

struct BucketBudgetTransaction: Decodable, Identifiable {
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

struct BucketBudgetSummary: Decodable {
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

struct BucketBudgetSpendingCategory: Decodable, Identifiable {
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

struct BucketBudgetAgeOfMoney: Decodable {
    let age: Int
}

struct BucketBudgetGoal: Decodable, Identifiable {
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

struct BucketBudgetInsight: Decodable, Identifiable {
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

struct BucketBudgetIncomeExpensePoint: Decodable, Identifiable {
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

struct BucketBudgetSubscription: Decodable, Identifiable {
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

struct BucketBudgetInvestment: Decodable, Identifiable {
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

struct BucketBudgetDebt: Decodable, Identifiable {
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

struct BucketBudgetTransactionListResponse: Decodable {
    let data: [BucketBudgetTransaction]
}

struct BucketBudgetSettings {
    let currency: String
    let locale: String
}

struct BucketBudgetCreateAccountRequest: Encodable {
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

struct BucketBudgetCreateTransactionRequest: Encodable {
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

struct BucketBudgetCreateGoalRequest: Encodable {
    let name: String
    let targetAmount: Double
    let savedAmount: Double

    private enum CodingKeys: String, CodingKey {
        case name
        case targetAmount = "target_amount"
        case savedAmount = "saved_amount"
    }
}

struct BucketBudgetCreateSubscriptionRequest: Encodable {
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

struct BucketBudgetCreateInvestmentRequest: Encodable {
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

struct BucketBudgetCreateDebtRequest: Encodable {
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

struct BucketBudgetCategory: Decodable, Identifiable {
    let id: Int
    let name: String
}

struct BucketBudgetCategoryGroup: Decodable, Identifiable {
    let id: Int
    let name: String
    let categories: [BucketBudgetCategory]
}

struct BucketBudgetCreateCategoryGroupRequest: Encodable {
    let name: String
}

struct BucketBudgetCreateCategoryRequest: Encodable {
    let groupID: Int
    let name: String

    private enum CodingKeys: String, CodingKey {
        case groupID = "group_id"
        case name
    }
}

struct BucketBudgetAssignBudgetRequest: Encodable {
    let assigned: Double
}

enum BucketBudgetAPIError: LocalizedError {
    case invalidBaseURL
    case notConnected
    case invalidResponse
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidBaseURL:
            return "Server URL is invalid."
        case .notConnected:
            return "Connect to your Bucket Budget server first."
        case .invalidResponse:
            return "Unexpected response from the server."
        case .server(let message):
            return message
        }
    }
}

struct BucketBudgetAPIClient {
    let connection: BucketBudgetConnection

    func login(request: BucketBudgetLoginRequest) async throws -> BucketBudgetLoginResponse {
        let body = [
            "email": request.identifier,
            "username": request.identifier,
            "password": request.password
        ]
        return try await send(path: "/auth/login", method: "POST", body: body, includeToken: false)
    }

    func fetchDashboard(month: String) async throws -> BucketBudgetDashboardResponse {
        let accounts: [BucketBudgetAccount] = try await send(path: "/accounts")
        let transactionsResponse: BucketBudgetTransactionListResponse = try await send(path: "/transactions?limit=12")
        let summary: BucketBudgetSummary = try await send(path: "/budget/summary/\(month)")
        let ageOfMoney: BucketBudgetAgeOfMoney = try await send(path: "/settings/age-of-money")

        let dateRange = monthDateRange(for: month)
        let spendingPath = "/reports/spending-by-category?from=\(dateRange.from)&to=\(dateRange.to)"
        let spending: [BucketBudgetSpendingCategory] = try await send(path: spendingPath)

        return BucketBudgetDashboardResponse(
            accounts: accounts,
            transactions: transactionsResponse.data,
            budgetSummary: summary,
            spendingByCategory: spending,
            ageOfMoney: ageOfMoney
        )
    }

    func fetchTransactions(limit: Int = 200) async throws -> [BucketBudgetTransaction] {
        let response: BucketBudgetTransactionListResponse = try await send(path: "/transactions?limit=\(limit)")
        return response.data
    }

    func fetchGoals() async throws -> [BucketBudgetGoal] {
        try await send(path: "/goals")
    }

    func fetchInsights() async throws -> [BucketBudgetInsight] {
        try await send(path: "/insights")
    }

    func fetchIncomeVsExpense(months: Int = 6) async throws -> [BucketBudgetIncomeExpensePoint] {
        try await send(path: "/reports/income-vs-expense?months=\(months)")
    }

    func fetchSubscriptions() async throws -> [BucketBudgetSubscription] {
        try await send(path: "/subscriptions")
    }

    func fetchInvestments() async throws -> [BucketBudgetInvestment] {
        try await send(path: "/investments")
    }

    func fetchDebts() async throws -> [BucketBudgetDebt] {
        try await send(path: "/debts")
    }

    func fetchCategoryGroups() async throws -> [BucketBudgetCategoryGroup] {
        try await send(path: "/category-groups")
    }

    func fetchSettings() async throws -> BucketBudgetSettings {
        let raw: [String: String] = try await send(path: "/settings")
        return BucketBudgetSettings(
            currency: raw["currency"] ?? "USD",
            locale: raw["locale"] ?? "en-US"
        )
    }

    func createAccount(_ requestBody: BucketBudgetCreateAccountRequest) async throws -> BucketBudgetAccount {
        try await send(path: "/accounts", method: "POST", body: requestBody)
    }

    func createTransaction(_ requestBody: BucketBudgetCreateTransactionRequest) async throws -> BucketBudgetTransaction {
        try await send(path: "/transactions", method: "POST", body: requestBody)
    }

    func createGoal(_ requestBody: BucketBudgetCreateGoalRequest) async throws -> BucketBudgetGoal {
        try await send(path: "/goals", method: "POST", body: requestBody)
    }

    func createSubscription(_ requestBody: BucketBudgetCreateSubscriptionRequest) async throws -> BucketBudgetSubscription {
        try await send(path: "/subscriptions", method: "POST", body: requestBody)
    }

    func createInvestment(_ requestBody: BucketBudgetCreateInvestmentRequest) async throws -> BucketBudgetInvestment {
        try await send(path: "/investments", method: "POST", body: requestBody)
    }

    func createDebt(_ requestBody: BucketBudgetCreateDebtRequest) async throws -> BucketBudgetDebt {
        try await send(path: "/debts", method: "POST", body: requestBody)
    }

    func createCategoryGroup(name: String) async throws -> BucketBudgetCategoryGroup {
        try await send(path: "/category-groups", method: "POST", body: BucketBudgetCreateCategoryGroupRequest(name: name))
    }

    func createCategory(groupID: Int, name: String) async throws -> BucketBudgetCategory {
        try await send(path: "/categories", method: "POST", body: BucketBudgetCreateCategoryRequest(groupID: groupID, name: name))
    }

    func assignBudget(month: String, categoryID: Int, assigned: Double) async throws {
        let _: BucketBudgetAssignBudgetResponse = try await send(
            path: "/budget/\(month)/\(categoryID)",
            method: "PUT",
            body: BucketBudgetAssignBudgetRequest(assigned: assigned)
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
            throw BucketBudgetAPIError.invalidBaseURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if includeToken {
            guard !connection.token.isEmpty else {
                throw BucketBudgetAPIError.notConnected
            }
            request.setValue("Bearer \(connection.token)", forHTTPHeaderField: "Authorization")
        }

        if includeBody {
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BucketBudgetAPIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let apiError = try? JSONDecoder().decode(APIErrorMessage.self, from: data) {
                throw BucketBudgetAPIError.server(apiError.error)
            }
            throw BucketBudgetAPIError.server("Request failed with status code \(httpResponse.statusCode).")
        }

        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw BucketBudgetAPIError.server("Could not decode server response.")
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

private struct BucketBudgetAssignBudgetResponse: Decodable {
    let categoryID: Int

    private enum CodingKeys: String, CodingKey {
        case categoryID = "category_id"
    }
}

private struct EmptyRequestBody: Encodable {}
