import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(ExchangeRateStore.self) private var rateStore
    @Environment(AuthSession.self) private var authSession

    var body: some View {
        NavigationStack {
            List {
                AccountSectionView()

                if authSession.isSignedIn {
                    MonobankSectionView()
                }

                Section {
                    NavigationLink {
                        CategoriesView()
                    } label: {
                        Label("Категорії", systemImage: "square.grid.2x2.fill")
                    }
                }

                Section("Валюта") {
                    Picker("Базова валюта", selection: Bindable(rateStore).baseCurrency) {
                        ForEach(Currency.allCases) { currency in
                            Text("\(currency.name) (\(currency.code))").tag(currency)
                        }
                    }

                    NavigationLink {
                        ExchangeRatesView()
                    } label: {
                        Label("Курси валют", systemImage: "arrow.left.arrow.right")
                    }
                }

                Section {
                    Text("Без входу дані зберігаються лише локально на пристрої (SwiftData). Після входу через Apple ID вони синхронізуються з сервером.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Налаштування")
        }
    }
}

#Preview {
    let authSession = AuthSession()
    let rateStore = ExchangeRateStore()
    SettingsView()
        .modelContainer(AppModelContainer.shared)
        .environment(rateStore)
        .environment(authSession)
        .environment(RemoteStore(authSession: authSession, rateStore: rateStore))
}
