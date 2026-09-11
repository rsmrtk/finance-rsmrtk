import Foundation

enum Currency: String, Codable, CaseIterable, Identifiable, Hashable {
    case uah
    case usd
    case eur
    case gbp
    case pln

    var id: String { rawValue }

    var code: String { rawValue.uppercased() }

    var symbol: String {
        switch self {
        case .uah: "₴"
        case .usd: "$"
        case .eur: "€"
        case .gbp: "£"
        case .pln: "zł"
        }
    }

    var name: String {
        switch self {
        case .uah: "Гривня"
        case .usd: "Долар США"
        case .eur: "Євро"
        case .gbp: "Фунт стерлінгів"
        case .pln: "Злотий"
        }
    }

    static let `default`: Currency = .uah

    func formatted(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = symbol
        formatter.currencyCode = code
        formatter.locale = Locale(identifier: "uk_UA")
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(symbol)\(amount)"
    }
}
