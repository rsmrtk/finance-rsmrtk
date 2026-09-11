import SwiftData

enum AppModelContainer {
    static let shared: ModelContainer = {
        let schema = Schema([Transaction.self, Category.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            seedDefaultCategoriesIfNeeded(in: container)
            return container
        } catch {
            fatalError("Не вдалося створити ModelContainer: \(error)")
        }
    }()

    @MainActor
    private static func seedDefaultCategoriesIfNeeded(in container: ModelContainer) {
        let context = container.mainContext
        let descriptor = FetchDescriptor<Category>()
        guard let count = try? context.fetchCount(descriptor), count == 0 else { return }

        for category in Category.defaultCategories {
            context.insert(category)
        }
        try? context.save()
    }
}
