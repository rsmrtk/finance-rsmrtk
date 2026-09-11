import Foundation
import Observation

@Observable
final class ExchangeRateStore {
    private enum Keys {
        static let baseCurrency = "exchangeRateStore.baseCurrency"
        static let rates = "exchangeRateStore.rates"
    }

    /// Валюта, у якій показуються підсумки на Огляді та в Аналітиці.
    var baseCurrency: Currency {
        didSet { UserDefaults.standard.set(baseCurrency.rawValue, forKey: Keys.baseCurrency) }
    }

    /// Курс кожної валюти відносно `baseCurrency` (скільки одиниць base за 1 одиницю валюти).
    var rates: [Currency: Double] {
        didSet { persistRates() }
    }

    init() {
        if let raw = UserDefaults.standard.string(forKey: Keys.baseCurrency),
           let saved = Currency(rawValue: raw) {
            baseCurrency = saved
        } else {
            baseCurrency = .default
        }

        if let data = UserDefaults.standard.data(forKey: Keys.rates),
           let decoded = try? JSONDecoder().decode([String: Double].self, from: data) {
            rates = Dictionary(uniqueKeysWithValues: decoded.compactMap { key, value in
                Currency(rawValue: key).map { ($0, value) }
            })
        } else {
            rates = Self.defaultRates
        }
    }

    /// Replaces `rates` using fresh values from the backend, which are
    /// always expressed as "1 unit of `currency` = X UAH". Re-expressed here
    /// relative to whatever `baseCurrency` is currently selected.
    func applyRemoteRates(_ rateToUAH: [Currency: Double]) {
        guard let baseRateToUAH = rateToUAH[baseCurrency], baseRateToUAH > 0 else { return }
        rates = rateToUAH.mapValues { $0 / baseRateToUAH }
    }

    func rate(for currency: Currency) -> Double {
        currency == baseCurrency ? 1 : (rates[currency] ?? 1)
    }

    func convert(_ amount: Decimal, from currency: Currency) -> Decimal {
        guard currency != baseCurrency else { return amount }
        return amount * Decimal(rate(for: currency))
    }

    private func persistRates() {
        let encodable = Dictionary(uniqueKeysWithValues: rates.map { ($0.key.rawValue, $0.value) })
        if let data = try? JSONEncoder().encode(encodable) {
            UserDefaults.standard.set(data, forKey: Keys.rates)
        }
    }

    /// Орієнтовні стартові курси відносно гривні. Користувач може відредагувати їх у Налаштуваннях.
    private static let defaultRates: [Currency: Double] = [
        .uah: 1,
        .usd: 41,
        .eur: 45,
        .gbp: 52,
        .pln: 10.5
    ]
}
