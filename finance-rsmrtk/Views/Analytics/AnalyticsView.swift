import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    @Environment(ExchangeRateStore.self) private var rateStore
    @Environment(AuthSession.self) private var authSession
    @Environment(RemoteStore.self) private var remoteStore
    @Query private var localTransactions: [Transaction]

    @State private var period: AnalyticsPeriod = .month
    @State private var chartType: TransactionType = .expense

    private var analyticsTransactions: [AnalyticsTransaction] {
        if authSession.isSignedIn {
            return remoteStore.transactions.compactMap {
                AnalyticsTransaction.remote($0, categories: remoteStore.categories)
            }
        } else {
            return localTransactions.map { AnalyticsTransaction.local($0) }
        }
    }

    private var filteredTransactions: [AnalyticsTransaction] {
        analyticsTransactions.filter { period.contains($0.date) }
    }

    private var categoryTotals: [CategoryTotal] {
        AnalyticsCalculator.categoryTotals(transactions: filteredTransactions, type: chartType, rateStore: rateStore)
    }

    private var monthlyTotals: [MonthlyTotal] {
        AnalyticsCalculator.monthlyTotals(transactions: analyticsTransactions, monthsBack: 6, rateStore: rateStore)
    }

    private var totalForChart: Decimal {
        categoryTotals.reduce(0) { $0 + $1.total }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Picker("Період", selection: $period) {
                        ForEach(AnalyticsPeriod.allCases) { period in
                            Text(period.title).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    byCategorySection
                    trendSection
                }
                .padding(.vertical)
            }
            .navigationTitle("Аналітика")
            .task {
                if authSession.isSignedIn && remoteStore.transactions.isEmpty {
                    await remoteStore.refreshAll()
                }
            }
        }
    }

    @ViewBuilder
    private var byCategorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("За категоріями")
                    .font(.headline)
                Spacer()
                Picker("Тип", selection: $chartType) {
                    Text("Витрати").tag(TransactionType.expense)
                    Text("Дохід").tag(TransactionType.income)
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }
            .padding(.horizontal)

            if categoryTotals.isEmpty {
                EmptyStateView(icon: "chart.pie", title: "Немає даних", message: "Додайте транзакції за цей період")
                    .frame(height: 200)
            } else {
                Chart(categoryTotals) { item in
                    SectorMark(
                        angle: .value("Сума", item.total),
                        innerRadius: .ratio(0.6),
                        angularInset: 1.5
                    )
                    .foregroundStyle(item.color)
                    .cornerRadius(4)
                }
                .frame(height: 220)
                .padding(.horizontal)
                .overlay {
                    VStack(spacing: 2) {
                        Text("Разом")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(rateStore.baseCurrency.formatted(totalForChart))
                            .font(.title3.weight(.semibold))
                    }
                }

                VStack(spacing: 0) {
                    ForEach(categoryTotals) { item in
                        HStack {
                            Circle().fill(item.color).frame(width: 10, height: 10)
                            Image(systemName: item.iconName)
                                .foregroundStyle(item.color)
                                .frame(width: 20)
                            Text(item.name)
                            Spacer()
                            Text(rateStore.baseCurrency.formatted(item.total))
                                .foregroundStyle(.secondary)
                            Text(percentage(item.total))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 44, alignment: .trailing)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal)
                        Divider().padding(.leading, 44)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var trendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Дохід / Витрати за 6 місяців")
                .font(.headline)
                .padding(.horizontal)

            Chart {
                ForEach(monthlyTotals) { item in
                    BarMark(
                        x: .value("Місяць", item.month, unit: .month),
                        y: .value("Сума", item.income)
                    )
                    .foregroundStyle(by: .value("Тип", TransactionType.income.title))
                    .position(by: .value("Тип", TransactionType.income.title))

                    BarMark(
                        x: .value("Місяць", item.month, unit: .month),
                        y: .value("Сума", item.expense)
                    )
                    .foregroundStyle(by: .value("Тип", TransactionType.expense.title))
                    .position(by: .value("Тип", TransactionType.expense.title))
                }
            }
            .chartForegroundStyleScale([
                TransactionType.income.title: Color.green,
                TransactionType.expense.title: Color.red
            ])
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { _ in
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                }
            }
            .frame(height: 220)
            .padding(.horizontal)
        }
    }

    private func percentage(_ value: Decimal) -> String {
        guard totalForChart > 0 else { return "0%" }
        let fraction = (value as NSDecimalNumber).doubleValue / (totalForChart as NSDecimalNumber).doubleValue
        return fraction.formatted(.percent.precision(.fractionLength(0)))
    }
}

#Preview {
    let authSession = AuthSession()
    let rateStore = ExchangeRateStore()
    AnalyticsView()
        .modelContainer(AppModelContainer.shared)
        .environment(rateStore)
        .environment(authSession)
        .environment(RemoteStore(authSession: authSession, rateStore: rateStore))
}
