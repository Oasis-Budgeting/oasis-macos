//
//  Bucket_BudgetUITests.swift
//  Bucket BudgetUITests
//
//  Created by Surya Vamsi on 28/02/26.
//

import XCTest

final class Bucket_BudgetUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("-ui-testing")
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testSidebarNavigationAndPrimaryScreensRender() throws {
        openSection("Dashboard", expect: "Dashboard")
        openSection("Accounts", expect: "Accounts")
        openSection("Buckets", expect: "Buckets")
        openSection("Transactions", expect: "Transactions")
        openSection("Goals", expect: "Goals")
        openSection("Subscriptions", expect: "Subscriptions")
        openSection("Investments", expect: "Investments")
        openSection("Debts", expect: "Debts")
        openSection("Reports", expect: "Reports")
        openSection("Settings", expect: "Settings")
    }

    @MainActor
    func testInlineInputsArePresentInEachScreen() throws {
        openSection("Transactions", expect: "Add Transaction")
        XCTAssertTrue(app.buttons["Create"].exists)
        XCTAssertTrue(app.textFields["Payee"].exists)
        XCTAssertTrue(app.textFields["Amount"].exists)

        openSection("Accounts", expect: "Add Account")
        XCTAssertTrue(app.textFields["Name"].exists)
        XCTAssertTrue(app.textFields["Starting Balance"].exists)
        XCTAssertTrue(app.buttons["Create Account"].exists)

        openSection("Goals", expect: "Add Goal")
        XCTAssertTrue(app.textFields["Target Amount"].exists)
        XCTAssertTrue(app.buttons["Create Goal"].exists)

        openSection("Subscriptions", expect: "Add Subscription")
        XCTAssertTrue(app.textFields["Payee"].exists)
        XCTAssertTrue(app.textFields["Amount"].exists)
        XCTAssertTrue(app.buttons["Create"].exists)

        openSection("Investments", expect: "Add Investment")
        XCTAssertTrue(app.textFields["Ticker"].exists)
        XCTAssertTrue(app.textFields["Current Price"].exists)
        XCTAssertTrue(app.buttons["Create"].exists)

        openSection("Debts", expect: "Add Debt")
        XCTAssertTrue(app.textFields["Balance"].exists)
        XCTAssertTrue(app.textFields["APR %"].exists)
        XCTAssertTrue(app.buttons["Create"].exists)

        openSection("Buckets", expect: "Budget Setup")
        XCTAssertTrue(app.textFields["Group Name"].exists)
        XCTAssertTrue(app.textFields["Category Name"].exists)
        XCTAssertTrue(app.textFields["Amount"].exists)
        XCTAssertTrue(app.buttons["Create Group"].exists)
        XCTAssertTrue(app.buttons["Create Category"].exists)
        XCTAssertTrue(app.buttons["Assign Budget"].exists)

        openSection("Settings", expect: "Connection")
        XCTAssertTrue(app.textFields["Server URL"].exists)
        XCTAssertTrue(app.textFields["Email or Username"].exists)
        XCTAssertTrue(app.secureTextFields["Password"].exists)
        XCTAssertTrue(app.secureTextFields["JWT Token"].exists)
        XCTAssertTrue(app.buttons["Login & Connect"].exists)
        XCTAssertTrue(app.buttons["Use Token"].exists)
    }

    @MainActor
    func testTransactionsSearchAndFilterControlsWork() throws {
        openSection("Transactions", expect: "Transactions")

        let searchField = app.textFields["Search payee, memo, account, category"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 3))
        clearAndType(searchField, text: "rent")

        XCTAssertFalse(searchField.value as? String == "Search payee, memo, account, category")
    }

    @MainActor
    func testConnectAndSyncWithTokenWhenConfigured() throws {
        let config = try requireLiveConfig()

        openSection("Settings", expect: "Connection")
        clearAndType(app.textFields["Server URL"], text: config.serverURL)
        clearAndType(app.secureTextFields["JWT Token"], text: config.token)
        app.buttons["Use Token"].tap()

        openSection("Settings", expect: "Server")
        XCTAssertTrue(app.staticTexts["Connected"].waitForExistence(timeout: 15))

        let syncButton = app.buttons["Sync"]
        XCTAssertTrue(syncButton.waitForExistence(timeout: 3))
        syncButton.tap()
        XCTAssertTrue(app.staticTexts["Connected"].waitForExistence(timeout: 15))
    }

    @MainActor
    func testCreateAccountGoalAndTransactionWhenConfigured() throws {
        let config = try requireLiveConfig()

        openSection("Settings", expect: "Connection")
        clearAndType(app.textFields["Server URL"], text: config.serverURL)
        clearAndType(app.secureTextFields["JWT Token"], text: config.token)
        app.buttons["Use Token"].tap()
        XCTAssertTrue(app.staticTexts["Connected"].waitForExistence(timeout: 15))

        let uniqueID = String(Int(Date().timeIntervalSince1970))
        let accountName = "E2E Account \(uniqueID)"
        let goalName = "E2E Goal \(uniqueID)"
        let payee = "E2E Payee \(uniqueID)"

        openSection("Accounts", expect: "Add Account")
        clearAndType(app.textFields["Name"], text: accountName)
        clearAndType(app.textFields["Starting Balance"], text: "1000")
        app.buttons["Create Account"].tap()
        XCTAssertTrue(app.staticTexts[accountName].waitForExistence(timeout: 20))

        openSection("Goals", expect: "Add Goal")
        clearAndType(app.textFields["Name"], text: goalName)
        clearAndType(app.textFields["Target Amount"], text: "500")
        clearAndType(app.textFields["Saved Amount"], text: "50")
        app.buttons["Create Goal"].tap()
        XCTAssertTrue(app.staticTexts[goalName].waitForExistence(timeout: 20))

        openSection("Transactions", expect: "Add Transaction")
        clearAndType(app.textFields["Payee"], text: payee)
        clearAndType(app.textFields["Memo"], text: "Created by UI E2E")
        clearAndType(app.textFields["Amount"], text: "12.34")
        app.buttons["Create"].tap()
        XCTAssertTrue(app.staticTexts[payee].waitForExistence(timeout: 25))
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    private func openSection(_ section: String, expect title: String) {
        let sectionCell = app.outlines["Sidebar"].staticTexts[section].firstMatch
        XCTAssertTrue(sectionCell.waitForExistence(timeout: 3), "Missing sidebar section \(section)")
        sectionCell.tap()
        XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 5), "Expected screen title \(title)")
    }

    private func clearAndType(_ element: XCUIElement, text: String) {
        XCTAssertTrue(element.waitForExistence(timeout: 3))
        element.tap()

        if let current = element.value as? String, !current.isEmpty, current != element.label {
            let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count)
            element.typeText(deleteString)
        }

        element.typeText(text)
    }

    private func requireLiveConfig() throws -> (serverURL: String, token: String) {
        let environment = ProcessInfo.processInfo.environment
        let runLive = environment["BB_E2E_RUN"] == "1"
        guard runLive else {
            throw XCTSkip("Live E2E disabled. Set BB_E2E_RUN=1 to enable.")
        }

        guard let serverURL = environment["BB_E2E_SERVER_URL"], !serverURL.isEmpty else {
            throw XCTSkip("Missing BB_E2E_SERVER_URL.")
        }
        guard let token = environment["BB_E2E_TOKEN"], !token.isEmpty else {
            throw XCTSkip("Missing BB_E2E_TOKEN.")
        }
        return (serverURL, token)
    }
}
