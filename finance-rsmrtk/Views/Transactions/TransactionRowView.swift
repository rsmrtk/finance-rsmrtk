import SwiftUI

struct TransactionRowView: View {
    let transaction: DisplayTransaction

    var body: some View {
        HStack(spacing: 12) {
            CategoryIconView(iconName: transaction.categoryIconName, colorHex: transaction.categoryColorHex)

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.categoryName)
                    .font(.subheadline.weight(.medium))
                if !transaction.note.isEmpty {
                    Text(transaction.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(transaction.amountText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(transaction.tint)
                Text(transaction.date, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}

#Preview {
    TransactionRowView(
        transaction: DisplayTransaction(
            id: UUID().uuidString,
            categoryName: "Продукти",
            categoryIconName: "cart.fill",
            categoryColorHex: "FF9500",
            note: "Кава та обід",
            amountText: "-350,00 ₴",
            tint: .red,
            date: .now,
            type: .expense,
            searchText: "Продукти Кава та обід",
            delete: {}
        )
    )
}
