import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ExchangeRateStore.self) private var rateStore
    @Environment(AuthSession.self) private var authSession
    @Environment(RemoteStore.self) private var remoteStore
    @Query(sort: \Transaction.date, order: .reverse) private var localTransactions: [Transaction]

    @State private var isPresentingAddTransaction = false

    private struct MonthlyAmount {
        let amount: Decimal
        let currency: Currency
        let type: TransactionType
    }

    private var currentMonthAmounts: [MonthlyAmount] {
        if authSession.isSignedIn {
            return remoteStore.transactions.compactMap { transaction in
                guard
                    let date = ISO8601DateFormatter().date(from: transaction.date),
                    Calendar.current.isDate(date, equalTo: .now, toGranularity: .month),
                    let currency = Currency(protoCurrency: transaction.currency),
                    let type = TransactionType(protoType: transaction.type),
                    let amount = Decimal(string: transaction.amount)
                else { return nil }
                return MonthlyAmount(amount: amount, currency: currency, type: type)
            }
        } else {
            return localTransactions
                .filter { Calendar.current.isDate($0.date, equalTo: .now, toGranularity: .month) }
                .map { MonthlyAmount(amount: $0.amount, currency: $0.currency, type: $0.type) }
        }
    }

    private var income: Decimal {
        currentMonthAmounts
            .filter { $0.type == .income }
            .reduce(0) { $0 + rateStore.convert($1.amount, from: $1.currency) }
    }

    private var expense: Decimal {
        currentMonthAmounts
            .filter { $0.type == .expense }
            .reduce(0) { $0 + rateStore.convert($1.amount, from: $1.currency) }
    }

    private var recentTransactions: [DisplayTransaction] {
        if authSession.isSignedIn {
            return remoteStore.transactions.prefix(5).map {
                DisplayTransaction.remote($0, categories: remoteStore.categories, store: remoteStore, onError: { _ in })
            }
        } else {
            return localTransactions.prefix(5).map { DisplayTransaction.local($0, modelContext: modelContext) }
        }
    }

    private var isEmpty: Bool {
        authSession.isSignedIn ? remoteStore.transactions.isEmpty : localTransactions.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    BalanceCardView(
                        balance: income - expense,
                        income: income,
                        expense: expense,
                        currency: rateStore.baseCurrency
                    )
                    .padding(.horizontal)

                    recentSection
                }
                .padding(.vertical)
            }
            .background(MeshGradientBackdrop())
            .navigationTitle("Огляд")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isPresentingAddTransaction = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $isPresentingAddTransaction) {
                AddTransactionView()
            }
            .task {
                if authSession.isSignedIn && remoteStore.transactions.isEmpty {
                    await remoteStore.refreshAll()
                }
            }
        }
    }

    @ViewBuilder
    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Останні транзакції")
                .font(.headline)
                .padding(.horizontal)

            if isEmpty {
                EmptyStateView(
                    icon: "creditcard",
                    title: "Ще немає транзакцій",
                    message: "Натисніть \"+\", щоб додати першу витрату або дохід"
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(recentTransactions.enumerated()), id: \.element.id) { index, transaction in
                        TransactionRowView(transaction: transaction)
                        if index != recentTransactions.count - 1 {
                            Divider().padding(.leading, 68)
                        }
                    }
                }
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
            }
        }
    }
}

#Preview {
    let authSession = AuthSession()
    let rateStore = ExchangeRateStore()
    DashboardView()
        .modelContainer(AppModelContainer.shared)
        .environment(rateStore)
        .environment(authSession)
        .environment(RemoteStore(authSession: authSession, rateStore: rateStore))
}
