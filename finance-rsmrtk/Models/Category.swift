import SwiftData
import SwiftUI

@Model
final class Category {
    var id: UUID
    var name: String
    var iconName: String
    var colorHex: String
    var type: TransactionType
    var isDefault: Bool

    @Relationship(deleteRule: .nullify, inverse: \Transaction.category)
    var transactions: [Transaction]? = []

    init(
        name: String,
        iconName: String,
        colorHex: String,
        type: TransactionType,
        isDefault: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.type = type
        self.isDefault = isDefault
    }

    var color: Color { Color(hex: colorHex) }
}

extension Category {
    static let defaultExpenseCategories: [Category] = [
        Category(name: "Продукти", iconName: "cart.fill", colorHex: "FF9500", type: .expense, isDefault: true),
        Category(name: "Транспорт", iconName: "car.fill", colorHex: "007AFF", type: .expense, isDefault: true),
        Category(name: "Житло", iconName: "house.fill", colorHex: "5856D6", type: .expense, isDefault: true),
        Category(name: "Розваги", iconName: "gamecontroller.fill", colorHex: "FF2D55", type: .expense, isDefault: true),
        Category(name: "Здоров'я", iconName: "cross.case.fill", colorHex: "34C759", type: .expense, isDefault: true),
        Category(name: "Одяг", iconName: "tshirt.fill", colorHex: "AF52DE", type: .expense, isDefault: true),
        Category(name: "Освіта", iconName: "book.fill", colorHex: "5AC8FA", type: .expense, isDefault: true),
        Category(name: "Інше", iconName: "ellipsis.circle.fill", colorHex: "8E8E93", type: .expense, isDefault: true)
    ]

    static let defaultIncomeCategories: [Category] = [
        Category(name: "Зарплата", iconName: "banknote.fill", colorHex: "34C759", type: .income, isDefault: true),
        Category(name: "Фріланс", iconName: "laptopcomputer", colorHex: "007AFF", type: .income, isDefault: true),
        Category(name: "Подарунки", iconName: "gift.fill", colorHex: "FF2D55", type: .income, isDefault: true),
        Category(name: "Інвестиції", iconName: "chart.line.uptrend.xyaxis", colorHex: "FF9500", type: .income, isDefault: true),
        Category(name: "Інше", iconName: "ellipsis.circle.fill", colorHex: "8E8E93", type: .income, isDefault: true)
    ]

    static var defaultCategories: [Category] {
        defaultExpenseCategories + defaultIncomeCategories
    }
}
