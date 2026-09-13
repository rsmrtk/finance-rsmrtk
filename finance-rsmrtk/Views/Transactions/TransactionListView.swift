import SwiftUI
import SwiftData

struct TransactionListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthSession.self) private var authSession
    @Environment(RemoteStore.self) private var remoteStore
    @Query(sort: \Transaction.date, order: .reverse) private var localTransactions: [Transaction]

    @State private var searchText = ""
    @State private var typeFilter: TransactionType?
    @State private var isPresentingAddTransaction = false
    @State private var errorMessage: String?

    private var displayTransactions: [DisplayTransaction] {
        if authSession.isSignedIn {
            return remoteStore.transactions.map {
                DisplayTransaction.remote(
                    $0,
                    categories: remoteStore.categories,
                    store: remoteStore,
                    onError: { errorMessage = $0 }
                )
            }
        } else {
            return localTransactions.map { DisplayTransaction.local($0, modelContext: modelContext) }
        }
    }

    private var filteredTransactions: [DisplayTransaction] {
        displayTransactions.filter { transaction in
            let matchesType = typeFilter == nil || transaction.type == typeFilter
            let matchesSearch = searchText.isEmpty || transaction.searchText.localizedCaseInsensitiveContains(searchText)
            return matchesType && matchesSearch
        }
    }

    private var groupedByDay: [(day: Date, items: [DisplayTransaction])] {
        let groups = Dictionary(grouping: filteredTransactions) {
            Calendar.current.startOfDay(for: $0.date)
        }
        return groups
            .sorted { $0.key > $1.key }
            .map { (day: $0.key, items: $0.value) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredTransactions.isEmpty {
                    EmptyStateView(
                        icon: "list.bullet",
                        title: "Немає транзакцій",
                        message: "Змініть фільтр або додайте нову транзакцію"
                    )
                } else {
                    List {
                        if let errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }

                        ForEach(groupedByDay, id: \.day) { group in
                            Section(header: Text(group.day, style: .date)) {
                                ForEach(group.items) { transaction in
                                    TransactionRowView(transaction: transaction)
                                        .listRowInsets(EdgeInsets())
                                }
                                .onDelete { offsets in
                                    for index in offsets {
                                        group.items[index].delete()
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(MeshGradientBackdrop())
            .searchable(text: $searchText, prompt: "Пошук за нотаткою чи категорією")
            .navigationTitle("Транзакції")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button("Усі") { typeFilter = nil }
                        Button(TransactionType.income.title) { typeFilter = .income }
                        Button(TransactionType.expense.title) { typeFilter = .expense }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isPresentingAddTransaction = true
                    } label: {
                        Image(systemName: "plus")
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
}

#Preview {
    let authSession = AuthSession()
    let rateStore = ExchangeRateStore()
    TransactionListView()
        .modelContainer(AppModelContainer.shared)
        .environment(authSession)
        .environment(RemoteStore(authSession: authSession, rateStore: rateStore))
}
