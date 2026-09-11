import Foundation

/// A category available for selection in the "add transaction" picker,
/// sourced from either local SwiftData or the backend.
enum PickableCategory: Identifiable, Hashable {
    case local(Category)
    case remote(CategoryModel.Category)

    var id: String {
        switch self {
        case .local(let category): category.id.uuidString
        case .remote(let category): category.id
        }
    }

    var name: String {
        switch self {
        case .local(let category): category.name
        case .remote(let category): category.name
        }
    }

    var iconName: String {
        switch self {
        case .local(let category): category.iconName
        case .remote(let category): category.iconName
        }
    }

    var colorHex: String {
        switch self {
        case .local(let category): category.colorHex
        case .remote(let category): category.colorHex
        }
    }

    var type: TransactionType {
        switch self {
        case .local(let category): category.type
        case .remote(let category): TransactionType(protoType: category.type) ?? .expense
        }
    }

    static func == (lhs: PickableCategory, rhs: PickableCategory) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
