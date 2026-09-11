import SwiftData
import Foundation

@Model
final class Transaction {
    var id: UUID
    var amount: Decimal
    var currency: Currency
    var type: TransactionType
    var date: Date
    var note: String
    var category: Category?

    init(
        amount: Decimal,
        currency: Currency,
        type: TransactionType,
        date: Date = .now,
        note: String = "",
        category: Category? = nil
    ) {
        self.id = UUID()
        self.amount = amount
        self.currency = currency
        self.type = type
        self.date = date
        self.note = note
        self.category = category
    }

    var signedAmount: Decimal {
        type == .expense ? -amount : amount
    }
}
