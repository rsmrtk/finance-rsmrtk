import Foundation
import Observation

enum BackendError: LocalizedError {
    case notSignedIn

    var errorDescription: String? {
        switch self {
        case .notSignedIn: "Спочатку увійдіть через Apple ID"
        }
    }
}

/// Holds data fetched from the finance-engine backend once the user is
/// signed in: categories, transactions, and exchange rates. Local SwiftData
/// stays the offline/guest-mode source of truth; this becomes the source of
/// truth once `AuthSession.isSignedIn` is true.
@Observable
final class RemoteStore {
    private(set) var categories: [CategoryModel.Category] = []
    private(set) var transactions: [TransactionModel.Transaction] = []
    var isSyncing = false
    var errorMessage: String?

    private let authSession: AuthSession
    private let rateStore: ExchangeRateStore

    init(authSession: AuthSession, rateStore: ExchangeRateStore) {
        self.authSession = authSession
        self.rateStore = rateStore
    }

    func reset() {
        categories = []
        transactions = []
        errorMessage = nil
    }

    func refreshAll() async {
        guard let token = authSession.accessToken else { return }

        isSyncing = true
        defer { isSyncing = false }

        do {
            async let categoriesTask = BackendClient.shared.listCategories(token: token)
            async let transactionsTask = BackendClient.shared.listTransactions(token: token)
            async let ratesTask = BackendClient.shared.listRates(token: token)

            categories = try await categoriesTask
            transactions = try await transactionsTask.sorted { $0.date > $1.date }

            let rateToUAH = Dictionary(uniqueKeysWithValues: try await ratesTask.compactMap { rate -> (Currency, Double)? in
                guard let currency = Currency(protoCurrency: rate.currency) else { return nil }
                return (currency, rate.rateToUah)
            })
            rateStore.applyRemoteRates(rateToUAH)

            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createCategory(name: String, iconName: String, colorHex: String, type: TransactionTypeModel.TransactionType) async throws {
        guard let token = authSession.accessToken else { throw BackendError.notSignedIn }
        let created = try await BackendClient.shared.createCategory(
            token: token, name: name, iconName: iconName, colorHex: colorHex, type: type
        )
        categories.append(created)
    }

    func deleteCategory(id: String) async throws {
        guard let token = authSession.accessToken else { throw BackendError.notSignedIn }
        try await BackendClient.shared.deleteCategory(token: token, categoryID: id)
        categories.removeAll { $0.id == id }
    }

    func createTransaction(
        amount: String,
        currency: CurrencyModel.Currency,
        type: TransactionTypeModel.TransactionType,
        date: String,
        note: String,
        categoryID: String
    ) async throws {
        guard let token = authSession.accessToken else { throw BackendError.notSignedIn }
        let created = try await BackendClient.shared.createTransaction(
            token: token, amount: amount, currency: currency, type: type, date: date, note: note, categoryID: categoryID
        )
        transactions.insert(created, at: 0)
    }

    func deleteTransaction(id: String) async throws {
        guard let token = authSession.accessToken else { throw BackendError.notSignedIn }
        try await BackendClient.shared.deleteTransaction(token: token, transactionID: id)
        transactions.removeAll { $0.id == id }
    }
}
