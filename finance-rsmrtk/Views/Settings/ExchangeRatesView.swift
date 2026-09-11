import SwiftUI

struct ExchangeRatesView: View {
    @Environment(ExchangeRateStore.self) private var rateStore

    var body: some View {
        Form {
            Section {
                Text("Скільки \(rateStore.baseCurrency.code) коштує 1 одиниця валюти. Використовується для підсумків на Огляді та в Аналітиці.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Курси відносно \(rateStore.baseCurrency.code)") {
                ForEach(Currency.allCases.filter { $0 != rateStore.baseCurrency }) { currency in
                    rateRow(for: currency)
                }
            }
        }
        .navigationTitle("Курси валют")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func rateRow(for currency: Currency) -> some View {
        let binding = Binding<Double>(
            get: { rateStore.rates[currency] ?? 1 },
            set: { rateStore.rates[currency] = $0 }
        )

        return HStack {
            Text(currency.code)
            Spacer()
            TextField("0", value: binding, format: .number.precision(.fractionLength(0...4)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 100)
        }
    }
}

#Preview {
    NavigationStack {
        ExchangeRatesView()
            .environment(ExchangeRateStore())
    }
}
