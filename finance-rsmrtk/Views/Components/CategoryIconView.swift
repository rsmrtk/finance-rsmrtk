import SwiftUI

/// Renders a category's icon regardless of whether it came from local
/// SwiftData or the backend — both just supply an icon name and hex color.
struct CategoryIconView: View {
    let iconName: String?
    let colorHex: String?
    var size: CGFloat = 40

    var body: some View {
        Circle()
            .fill(color.opacity(0.18))
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: iconName ?? "questionmark.circle.fill")
                    .font(.system(size: size * 0.45, weight: .semibold))
                    .foregroundStyle(color)
            }
    }

    private var color: Color {
        colorHex.map { Color(hex: $0) } ?? .gray
    }
}

extension CategoryIconView {
    init(category: Category?, size: CGFloat = 40) {
        self.init(iconName: category?.iconName, colorHex: category?.colorHex, size: size)
    }
}

#Preview {
    CategoryIconView(category: Category.defaultExpenseCategories.first)
}
