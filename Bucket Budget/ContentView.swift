//
//  ContentView.swift
//  Bucket Budget
//
//  Created by Surya Vamsi on 28/02/26.
//

import SwiftUI
import Charts

struct ContentView: View {
    @AppStorage("bb.serverURL") private var storedServerURL = "http://192.168.0.105:3003"
    @AppStorage("bb.authToken") private var storedAuthToken = ""
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var selectedSection: SidebarSection? = .dashboard
    @State private var selectedTransactionID: Int?
    @State private var transactionSearchText = ""
    @State private var transactionFilter: TransactionFilter = .all

    @State private var dashboard: BucketBudgetDashboardResponse?
    @State private var allTransactions: [BucketBudgetTransaction] = []
    @State private var goals: [BucketBudgetGoal] = []
    @State private var insights: [BucketBudgetInsight] = []
    @State private var incomeVsExpense: [BucketBudgetIncomeExpensePoint] = []
    @State private var subscriptions: [BucketBudgetSubscription] = []
    @State private var investments: [BucketBudgetInvestment] = []
    @State private var debts: [BucketBudgetDebt] = []
    @State private var categoryGroups: [BucketBudgetCategoryGroup] = []

    @State private var appCurrencyCode = "USD"
    @State private var appLocaleIdentifier = "en-US"

    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var lastSyncAt: Date?

    @State private var showConnectionSheet = false
    @State private var showAddTransactionSheet = false
    @State private var showAddGoalSheet = false
    @State private var showAddAccountSheet = false
    @State private var showAddSubscriptionSheet = false
    @State private var showAddInvestmentSheet = false
    @State private var showAddDebtSheet = false
    @State private var showAddCategoryGroupSheet = false
    @State private var showAddCategorySheet = false
    @State private var showAssignBudgetSheet = false
    @State private var hasLoaded = false

    @State private var formServerURL = ""
    @State private var formIdentifier = ""
    @State private var formPassword = ""
    @State private var formToken = ""
    @State private var isAuthenticating = false
    @State private var animateCharts = false
    @State private var selectedReportMonth: String?

    @State private var newTransactionAccountID: Int?
    @State private var newTransactionDate = Date.now
    @State private var newTransactionPayee = ""
    @State private var newTransactionMemo = ""
    @State private var newTransactionAmount = ""
    @State private var newTransactionCleared = false

    @State private var newGoalName = ""
    @State private var newGoalTargetAmount = ""
    @State private var newGoalSavedAmount = "0"

    @State private var newAccountName = ""
    @State private var newAccountType = "checking"
    @State private var newAccountBalance = "0"
    @State private var newAccountOnBudget = true

    @State private var newSubscriptionAccountID: Int?
    @State private var newSubscriptionType = "expense"
    @State private var newSubscriptionAmount = ""
    @State private var newSubscriptionFrequency = "monthly"
    @State private var newSubscriptionDate = Date.now
    @State private var newSubscriptionPayee = ""
    @State private var newSubscriptionMemo = ""

    @State private var newInvestmentTicker = ""
    @State private var newInvestmentName = ""
    @State private var newInvestmentAssetClass = "Stock"
    @State private var newInvestmentQuantity = "0"
    @State private var newInvestmentAveragePrice = "0"
    @State private var newInvestmentCurrentPrice = "0"

    @State private var newDebtName = ""
    @State private var newDebtType = "credit_card"
    @State private var newDebtBalance = "0"
    @State private var newDebtInterestRate = "0"
    @State private var newDebtMinimumPayment = "0"
    @State private var newDebtExtraPayment = "0"

    @State private var newCategoryGroupName = ""
    @State private var newCategoryGroupSelectionID: Int?
    @State private var newCategoryName = ""
    @State private var assignBudgetCategoryID: Int?
    @State private var assignBudgetAmount = ""

    private var isConnected: Bool {
        !storedServerURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !storedAuthToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var activeAccounts: [BucketBudgetAccount] {
        dashboard?.accounts.filter { !$0.closed } ?? []
    }

    private var availableAccounts: [BucketBudgetAccount] {
        dashboard?.accounts ?? []
    }

    private var totalBalance: Double {
        activeAccounts.reduce(0) { $0 + $1.balance }
    }

    private var monthlyIncome: Double {
        dashboard?.budgetSummary.monthIncome ?? 0
    }

    private var monthlyExpenses: Double {
        abs(dashboard?.budgetSummary.monthExpenses ?? 0)
    }

    private var projectedSavings: Double {
        monthlyIncome + (dashboard?.budgetSummary.monthExpenses ?? 0)
    }

    private var toBeBudgeted: Double {
        dashboard?.budgetSummary.toBeBudgeted ?? 0
    }

    private var ageOfMoney: Int {
        dashboard?.ageOfMoney.age ?? 0
    }

    private var filteredTransactions: [BucketBudgetTransaction] {
        let statusFiltered = allTransactions.filter { transaction in
            switch transactionFilter {
            case .all:
                return true
            case .cleared:
                return transaction.cleared
            case .pending:
                return !transaction.cleared
            }
        }

        guard !transactionSearchText.isEmpty else {
            return statusFiltered
        }

        return statusFiltered.filter {
            ($0.payee ?? "").localizedCaseInsensitiveContains(transactionSearchText) ||
            ($0.memo ?? "").localizedCaseInsensitiveContains(transactionSearchText) ||
            ($0.categoryName ?? "").localizedCaseInsensitiveContains(transactionSearchText) ||
            ($0.accountName ?? "").localizedCaseInsensitiveContains(transactionSearchText)
        }
    }

    private var selectedTransaction: BucketBudgetTransaction? {
        guard let selectedTransactionID else {
            return nil
        }

        return allTransactions.first(where: { $0.id == selectedTransactionID })
    }

    private var totalGoalTarget: Double {
        goals.reduce(0) { $0 + $1.targetAmount }
    }

    private var totalGoalSaved: Double {
        goals.reduce(0) { $0 + $1.savedAmount }
    }

    private var spendingCategories: [BucketBudgetSpendingCategory] {
        (dashboard?.spendingByCategory ?? []).sorted { $0.total > $1.total }
    }

    private var incomeSeries: [BucketBudgetIncomeExpensePoint] {
        incomeVsExpense.sorted { $0.month < $1.month }
    }

    private var appLocale: Locale {
        Locale(identifier: appLocaleIdentifier)
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            mainContent
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 1100, minHeight: 740)
        .background {
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.1, blue: 0.18),
                    Color(red: 0.1, green: 0.15, blue: 0.24),
                    Color(red: 0.12, green: 0.21, blue: 0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
        .environment(\.locale, appLocale)
        .environment(\.appCurrencyCode, appCurrencyCode)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    Task {
                        await refreshData()
                    }
                } label: {
                    Label("Sync", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.glassProminent)
                .disabled(isLoading || !isConnected)
            }
        }
        .animation(reduceMotion ? nil : .snappy(duration: 0.35, extraBounce: 0.04), value: selectedSection)
        .animation(reduceMotion ? nil : .smooth(duration: 0.45), value: dashboard?.transactions.count ?? 0)
        .overlay(alignment: .top) {
            if isLoading {
                ProgressView("Syncing with server")
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.top, 12)
            }
        }
        .onAppear {
            formServerURL = storedServerURL
            formToken = storedAuthToken

            guard !hasLoaded else {
                return
            }

            hasLoaded = true

            if isConnected {
                Task {
                    await refreshData()
                }
            }
        }
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            List(SidebarSection.allCases, selection: $selectedSection) { section in
                Label(section.title, systemImage: section.icon)
                    .tag(section)
            }
            .listStyle(.sidebar)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(isConnected ? .green : .orange)
                        .frame(width: 8, height: 8)
                    Text(isConnected ? "Connected" : "Disconnected")
                        .font(.caption.weight(.semibold))
                }

                Text(storedServerURL)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if let lastSyncAt {
                    Text("Synced \(lastSyncAt, format: .dateTime.hour().minute())")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .glassEffect(.regular.tint(.white.opacity(0.04)), in: .rect(cornerRadius: 14))
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .navigationTitle("Bucket Budget")
        .navigationSplitViewColumnWidth(min: 220, ideal: 250)
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            if let errorMessage {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(errorMessage)
                        .font(.subheadline)
                    Spacer()
                }
                .padding(12)
                .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }

            Group {
                switch selectedSection ?? .dashboard {
                case .dashboard:
                    dashboardScreen
                case .accounts:
                    accountsScreen
                case .buckets:
                    bucketsScreen
                case .transactions:
                    transactionsScreen
                case .goals:
                    goalsScreen
                case .subscriptions:
                    subscriptionsScreen
                case .investments:
                    investmentsScreen
                case .debts:
                    debtsScreen
                case .reports:
                    reportsScreen
                case .settings:
                    settingsScreen
                }
            }
            .id(selectedSection ?? .dashboard)
            .transition(.opacity.combined(with: .scale(scale: 0.985)))
            .padding(20)
        }
        .background(.clear)
    }

    private var dashboardScreen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                screenHeader(
                    title: "Dashboard",
                    subtitle: "A clean overview of your budget, spending, and account health."
                )

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    StatTile(title: "Total Balance", value: totalBalance, icon: "wallet.bifold", tint: .blue)
                    StatTile(title: "To Be Budgeted", value: toBeBudgeted, icon: "tray.full", tint: .indigo)
                    StatTile(title: "Monthly Expenses", value: monthlyExpenses, icon: "arrow.down.right", tint: .red)
                    StatTile(title: "Projected Savings", value: projectedSavings, icon: "leaf", tint: .green)
                }

                HStack(alignment: .top, spacing: 12) {
                    PanelCard(title: "Top Spending Categories") {
                        if let categories = dashboard?.spendingByCategory, !categories.isEmpty {
                            VStack(spacing: 10) {
                                ForEach(Array(categories.prefix(6).enumerated()), id: \.offset) { index, category in
                                    CategoryBarRow(
                                        name: category.category ?? "Uncategorized",
                                        amount: category.total,
                                        percentage: categoryShare(for: category.total),
                                        tint: paletteColor(index)
                                    )
                                }
                            }
                        } else {
                            emptyPanel("No spending data for this month.")
                        }
                    }

                    PanelCard(title: "Live Insights") {
                        if insights.isEmpty {
                            emptyPanel("No insights yet.")
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(Array(insights.prefix(4))) { insight in
                                    InsightRow(insight: insight)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: 360)
                }

                PanelCard(title: "Recent Transactions") {
                    if let recent = dashboard?.transactions, !recent.isEmpty {
                        SimpleTransactionList(transactions: recent)
                    } else {
                        emptyPanel("No recent transactions.")
                    }
                }
            }
        }
    }

    private var bucketsScreen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                screenHeader(
                    title: "Buckets",
                    subtitle: "Spending distribution across categories this month."
                )

                PanelCard(title: "Budget Setup") {
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Create Group")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            TextField("Group Name", text: $newCategoryGroupName)
                                .textFieldStyle(.roundedBorder)
                            Button("Create Group") {
                                Task { await createCategoryGroup() }
                            }
                            .buttonStyle(.glass)
                            .disabled(newCategoryGroupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !isConnected)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Create Category")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Picker("Group", selection: $newCategoryGroupSelectionID) {
                                Text("Select Group").tag(Optional<Int>.none)
                                ForEach(categoryGroups) { group in
                                    Text(group.name).tag(Optional(group.id))
                                }
                            }
                            .pickerStyle(.menu)
                            TextField("Category Name", text: $newCategoryName)
                                .textFieldStyle(.roundedBorder)
                            Button("Create Category") {
                                Task { await createCategory() }
                            }
                            .buttonStyle(.glass)
                            .disabled(newCategoryGroupSelectionID == nil || newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !isConnected)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Assign Budget")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Picker("Category", selection: $assignBudgetCategoryID) {
                                Text("Select Category").tag(Optional<Int>.none)
                                ForEach(categoryGroups, id: \.id) { group in
                                    ForEach(group.categories) { category in
                                        Text("\(group.name) • \(category.name)").tag(Optional(category.id))
                                    }
                                }
                            }
                            .pickerStyle(.menu)
                            TextField("Amount", text: $assignBudgetAmount)
                                .textFieldStyle(.roundedBorder)
                            Button("Assign Budget") {
                                Task { await assignBudgetToCategory() }
                            }
                            .buttonStyle(.glassProminent)
                            .disabled(assignBudgetCategoryID == nil || parsedNumber(assignBudgetAmount) == nil || !isConnected)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Text("Month: \(currentMonth())")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !spendingCategories.isEmpty {
                    PanelCard(title: "Category Mix") {
                        Chart(spendingCategories.prefix(8).enumerated().map { index, category in
                            SpendingSlice(
                                category: category.category ?? "Uncategorized",
                                total: category.total,
                                color: paletteColor(index)
                            )
                        }) { item in
                            SectorMark(
                                angle: .value("Amount", item.total),
                                innerRadius: .ratio(0.55),
                                outerRadius: .inset(10)
                            )
                            .foregroundStyle(item.color)
                            .cornerRadius(4)
                        }
                        .frame(height: 280)
                    }

                    VStack(spacing: 10) {
                        ForEach(Array(spendingCategories.enumerated()), id: \.offset) { index, category in
                            PanelCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(category.category ?? "Uncategorized")
                                            .font(.headline)
                                        Spacer()
                                        Text(category.total, format: .currency(code: appCurrencyCode))
                                            .font(.headline)
                                    }

                                    ProgressView(value: categoryShare(for: category.total))
                                        .tint(paletteColor(index))

                                    Text("\(Int(categoryShare(for: category.total) * 100))% of monthly spending")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                } else {
                    ContentUnavailableView("No Bucket Data", systemImage: "tray", description: Text("Categorized spending will appear here after you add transactions."))
                }
            }
        }
    }

    private var transactionsScreen: some View {
        VStack(alignment: .leading, spacing: 14) {
            screenHeader(
                title: "Transactions",
                subtitle: "Search and inspect your latest account activity."
            )

            PanelCard(title: "Add Transaction") {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Picker("Account", selection: $newTransactionAccountID) {
                            Text("Select Account").tag(Optional<Int>.none)
                            ForEach(availableAccounts) { account in
                                Text(account.name).tag(Optional(account.id))
                            }
                        }
                        .pickerStyle(.menu)
                        DatePicker("Date", selection: $newTransactionDate, displayedComponents: .date)
                        Toggle("Cleared", isOn: $newTransactionCleared)
                    }
                    .frame(maxWidth: 220, alignment: .leading)

                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Payee", text: $newTransactionPayee)
                            .textFieldStyle(.roundedBorder)
                        TextField("Memo", text: $newTransactionMemo)
                            .textFieldStyle(.roundedBorder)
                        HStack {
                            TextField("Amount", text: $newTransactionAmount)
                                .textFieldStyle(.roundedBorder)
                            Button("Create") {
                                Task { await createTransaction() }
                            }
                            .buttonStyle(.glassProminent)
                            .disabled(newTransactionAccountID == nil || parsedNumber(newTransactionAmount) == nil || !isConnected)
                        }
                    }
                }
            }

            PanelCard {
                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search payee, memo, account, category", text: $transactionSearchText)
                            .textFieldStyle(.plain)

                        if !transactionSearchText.isEmpty {
                            Button {
                                transactionSearchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                    Picker("Status", selection: $transactionFilter) {
                        ForEach(TransactionFilter.allCases) { filter in
                            Text(filter.title).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 230)

                    Text("\(filteredTransactions.count) items")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.08), in: Capsule())
                        .foregroundStyle(.secondary)
                }
            }

            HStack(alignment: .top, spacing: 12) {
                PanelCard {
                    VStack(spacing: 0) {
                        HStack {
                            Text("Date")
                                .font(.caption.weight(.semibold))
                                .frame(width: 120, alignment: .leading)
                            Text("Payee")
                                .font(.caption.weight(.semibold))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("Category")
                                .font(.caption.weight(.semibold))
                                .frame(width: 160, alignment: .leading)
                            Text("Amount")
                                .font(.caption.weight(.semibold))
                                .frame(width: 120, alignment: .trailing)
                            Text("Status")
                                .font(.caption.weight(.semibold))
                                .frame(width: 84, alignment: .center)
                        }
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.bottom, 8)

                        Divider()

                        ScrollView {
                            LazyVStack(spacing: 6) {
                                ForEach(filteredTransactions) { transaction in
                                    TransactionRow(
                                        transaction: transaction,
                                        isSelected: selectedTransactionID == transaction.id,
                                        currencyCode: appCurrencyCode
                                    ) {
                                        selectedTransactionID = transaction.id
                                    }
                                }
                            }
                            .padding(.top, 8)
                        }
                    }
                    .frame(minHeight: 420)
                }

                PanelCard(title: "Details") {
                    if let selectedTransaction {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(selectedTransaction.payee ?? "Untitled")
                                .font(.headline)
                            Text(selectedTransaction.date, format: .dateTime.weekday().month().day().year())
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Divider()

                            detailRow("Amount", value: selectedTransaction.amount.formatted(.currency(code: appCurrencyCode)))
                            detailRow("Category", value: selectedTransaction.categoryName ?? "-")
                            detailRow("Account", value: selectedTransaction.accountName ?? "-")
                            detailRow("Status", value: selectedTransaction.cleared ? "Cleared" : "Pending")

                            if let memo = selectedTransaction.memo, !memo.isEmpty {
                                Divider()
                                Text(memo)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer(minLength: 0)
                        }
                    } else {
                        emptyPanel("Select a transaction to inspect details.")
                    }
                }
                .frame(width: 300)
            }
        }
    }

    private var goalsScreen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                screenHeader(
                    title: "Goals",
                    subtitle: "Track progress toward savings and purchase targets."
                )

                PanelCard(title: "Add Goal") {
                    HStack(alignment: .top, spacing: 10) {
                        TextField("Name", text: $newGoalName)
                            .textFieldStyle(.roundedBorder)
                        TextField("Target Amount", text: $newGoalTargetAmount)
                            .textFieldStyle(.roundedBorder)
                        TextField("Saved Amount", text: $newGoalSavedAmount)
                            .textFieldStyle(.roundedBorder)
                        Button("Create Goal") {
                            Task { await createGoal() }
                        }
                        .buttonStyle(.glassProminent)
                        .disabled(newGoalName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || parsedNumber(newGoalTargetAmount) == nil || !isConnected)
                    }
                }

                HStack(spacing: 12) {
                    StatTile(title: "Goal Target", value: totalGoalTarget, icon: "target", tint: .indigo)
                    StatTile(title: "Saved", value: totalGoalSaved, icon: "banknote", tint: .green)
                    StatTile(title: "Remaining", value: max(totalGoalTarget - totalGoalSaved, 0), icon: "hourglass", tint: .orange)
                }

                if goals.isEmpty {
                    PanelCard {
                        ContentUnavailableView(
                            "No Goals Yet",
                            systemImage: "target",
                            description: Text("Create goals in your web app and they will appear here.")
                        )
                        .frame(maxWidth: .infinity, minHeight: 260)
                    }
                } else {
                    VStack(spacing: 10) {
                        ForEach(goals) { goal in
                            PanelCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("\(goal.icon ?? "🎯") \(goal.name)")
                                            .font(.headline)
                                        Spacer()
                                        Text(progressText(for: goal))
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                    }

                                    ProgressView(value: goalProgress(goal))
                                        .tint(goalColor(goal))

                                    HStack {
                                        Text(goal.savedAmount, format: .currency(code: appCurrencyCode))
                                        Text("of")
                                            .foregroundStyle(.secondary)
                                        Text(goal.targetAmount, format: .currency(code: appCurrencyCode))
                                        Spacer()
                                        Text(goal.status.capitalized)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(.secondary.opacity(0.2), in: Capsule())
                                    }
                                    .font(.caption)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var reportsScreen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                screenHeader(
                    title: "Reports",
                    subtitle: "Income and expense trends from your server data."
                )

                PanelCard(title: "Income vs Expense") {
                    if incomeSeries.isEmpty {
                        emptyPanel("No report data available.")
                    } else {
                        Chart {
                            ForEach(incomeSeries) { point in
                                AreaMark(
                                    x: .value("Month", point.month),
                                    y: .value("Income", animateCharts ? point.income : 0),
                                    series: .value("Series", "Income")
                                )
                                .foregroundStyle(.green.opacity(0.12))

                                LineMark(
                                    x: .value("Month", point.month),
                                    y: .value("Income", animateCharts ? point.income : 0),
                                    series: .value("Series", "Income")
                                )
                                .foregroundStyle(by: .value("Series", "Income"))
                                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))

                                LineMark(
                                    x: .value("Month", point.month),
                                    y: .value("Expense", animateCharts ? point.expenses : 0),
                                    series: .value("Series", "Expense")
                                )
                                .foregroundStyle(by: .value("Series", "Expense"))
                                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                                .interpolationMethod(.catmullRom)

                                if selectedReportMonth == point.month {
                                    RuleMark(x: .value("Selected", point.month))
                                        .foregroundStyle(.white.opacity(0.35))
                                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                                }
                            }
                        }
                        .chartForegroundStyleScale([
                            "Income": Color.green,
                            "Expense": Color.red
                        ])
                        .chartXSelection(value: $selectedReportMonth)
                        .chartLegend(position: .top, alignment: .leading)
                        .chartYAxis {
                            AxisMarks(values: .automatic(desiredCount: 4))
                        }
                        .frame(height: 280)
                    }
                }

                PanelCard(title: "Monthly Net") {
                    if incomeSeries.isEmpty {
                        emptyPanel("No net trend data.")
                    } else {
                        Chart(incomeSeries) { point in
                            let net = animateCharts ? (point.income - point.expenses) : 0
                            BarMark(
                                x: .value("Month", point.month),
                                y: .value("Net", net)
                            )
                            .foregroundStyle(net >= 0 ? .teal : .orange)
                            .cornerRadius(4)
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                        .frame(height: 220)
                    }
                }

                PanelCard(title: "Account Balances") {
                    if activeAccounts.isEmpty {
                        emptyPanel("No active accounts.")
                    } else {
                        Chart(activeAccounts) { account in
                            BarMark(
                                x: .value("Balance", animateCharts ? account.balance : 0),
                                y: .value("Account", account.name)
                            )
                            .foregroundStyle(account.balance < 0 ? .orange : .cyan)
                            .cornerRadius(4)
                        }
                        .frame(height: CGFloat(max(160, activeAccounts.count * 36)))
                    }
                }
            }
        }
    }

    private var accountsScreen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                screenHeader(
                    title: "Accounts",
                    subtitle: "Manage cash, credit, and investment accounts."
                )

                PanelCard(title: "Add Account") {
                    HStack(alignment: .top, spacing: 10) {
                        TextField("Name", text: $newAccountName)
                            .textFieldStyle(.roundedBorder)
                        Picker("Type", selection: $newAccountType) {
                            Text("Checking").tag("checking")
                            Text("Savings").tag("savings")
                            Text("Credit Card").tag("credit_card")
                            Text("Cash").tag("cash")
                            Text("Investment").tag("investment")
                        }
                        .pickerStyle(.menu)
                        .frame(width: 160)
                        TextField("Starting Balance", text: $newAccountBalance)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 140)
                        Toggle("On Budget", isOn: $newAccountOnBudget)
                            .toggleStyle(.switch)
                        Button("Create Account") {
                            Task { await createAccount() }
                        }
                        .buttonStyle(.glassProminent)
                        .disabled(newAccountName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || parsedNumber(newAccountBalance) == nil || !isConnected)
                    }
                }

                if dashboard?.accounts.isEmpty ?? true {
                    PanelCard {
                        ContentUnavailableView("No Accounts", systemImage: "wallet.bifold", description: Text("Create an account to start tracking balances."))
                            .frame(maxWidth: .infinity, minHeight: 220)
                    }
                } else {
                    VStack(spacing: 10) {
                        ForEach(dashboard?.accounts ?? []) { account in
                            PanelCard {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(account.name)
                                            .font(.headline)
                                        Text(account.type.replacingOccurrences(of: "_", with: " ").capitalized)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text(account.balance, format: .currency(code: appCurrencyCode))
                                        .font(.headline)
                                        .foregroundStyle(account.balance < 0 ? .orange : .primary)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var subscriptionsScreen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                screenHeader(
                    title: "Subscriptions",
                    subtitle: "Recurring transactions and bills synced from your backend."
                )

                PanelCard(title: "Add Subscription") {
                    HStack(alignment: .top, spacing: 10) {
                        Picker("Account", selection: $newSubscriptionAccountID) {
                            Text("Select Account").tag(Optional<Int>.none)
                            ForEach(availableAccounts) { account in
                                Text(account.name).tag(Optional(account.id))
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 170)

                        Picker("Type", selection: $newSubscriptionType) {
                            Text("Expense").tag("expense")
                            Text("Income").tag("income")
                        }
                        .pickerStyle(.menu)
                        .frame(width: 110)

                        Picker("Frequency", selection: $newSubscriptionFrequency) {
                            Text("Weekly").tag("weekly")
                            Text("Monthly").tag("monthly")
                            Text("Quarterly").tag("quarterly")
                            Text("Yearly").tag("yearly")
                        }
                        .pickerStyle(.menu)
                        .frame(width: 120)

                        DatePicker("Next Date", selection: $newSubscriptionDate, displayedComponents: .date)
                            .labelsHidden()
                            .frame(width: 140)
                        TextField("Payee", text: $newSubscriptionPayee)
                            .textFieldStyle(.roundedBorder)
                        TextField("Amount", text: $newSubscriptionAmount)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 120)
                        Button("Create") {
                            Task { await createSubscription() }
                        }
                        .buttonStyle(.glassProminent)
                        .disabled(newSubscriptionAccountID == nil || parsedNumber(newSubscriptionAmount) == nil || !isConnected)
                    }
                }

                if subscriptions.isEmpty {
                    PanelCard {
                        ContentUnavailableView("No Subscriptions", systemImage: "calendar.badge.clock", description: Text("Add recurring transactions to see them here."))
                            .frame(maxWidth: .infinity, minHeight: 220)
                    }
                } else {
                    VStack(spacing: 10) {
                        ForEach(subscriptions) { subscription in
                            PanelCard {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(subscription.payee?.isEmpty == false ? subscription.payee! : "Recurring Item")
                                            .font(.headline)
                                        Text("\(subscription.frequency.capitalized) • next \(subscription.nextDate)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text(subscription.amount, format: .currency(code: appCurrencyCode))
                                        .font(.headline)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var investmentsScreen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                screenHeader(
                    title: "Investments",
                    subtitle: "Portfolio holdings and XIRR synced from your backend."
                )

                PanelCard(title: "Add Investment") {
                    HStack(alignment: .top, spacing: 10) {
                        TextField("Ticker", text: $newInvestmentTicker)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 110)
                        TextField("Name", text: $newInvestmentName)
                            .textFieldStyle(.roundedBorder)
                        TextField("Asset Class", text: $newInvestmentAssetClass)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 130)
                        TextField("Qty", text: $newInvestmentQuantity)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 90)
                        TextField("Avg Price", text: $newInvestmentAveragePrice)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                        TextField("Current Price", text: $newInvestmentCurrentPrice)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 110)
                        Button("Create") {
                            Task { await createInvestment() }
                        }
                        .buttonStyle(.glassProminent)
                        .disabled(newInvestmentTicker.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || newInvestmentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !isConnected)
                    }
                }

                if investments.isEmpty {
                    PanelCard {
                        ContentUnavailableView("No Investments", systemImage: "chart.line.uptrend.xyaxis", description: Text("Add holdings to track performance here."))
                            .frame(maxWidth: .infinity, minHeight: 220)
                    }
                } else {
                    VStack(spacing: 10) {
                        ForEach(investments) { investment in
                            PanelCard {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(investment.ticker) • \(investment.name)")
                                            .font(.headline)
                                        Text(investment.assetClass)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text((investment.quantity * investment.currentPrice), format: .currency(code: appCurrencyCode))
                                            .font(.headline)
                                        if let xirr = investment.xirr {
                                            Text("XIRR \(xirr, format: .number.precision(.fractionLength(2)))%")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var debtsScreen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                screenHeader(
                    title: "Debts",
                    subtitle: "Debt balances and payoff plan synced from your backend."
                )

                PanelCard(title: "Add Debt") {
                    HStack(alignment: .top, spacing: 10) {
                        TextField("Name", text: $newDebtName)
                            .textFieldStyle(.roundedBorder)
                        Picker("Type", selection: $newDebtType) {
                            Text("Credit Card").tag("credit_card")
                            Text("Loan").tag("loan")
                            Text("Mortgage").tag("mortgage")
                            Text("Other").tag("other")
                        }
                        .pickerStyle(.menu)
                        .frame(width: 120)
                        TextField("Balance", text: $newDebtBalance)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 110)
                        TextField("APR %", text: $newDebtInterestRate)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 90)
                        TextField("Minimum", text: $newDebtMinimumPayment)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 110)
                        TextField("Extra", text: $newDebtExtraPayment)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                        Button("Create") {
                            Task { await createDebt() }
                        }
                        .buttonStyle(.glassProminent)
                        .disabled(newDebtName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || parsedNumber(newDebtBalance) == nil || !isConnected)
                    }
                }

                if debts.isEmpty {
                    PanelCard {
                        ContentUnavailableView("No Debts", systemImage: "creditcard", description: Text("Add debts to plan payoff strategies."))
                            .frame(maxWidth: .infinity, minHeight: 220)
                    }
                } else {
                    VStack(spacing: 10) {
                        ForEach(debts) { debt in
                            PanelCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(debt.name)
                                            .font(.headline)
                                        Spacer()
                                        Text(debt.balance, format: .currency(code: appCurrencyCode))
                                            .font(.headline)
                                    }

                                    HStack {
                                        Text("APR \(debt.interestRate, format: .number.precision(.fractionLength(2)))%")
                                        Spacer()
                                        if let months = debt.monthsToPayoff {
                                            Text("Payoff ~ \(months) months")
                                        }
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var settingsScreen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                screenHeader(
                    title: "Settings",
                    subtitle: "Connection and sync preferences for your self-hosted instance."
                )

                PanelCard(title: "Connection") {
                    VStack(alignment: .leading, spacing: 10) {
                        TextField("Server URL", text: $formServerURL)
                            .textFieldStyle(.roundedBorder)
                        HStack {
                            TextField("Email or Username", text: $formIdentifier)
                                .textFieldStyle(.roundedBorder)
                            SecureField("Password", text: $formPassword)
                                .textFieldStyle(.roundedBorder)
                            Button {
                                Task { await loginAndConnect() }
                            } label: {
                                if isAuthenticating {
                                    ProgressView()
                                } else {
                                    Text("Login & Connect")
                                }
                            }
                            .buttonStyle(.glassProminent)
                            .disabled(
                                isAuthenticating ||
                                formServerURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                                formIdentifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                                formPassword.isEmpty
                            )
                        }
                        HStack {
                            SecureField("JWT Token", text: $formToken)
                                .textFieldStyle(.roundedBorder)
                            Button("Use Token") {
                                Task { await connectWithToken() }
                            }
                            .buttonStyle(.glass)
                            .disabled(
                                formServerURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                                formToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            )
                        }
                    }
                }

                PanelCard(title: "Server") {
                    VStack(alignment: .leading, spacing: 10) {
                        detailRow("Server URL", value: storedServerURL)
                        detailRow("Token", value: storedAuthToken.isEmpty ? "Not set" : "Configured")
                        detailRow("Status", value: isConnected ? "Connected" : "Disconnected")
                        detailRow("Currency", value: appCurrencyCode)
                        detailRow("Locale", value: appLocaleIdentifier)
                        if let lastSyncAt {
                            detailRow("Last Sync", value: lastSyncAt.formatted(.dateTime.month().day().hour().minute()))
                        }

                        HStack {
                            Button("Edit Connection") {
                                showConnectionSheet = true
                            }
                            .buttonStyle(.glassProminent)

                            Button("Sync Now") {
                                Task {
                                    await refreshData()
                                }
                            }
                            .buttonStyle(.glass)
                            .disabled(isLoading || !isConnected)

                            Button("Disconnect") {
                                disconnect()
                            }
                            .buttonStyle(.glass)
                            .disabled(storedAuthToken.isEmpty)
                        }
                    }
                }

                PanelCard(title: "About") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Bucket Budget macOS")
                            .font(.headline)
                        Text("Native client for your self-hosted budget server.")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var connectionSheet: some View {
        NavigationStack {
            Form {
                Section("Server") {
                    TextField("URL", text: $formServerURL)
                }

                Section("Login") {
                    TextField("Email or Username", text: $formIdentifier)
                    SecureField("Password", text: $formPassword)

                    Button {
                        Task {
                            await loginAndConnect()
                        }
                    } label: {
                        HStack {
                            if isAuthenticating {
                                ProgressView()
                                    .controlSize(.small)
                            }
                            Text("Login & Connect")
                        }
                    }
                    .disabled(
                        isAuthenticating ||
                        formServerURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                        formIdentifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                        formPassword.isEmpty
                    )
                }

                Section("Or Use Existing Token") {
                    SecureField("JWT Token", text: $formToken)

                    Button("Save Token & Connect") {
                        Task {
                            await connectWithToken()
                        }
                    }
                    .disabled(
                        formServerURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                        formToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Connection")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        showConnectionSheet = false
                    }
                }
            }
        }
        .frame(minWidth: 520, minHeight: 420)
    }

    private var addTransactionSheet: some View {
        NavigationStack {
            Form {
                Section("Transaction") {
                    Picker("Account", selection: $newTransactionAccountID) {
                        ForEach(availableAccounts) { account in
                            Text(account.name).tag(Optional(account.id))
                        }
                    }

                    DatePicker("Date", selection: $newTransactionDate, displayedComponents: .date)
                    TextField("Payee", text: $newTransactionPayee)
                    TextField("Memo", text: $newTransactionMemo)
                    TextField("Amount", text: $newTransactionAmount)
                    Toggle("Cleared", isOn: $newTransactionCleared)
                }
            }
            .navigationTitle("Add Transaction")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showAddTransactionSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await createTransaction()
                        }
                    }
                    .disabled(newTransactionAccountID == nil || parsedNumber(newTransactionAmount) == nil)
                }
            }
        }
        .frame(minWidth: 480, minHeight: 340)
    }

    private var addGoalSheet: some View {
        NavigationStack {
            Form {
                Section("Goal") {
                    TextField("Name", text: $newGoalName)
                    TextField("Target Amount", text: $newGoalTargetAmount)
                    TextField("Saved Amount", text: $newGoalSavedAmount)
                }
            }
            .navigationTitle("Add Goal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showAddGoalSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await createGoal()
                        }
                    }
                    .disabled(newGoalName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || parsedNumber(newGoalTargetAmount) == nil)
                }
            }
        }
        .frame(minWidth: 420, minHeight: 280)
    }

    private var addAccountSheet: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    TextField("Name", text: $newAccountName)
                    Picker("Type", selection: $newAccountType) {
                        Text("Checking").tag("checking")
                        Text("Savings").tag("savings")
                        Text("Credit Card").tag("credit_card")
                        Text("Cash").tag("cash")
                        Text("Investment").tag("investment")
                    }
                    TextField("Starting Balance", text: $newAccountBalance)
                    Toggle("On Budget", isOn: $newAccountOnBudget)
                }
            }
            .navigationTitle("Add Account")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showAddAccountSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await createAccount()
                        }
                    }
                    .disabled(newAccountName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || parsedNumber(newAccountBalance) == nil)
                }
            }
        }
        .frame(minWidth: 440, minHeight: 300)
    }

    private var addSubscriptionSheet: some View {
        NavigationStack {
            Form {
                Section("Subscription") {
                    Picker("Account", selection: $newSubscriptionAccountID) {
                        ForEach(availableAccounts) { account in
                            Text(account.name).tag(Optional(account.id))
                        }
                    }
                    Picker("Type", selection: $newSubscriptionType) {
                        Text("Expense").tag("expense")
                        Text("Income").tag("income")
                    }
                    TextField("Amount", text: $newSubscriptionAmount)
                    Picker("Frequency", selection: $newSubscriptionFrequency) {
                        Text("Weekly").tag("weekly")
                        Text("Monthly").tag("monthly")
                        Text("Quarterly").tag("quarterly")
                        Text("Yearly").tag("yearly")
                    }
                    DatePicker("Next Date", selection: $newSubscriptionDate, displayedComponents: .date)
                    TextField("Payee", text: $newSubscriptionPayee)
                    TextField("Memo", text: $newSubscriptionMemo)
                }
            }
            .navigationTitle("Add Subscription")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAddSubscriptionSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await createSubscription() }
                    }
                    .disabled(newSubscriptionAccountID == nil || parsedNumber(newSubscriptionAmount) == nil)
                }
            }
        }
        .frame(minWidth: 460, minHeight: 360)
    }

    private var addInvestmentSheet: some View {
        NavigationStack {
            Form {
                Section("Investment") {
                    TextField("Ticker", text: $newInvestmentTicker)
                    TextField("Name", text: $newInvestmentName)
                    TextField("Asset Class", text: $newInvestmentAssetClass)
                    TextField("Quantity", text: $newInvestmentQuantity)
                    TextField("Average Price", text: $newInvestmentAveragePrice)
                    TextField("Current Price", text: $newInvestmentCurrentPrice)
                }
            }
            .navigationTitle("Add Investment")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAddInvestmentSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await createInvestment() }
                    }
                    .disabled(newInvestmentTicker.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || newInvestmentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .frame(minWidth: 460, minHeight: 360)
    }

    private var addDebtSheet: some View {
        NavigationStack {
            Form {
                Section("Debt") {
                    TextField("Name", text: $newDebtName)
                    Picker("Type", selection: $newDebtType) {
                        Text("Credit Card").tag("credit_card")
                        Text("Loan").tag("loan")
                        Text("Mortgage").tag("mortgage")
                        Text("Other").tag("other")
                    }
                    TextField("Balance", text: $newDebtBalance)
                    TextField("Interest Rate %", text: $newDebtInterestRate)
                    TextField("Minimum Payment", text: $newDebtMinimumPayment)
                    TextField("Extra Payment", text: $newDebtExtraPayment)
                }
            }
            .navigationTitle("Add Debt")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAddDebtSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await createDebt() }
                    }
                    .disabled(newDebtName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || parsedNumber(newDebtBalance) == nil)
                }
            }
        }
        .frame(minWidth: 460, minHeight: 360)
    }

    private var addCategoryGroupSheet: some View {
        NavigationStack {
            Form {
                Section("Category Group") {
                    TextField("Group Name", text: $newCategoryGroupName)
                }
            }
            .navigationTitle("Create Category Group")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAddCategoryGroupSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await createCategoryGroup() }
                    }
                    .disabled(newCategoryGroupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .frame(minWidth: 420, minHeight: 220)
    }

    private var addCategorySheet: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    Picker("Group", selection: $newCategoryGroupSelectionID) {
                        ForEach(categoryGroups) { group in
                            Text(group.name).tag(Optional(group.id))
                        }
                    }
                    TextField("Category Name", text: $newCategoryName)
                }
            }
            .navigationTitle("Create Category")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAddCategorySheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await createCategory() }
                    }
                    .disabled(newCategoryGroupSelectionID == nil || newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .frame(minWidth: 420, minHeight: 260)
    }

    private var assignBudgetSheet: some View {
        NavigationStack {
            Form {
                Section("Assign Budget") {
                    Picker("Category", selection: $assignBudgetCategoryID) {
                        ForEach(categoryGroups, id: \.id) { group in
                            ForEach(group.categories) { category in
                                Text("\(group.name) • \(category.name)").tag(Optional(category.id))
                            }
                        }
                    }
                    TextField("Amount", text: $assignBudgetAmount)
                }
            }
            .navigationTitle("Assign Budget")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAssignBudgetSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await assignBudgetToCategory() }
                    }
                    .disabled(assignBudgetCategoryID == nil || parsedNumber(assignBudgetAmount) == nil)
                }
            }
        }
        .frame(minWidth: 460, minHeight: 280)
    }

    @MainActor
    private func loginAndConnect() async {
        isAuthenticating = true
        errorMessage = nil

        defer {
            isAuthenticating = false
        }

        do {
            let client = BucketBudgetAPIClient(connection: .init(serverURL: formServerURL, token: ""))
            let loginResponse = try await client.login(request: .init(identifier: formIdentifier, password: formPassword))
            storedServerURL = formServerURL.trimmingCharacters(in: .whitespacesAndNewlines)
            storedAuthToken = loginResponse.token
            formToken = loginResponse.token
            showConnectionSheet = false
            await refreshData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func connectWithToken() async {
        storedServerURL = formServerURL.trimmingCharacters(in: .whitespacesAndNewlines)
        storedAuthToken = formToken.trimmingCharacters(in: .whitespacesAndNewlines)
        showConnectionSheet = false
        await refreshData()
    }

    @MainActor
    private func disconnect() {
        storedAuthToken = ""
        formToken = ""
        dashboard = nil
        allTransactions = []
        goals = []
        insights = []
        incomeVsExpense = []
        subscriptions = []
        investments = []
        debts = []
        categoryGroups = []
        selectedTransactionID = nil
        errorMessage = nil
    }

    @MainActor
    private func createTransaction() async {
        guard let accountID = newTransactionAccountID,
              let amount = parsedNumber(newTransactionAmount) else {
            errorMessage = "Select an account and enter a valid amount."
            return
        }

        do {
            let client = BucketBudgetAPIClient(connection: .init(serverURL: storedServerURL, token: storedAuthToken))
            _ = try await client.createTransaction(
                .init(
                    accountID: accountID,
                    date: apiDateString(from: newTransactionDate),
                    payee: newTransactionPayee,
                    memo: newTransactionMemo,
                    amount: amount,
                    cleared: newTransactionCleared
                )
            )
            showAddTransactionSheet = false
            resetAddForms()
            await refreshData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func createGoal() async {
        guard let target = parsedNumber(newGoalTargetAmount) else {
            errorMessage = "Enter a valid target amount."
            return
        }

        let saved = parsedNumber(newGoalSavedAmount) ?? 0

        do {
            let client = BucketBudgetAPIClient(connection: .init(serverURL: storedServerURL, token: storedAuthToken))
            _ = try await client.createGoal(.init(name: newGoalName, targetAmount: target, savedAmount: saved))
            showAddGoalSheet = false
            resetAddForms()
            await refreshData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func createAccount() async {
        guard let balance = parsedNumber(newAccountBalance) else {
            errorMessage = "Enter a valid starting balance."
            return
        }

        do {
            let client = BucketBudgetAPIClient(connection: .init(serverURL: storedServerURL, token: storedAuthToken))
            _ = try await client.createAccount(
                .init(
                    name: newAccountName,
                    type: newAccountType,
                    balance: balance,
                    onBudget: newAccountOnBudget
                )
            )
            showAddAccountSheet = false
            resetAddForms()
            await refreshData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func createSubscription() async {
        guard let accountID = newSubscriptionAccountID,
              let amount = parsedNumber(newSubscriptionAmount) else {
            errorMessage = "Choose an account and valid amount for subscription."
            return
        }

        do {
            let client = BucketBudgetAPIClient(connection: .init(serverURL: storedServerURL, token: storedAuthToken))
            _ = try await client.createSubscription(
                .init(
                    accountID: accountID,
                    type: newSubscriptionType,
                    amount: amount,
                    frequency: newSubscriptionFrequency,
                    nextDate: apiDateString(from: newSubscriptionDate),
                    payee: newSubscriptionPayee,
                    memo: newSubscriptionMemo
                )
            )
            showAddSubscriptionSheet = false
            resetAddForms()
            await refreshData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func createInvestment() async {
        guard let quantity = parsedNumber(newInvestmentQuantity),
              let averagePrice = parsedNumber(newInvestmentAveragePrice),
              let currentPrice = parsedNumber(newInvestmentCurrentPrice) else {
            errorMessage = "Enter valid numeric values for investment fields."
            return
        }

        do {
            let client = BucketBudgetAPIClient(connection: .init(serverURL: storedServerURL, token: storedAuthToken))
            _ = try await client.createInvestment(
                .init(
                    ticker: newInvestmentTicker,
                    name: newInvestmentName,
                    assetClass: newInvestmentAssetClass,
                    quantity: quantity,
                    averagePrice: averagePrice,
                    currentPrice: currentPrice
                )
            )
            showAddInvestmentSheet = false
            resetAddForms()
            await refreshData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func createDebt() async {
        guard let balance = parsedNumber(newDebtBalance),
              let interestRate = parsedNumber(newDebtInterestRate),
              let minimumPayment = parsedNumber(newDebtMinimumPayment),
              let extraPayment = parsedNumber(newDebtExtraPayment) else {
            errorMessage = "Enter valid debt values."
            return
        }

        do {
            let client = BucketBudgetAPIClient(connection: .init(serverURL: storedServerURL, token: storedAuthToken))
            _ = try await client.createDebt(
                .init(
                    name: newDebtName,
                    type: newDebtType,
                    balance: balance,
                    interestRate: interestRate,
                    minimumPayment: minimumPayment,
                    extraPayment: extraPayment
                )
            )
            showAddDebtSheet = false
            resetAddForms()
            await refreshData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func createCategoryGroup() async {
        do {
            let client = BucketBudgetAPIClient(connection: .init(serverURL: storedServerURL, token: storedAuthToken))
            _ = try await client.createCategoryGroup(name: newCategoryGroupName)
            showAddCategoryGroupSheet = false
            resetAddForms()
            await refreshData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func createCategory() async {
        guard let groupID = newCategoryGroupSelectionID else {
            errorMessage = "Select a category group first."
            return
        }

        do {
            let client = BucketBudgetAPIClient(connection: .init(serverURL: storedServerURL, token: storedAuthToken))
            _ = try await client.createCategory(groupID: groupID, name: newCategoryName)
            showAddCategorySheet = false
            resetAddForms()
            await refreshData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func assignBudgetToCategory() async {
        guard let categoryID = assignBudgetCategoryID,
              let amount = parsedNumber(assignBudgetAmount) else {
            errorMessage = "Select category and valid amount."
            return
        }

        do {
            let client = BucketBudgetAPIClient(connection: .init(serverURL: storedServerURL, token: storedAuthToken))
            try await client.assignBudget(month: currentMonth(), categoryID: categoryID, assigned: amount)
            showAssignBudgetSheet = false
            resetAddForms()
            await refreshData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func resetAddForms() {
        newTransactionAccountID = availableAccounts.first?.id
        newTransactionDate = .now
        newTransactionPayee = ""
        newTransactionMemo = ""
        newTransactionAmount = ""
        newTransactionCleared = false

        newGoalName = ""
        newGoalTargetAmount = ""
        newGoalSavedAmount = "0"

        newAccountName = ""
        newAccountType = "checking"
        newAccountBalance = "0"
        newAccountOnBudget = true

        newSubscriptionAccountID = availableAccounts.first?.id
        newSubscriptionType = "expense"
        newSubscriptionAmount = ""
        newSubscriptionFrequency = "monthly"
        newSubscriptionDate = .now
        newSubscriptionPayee = ""
        newSubscriptionMemo = ""

        newInvestmentTicker = ""
        newInvestmentName = ""
        newInvestmentAssetClass = "Stock"
        newInvestmentQuantity = "0"
        newInvestmentAveragePrice = "0"
        newInvestmentCurrentPrice = "0"

        newDebtName = ""
        newDebtType = "credit_card"
        newDebtBalance = "0"
        newDebtInterestRate = "0"
        newDebtMinimumPayment = "0"
        newDebtExtraPayment = "0"

        newCategoryGroupName = ""
        newCategoryGroupSelectionID = categoryGroups.first?.id
        newCategoryName = ""
        assignBudgetCategoryID = categoryGroups.flatMap(\.categories).first?.id
        assignBudgetAmount = ""
    }

    @MainActor
    private func refreshData() async {
        guard isConnected else {
            errorMessage = BucketBudgetAPIError.notConnected.localizedDescription
            return
        }

        isLoading = true
        errorMessage = nil
        animateCharts = false

        do {
            let month = currentMonth()
            let client = BucketBudgetAPIClient(connection: .init(serverURL: storedServerURL, token: storedAuthToken))

            let dashboardResponse = try await client.fetchDashboard(month: month)
            let transactionsResponse = try await client.fetchTransactions(limit: 200)
            let settingsResponse = (try? await client.fetchSettings()) ?? BucketBudgetSettings(currency: "USD", locale: "en-US")

            let goalsResponse = (try? await client.fetchGoals()) ?? []
            let insightsResponse = (try? await client.fetchInsights()) ?? []
            let incomeExpenseResponse = (try? await client.fetchIncomeVsExpense(months: 6)) ?? []
            let subscriptionsResponse = (try? await client.fetchSubscriptions()) ?? []
            let investmentsResponse = (try? await client.fetchInvestments()) ?? []
            let debtsResponse = (try? await client.fetchDebts()) ?? []
            let categoryGroupsResponse = (try? await client.fetchCategoryGroups()) ?? []

            dashboard = dashboardResponse
            allTransactions = transactionsResponse
            goals = goalsResponse
            insights = insightsResponse
            incomeVsExpense = incomeExpenseResponse.sorted { $0.month > $1.month }
            subscriptions = subscriptionsResponse
            investments = investmentsResponse
            debts = debtsResponse
            categoryGroups = categoryGroupsResponse
            appCurrencyCode = settingsResponse.currency
            appLocaleIdentifier = settingsResponse.locale

            if selectedTransactionID == nil {
                selectedTransactionID = transactionsResponse.first?.id
            }

            lastSyncAt = .now
            selectedReportMonth = nil

            if reduceMotion {
                animateCharts = true
            } else {
                withAnimation(.smooth(duration: 0.65)) {
                    animateCharts = true
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func currentMonth() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: .now)
    }

    private func apiDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func parsedNumber(_ value: String) -> Double? {
        let sanitized = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sanitized.isEmpty else {
            return nil
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = appLocale

        if let number = formatter.number(from: sanitized) {
            return number.doubleValue
        }

        return Double(sanitized.replacingOccurrences(of: ",", with: ""))
    }

    private func categoryShare(for amount: Double) -> Double {
        let total = (dashboard?.spendingByCategory.reduce(0) { $0 + $1.total } ?? 0)
        guard total > 0 else {
            return 0
        }
        return min(max(amount / total, 0), 1)
    }

    private func paletteColor(_ index: Int) -> Color {
        let palette: [Color] = [.blue, .green, .indigo, .orange, .pink, .teal, .mint]
        return palette[index % palette.count]
    }

    private func goalProgress(_ goal: BucketBudgetGoal) -> Double {
        guard goal.targetAmount > 0 else {
            return 0
        }
        return min(max(goal.savedAmount / goal.targetAmount, 0), 1)
    }

    private func progressText(for goal: BucketBudgetGoal) -> String {
        "\(Int(goalProgress(goal) * 100))%"
    }

    private func goalColor(_ goal: BucketBudgetGoal) -> Color {
        if let colorHex = goal.colorHex {
            return Color(hex: colorHex) ?? .indigo
        }
        return .indigo
    }

    @ViewBuilder
    private func screenHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.largeTitle.weight(.bold))
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func emptyPanel(_ message: String) -> some View {
        Text(message)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
    }

    @ViewBuilder
    private func detailRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}

private struct PanelCard<Content: View>: View {
    let title: String?
    @State private var isHovering = false
    @ViewBuilder var content: Content

    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title {
                Text(title)
                    .font(.headline)
            }
            content
        }
        .padding(14)
        .glassEffect(.regular.tint(.white.opacity(isHovering ? 0.11 : 0.07)).interactive(), in: .rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(isHovering ? 0.2 : 0.12), lineWidth: 1)
        }
        .scaleEffect(isHovering ? 1.006 : 1)
        .shadow(color: .black.opacity(isHovering ? 0.24 : 0.12), radius: isHovering ? 18 : 10, y: isHovering ? 10 : 4)
        .animation(.easeOut(duration: 0.18), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

private struct StatTile: View {
    @Environment(\.appCurrencyCode) private var appCurrencyCode
    let title: String
    let value: Double
    let icon: String
    let tint: Color
    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value, format: .currency(code: appCurrencyCode))
                .font(.title3.weight(.semibold))
                .contentTransition(.numericText())
            RoundedRectangle(cornerRadius: 2)
                .fill(tint.opacity(0.75))
                .frame(width: 56, height: 3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .glassEffect(.regular.tint(tint.opacity(isHovering ? 0.24 : 0.15)).interactive(), in: .rect(cornerRadius: 16))
        .scaleEffect(isHovering ? 1.01 : 1)
        .animation(.easeOut(duration: 0.16), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

private struct CategoryBarRow: View {
    @Environment(\.appCurrencyCode) private var appCurrencyCode
    let name: String
    let amount: Double
    let percentage: Double
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(name)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(amount, format: .currency(code: appCurrencyCode))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: percentage)
                .tint(tint)
        }
    }
}

private struct InsightRow: View {
    let insight: BucketBudgetInsight

    private var tint: Color {
        switch insight.severity.lowercased() {
        case "warning":
            return .orange
        case "success":
            return .green
        default:
            return .blue
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                Text(insight.icon ?? "💡")
                VStack(alignment: .leading, spacing: 2) {
                    Text(insight.title)
                        .font(.subheadline.weight(.semibold))
                    Text(insight.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(8)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct TransactionRow: View {
    let transaction: BucketBudgetTransaction
    let isSelected: Bool
    let currencyCode: String
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 10) {
                Text(transaction.date, format: .dateTime.year().month(.abbreviated).day())
                    .font(.caption)
                    .frame(width: 120, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    Text(transaction.payee ?? "-")
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                    Text(transaction.accountName ?? "-")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(transaction.categoryName ?? "-")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 160, alignment: .leading)
                    .lineLimit(1)

                Text(transaction.amount, format: .currency(code: currencyCode))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(transaction.amount < 0 ? .red : .green)
                    .frame(width: 120, alignment: .trailing)

                StatusPill(isCleared: transaction.cleared)
                    .frame(width: 84, alignment: .center)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.16) : Color.white.opacity(0.02))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? Color.accentColor.opacity(0.45) : Color.white.opacity(0.06), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct SimpleTransactionList: View {
    @Environment(\.appCurrencyCode) private var appCurrencyCode
    let transactions: [BucketBudgetTransaction]

    var body: some View {
        VStack(spacing: 8) {
            ForEach(transactions) { transaction in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(transaction.payee ?? "Untitled")
                            .font(.subheadline.weight(.medium))
                        Text(transaction.categoryName ?? "Uncategorized")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(transaction.amount, format: .currency(code: appCurrencyCode))
                            .foregroundStyle(transaction.amount < 0 ? .red : .green)
                        Text(transaction.date, format: .dateTime.month().day())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Divider()
            }
        }
    }
}

private struct SpendingSlice: Identifiable {
    let id = UUID()
    let category: String
    let total: Double
    let color: Color
}

private enum TransactionFilter: String, CaseIterable, Identifiable {
    case all
    case cleared
    case pending

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "All"
        case .cleared:
            return "Cleared"
        case .pending:
            return "Pending"
        }
    }
}

private struct StatusPill: View {
    let isCleared: Bool

    var body: some View {
        Text(isCleared ? "Cleared" : "Pending")
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background((isCleared ? Color.green : Color.orange).opacity(0.18), in: Capsule())
            .foregroundStyle(isCleared ? Color.green : Color.orange)
    }
}

private enum SidebarSection: String, CaseIterable, Identifiable {
    case dashboard
    case accounts
    case buckets
    case transactions
    case goals
    case subscriptions
    case investments
    case debts
    case reports
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard:
            return "Dashboard"
        case .accounts:
            return "Accounts"
        case .buckets:
            return "Buckets"
        case .transactions:
            return "Transactions"
        case .goals:
            return "Goals"
        case .subscriptions:
            return "Subscriptions"
        case .investments:
            return "Investments"
        case .debts:
            return "Debts"
        case .reports:
            return "Reports"
        case .settings:
            return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .dashboard:
            return "rectangle.grid.2x2"
        case .accounts:
            return "wallet.bifold"
        case .buckets:
            return "tray.full"
        case .transactions:
            return "list.bullet.rectangle"
        case .goals:
            return "target"
        case .subscriptions:
            return "calendar.badge.clock"
        case .investments:
            return "chart.line.uptrend.xyaxis"
        case .debts:
            return "creditcard"
        case .reports:
            return "chart.bar"
        case .settings:
            return "gearshape"
        }
    }
}

private struct AppCurrencyCodeKey: EnvironmentKey {
    static let defaultValue = "USD"
}

private extension EnvironmentValues {
    var appCurrencyCode: String {
        get { self[AppCurrencyCodeKey.self] }
        set { self[AppCurrencyCodeKey.self] = newValue }
    }
}

private extension Color {
    init?(hex: String) {
        let value = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        guard Scanner(string: value).scanHexInt64(&int) else {
            return nil
        }

        let red: UInt64
        let green: UInt64
        let blue: UInt64

        switch value.count {
        case 6:
            red = (int >> 16) & 0xFF
            green = (int >> 8) & 0xFF
            blue = int & 0xFF
        default:
            return nil
        }

        self.init(
            .sRGB,
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255,
            opacity: 1
        )
    }
}

#Preview {
    ContentView()
}
