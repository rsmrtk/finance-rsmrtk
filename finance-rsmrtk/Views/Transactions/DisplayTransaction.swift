import SwiftUI
import SwiftData

/// A transaction ready to render in a row, sourced from either local
/// SwiftData (guest mode) or the backend (signed-in mode). Views work with
/// this instead of the two underlying types directly.
struct DisplayTransaction: Identifiable {
    let id: String
    let categoryName: String
    let categoryIconName: String?
    let categoryColorHex: String?
    let note: String
    let amountText: String
    let tint: Color
    let date: Date
    let type: TransactionType
    let searchText: String
    let delete: () -> Void

    static func local(_ transaction: Transaction, modelContext: ModelContext) -> DisplayTransaction {
        DisplayTransaction(
            id: transaction.id.uuidString,
            categoryName: transaction.category?.name ?? "Без категорії",
            categoryIconName: transaction.category?.iconName,
            categoryColorHex: transaction.category?.colorHex,
            note: transaction.note,
            amountText: "\(transaction.type.sign)\(transaction.currency.formatted(transaction.amount))",
            tint: transaction.type.tint,
            date: transaction.date,
            type: transaction.type,
            searchText: "\(transaction.category?.name ?? "") \(transaction.note)",
            delete: { modelContext.delete(transaction) }
        )
    }

    static func remote(
        _ transaction: TransactionModel.Transaction,
        categories: [CategoryModel.Category],
        store: RemoteStore,
        onError: @escaping (String) -> Void
    ) -> DisplayTransaction {
        let category = categories.first { $0.id == transaction.categoryID }
        let type = TransactionType(protoType: transaction.type) ?? .expense
        let currency = Currency(protoCurrency: transaction.currency) ?? .uah
        let amount = Decimal(string: transaction.amount) ?? 0
        let date = ISO8601DateFormatter().date(from: transaction.date) ?? .now

        return DisplayTransaction(
            id: transaction.id,
            categoryName: category?.name ?? "Без категорії",
            categoryIconName: category?.iconName,
            categoryColorHex: category?.colorHex,
            note: transaction.note,
            amountText: "\(type.sign)\(currency.formatted(amount))",
            tint: type.tint,
            date: date,
            type: type,
            searchText: "\(category?.name ?? "") \(transaction.note)",
            delete: {
                Task {
                    do {
                        try await store.deleteTransaction(id: transaction.id)
                    } catch {
                        onError(error.localizedDescription)
                    }
                }
            }
        )
    }
}
