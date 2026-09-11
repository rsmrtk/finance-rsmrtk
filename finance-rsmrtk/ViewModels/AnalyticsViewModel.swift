import Foundation
import SwiftUI

enum AnalyticsPeriod: String, CaseIterable, Identifiable {
    case month
    case quarter
    case year
    case all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .month: "Місяць"
        case .quarter: "3 місяці"
        case .year: "Рік"
        case .all: "Увесь час"
        }
    }

    func contains(_ date: Date, referenceDate: Date = .now) -> Bool {
        let calendar = Calendar.current
        switch self {
        case .month:
            return calendar.isDate(date, equalTo: referenceDate, toGranularity: .month)
        case .quarter:
            guard let start = calendar.date(byAdding: .month, value: -3, to: referenceDate) else { return true }
            return date >= start
        case .year:
            return calendar.isDate(date, equalTo: referenceDate, toGranularity: .year)
        case .all:
            return true
        }
    }
}

/// A transaction reduced to just what the analytics charts need, sourced
/// from either local SwiftData or the backend.
struct AnalyticsTransaction {
    let type: TransactionType
    let amount: Decimal
    let currency: Currency
    let date: Date
    let categoryID: String
    let categoryName: String
    let categoryIconName: String
    let categoryColorHex: String

    static func local(_ transaction: Transaction) -> AnalyticsTransaction {
        AnalyticsTransaction(
            type: transaction.type,
            amount: transaction.amount,
            currency: transaction.currency,
            date: transaction.date,
            categoryID: transaction.category?.id.uuidString ?? "uncategorized",
            categoryName: transaction.category?.name ?? "Без категорії",
            categoryIconName: transaction.category?.iconName ?? "questionmark.circle.fill",
            categoryColorHex: transaction.category?.colorHex ?? "8E8E93"
        )
    }

    static func remote(_ transaction: TransactionModel.Transaction, categories: [CategoryModel.Category]) -> AnalyticsTransaction? {
        guard
            let type = TransactionType(protoType: transaction.type),
            let currency = Currency(protoCurrency: transaction.currency),
            let amount = Decimal(string: transaction.amount),
            let date = ISO8601DateFormatter().date(from: transaction.date)
        else { return nil }

        let category = categories.first { $0.id == transaction.categoryID }
        return AnalyticsTransaction(
            type: type,
            amount: amount,
            currency: currency,
            date: date,
            categoryID: transaction.categoryID.isEmpty ? "uncategorized" : transaction.categoryID,
            categoryName: category?.name ?? "Без категорії",
            categoryIconName: category?.iconName ?? "questionmark.circle.fill",
            categoryColorHex: category?.colorHex ?? "8E8E93"
        )
    }
}

struct CategoryTotal: Identifiable {
    let id: String
    let name: String
    let iconName: String
    let color: Color
    let total: Decimal
}

struct MonthlyTotal: Identifiable {
    let id: Date
    let month: Date
    let income: Decimal
    let expense: Decimal
}

enum AnalyticsCalculator {
    static func categoryTotals(
        transactions: [AnalyticsTransaction],
        type: TransactionType,
        rateStore: ExchangeRateStore
    ) -> [CategoryTotal] {
        let grouped = Dictionary(grouping: transactions.filter { $0.type == type }) { $0.categoryID }

        return grouped.compactMap { _, items -> CategoryTotal? in
            guard let first = items.first else { return nil }
            let total = items.reduce(Decimal(0)) { $0 + rateStore.convert($1.amount, from: $1.currency) }
            return CategoryTotal(
                id: first.categoryID,
                name: first.categoryName,
                iconName: first.categoryIconName,
                color: Color(hex: first.categoryColorHex),
                total: total
            )
        }
        .sorted { $0.total > $1.total }
    }

    static func monthlyTotals(
        transactions: [AnalyticsTransaction],
        monthsBack: Int,
        rateStore: ExchangeRateStore,
        referenceDate: Date = .now
    ) -> [MonthlyTotal] {
        let calendar = Calendar.current
        let months: [Date] = (0..<monthsBack).reversed().compactMap {
            calendar.date(byAdding: .month, value: -$0, to: calendar.startOfMonth(for: referenceDate))
        }

        return months.map { month in
            let items = transactions.filter { calendar.isDate($0.date, equalTo: month, toGranularity: .month) }
            let income = items.filter { $0.type == .income }
                .reduce(Decimal(0)) { $0 + rateStore.convert($1.amount, from: $1.currency) }
            let expense = items.filter { $0.type == .expense }
                .reduce(Decimal(0)) { $0 + rateStore.convert($1.amount, from: $1.currency) }
            return MonthlyTotal(id: month, month: month, income: income, expense: expense)
        }
    }
}

private extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        self.date(from: dateComponents([.year, .month], from: date)) ?? date
    }
}
