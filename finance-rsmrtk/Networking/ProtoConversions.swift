import Foundation

extension Currency {
    init?(protoCurrency: CurrencyModel.Currency) {
        switch protoCurrency {
        case .uah: self = .uah
        case .usd: self = .usd
        case .eur: self = .eur
        case .gbp: self = .gbp
        case .pln: self = .pln
        case .unspecified, .UNRECOGNIZED: return nil
        }
    }

    var protoCurrency: CurrencyModel.Currency {
        switch self {
        case .uah: .uah
        case .usd: .usd
        case .eur: .eur
        case .gbp: .gbp
        case .pln: .pln
        }
    }
}

extension TransactionType {
    init?(protoType: TransactionTypeModel.TransactionType) {
        switch protoType {
        case .expense: self = .expense
        case .income: self = .income
        case .unspecified, .UNRECOGNIZED: return nil
        }
    }

    var protoType: TransactionTypeModel.TransactionType {
        switch self {
        case .expense: .expense
        case .income: .income
        }
    }
}
