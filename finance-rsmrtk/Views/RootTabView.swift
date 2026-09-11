import SwiftUI
import SwiftData

struct RootTabView: View {
    @State private var exchangeRateStore: ExchangeRateStore
    @State private var authSession: AuthSession
    @State private var remoteStore: RemoteStore

    init() {
        let rateStore = ExchangeRateStore()
        let session = AuthSession()
        _exchangeRateStore = State(initialValue: rateStore)
        _authSession = State(initialValue: session)
        _remoteStore = State(initialValue: RemoteStore(authSession: session, rateStore: rateStore))
    }

    var body: some View {
        TabView {
            Tab("Огляд", systemImage: "house.fill") {
                DashboardView()
            }
            Tab("Транзакції", systemImage: "list.bullet") {
                TransactionListView()
            }
            Tab("Аналітика", systemImage: "chart.pie.fill") {
                AnalyticsView()
            }
            Tab("Налаштування", systemImage: "gearshape.fill") {
                SettingsView()
            }
        }
        .environment(exchangeRateStore)
        .environment(authSession)
        .environment(remoteStore)
        .task {
            if authSession.isSignedIn {
                await remoteStore.refreshAll()
            }
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(AppModelContainer.shared)
}
