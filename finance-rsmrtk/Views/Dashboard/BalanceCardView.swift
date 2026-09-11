import SwiftUI

struct BalanceCardView: View {
    let balance: Decimal
    let income: Decimal
    let expense: Decimal
    let currency: Currency

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Баланс за місяць")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                Text(currency.formatted(balance))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            HStack(spacing: 24) {
                statColumn(title: "Дохід", amount: income, icon: "arrow.down.circle.fill")
                statColumn(title: "Витрати", amount: expense, icon: "arrow.up.circle.fill")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func statColumn(title: String, amount: Decimal, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.white.opacity(0.85))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.75))
                Text(currency.formatted(amount))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
            }
        }
    }
}

#Preview {
    BalanceCardView(balance: 12500, income: 25000, expense: 12500, currency: .uah)
        .padding()
}
