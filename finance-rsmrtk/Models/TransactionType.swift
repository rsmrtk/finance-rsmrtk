import SwiftUI

enum TransactionType: String, Codable, CaseIterable, Identifiable {
    case expense
    case income

    var id: String { rawValue }

    var title: String {
        switch self {
        case .expense: "Витрата"
        case .income: "Дохід"
        }
    }

    var sign: String {
        switch self {
        case .expense: "-"
        case .income: "+"
        }
    }

    var tint: Color {
        switch self {
        case .expense: .red
        case .income: .green
        }
    }
}
