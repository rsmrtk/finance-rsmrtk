import SwiftUI
import SwiftData

struct CategoriesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthSession.self) private var authSession
    @Environment(RemoteStore.self) private var remoteStore
    @Query(sort: \Category.name) private var localCategories: [Category]

    @State private var isPresentingAddCategory = false
    @State private var newCategoryType: TransactionType = .expense
    @State private var errorMessage: String?

    var body: some View {
        List {
            if authSession.isSignedIn {
                remoteSection(title: "Витрати", type: .expense)
                remoteSection(title: "Дохід", type: .income)
            } else {
                localSection(title: "Витрати", type: .expense, items: localCategories.filter { $0.type == .expense })
                localSection(title: "Дохід", type: .income, items: localCategories.filter { $0.type == .income })
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .navigationTitle("Категорії")
        .sheet(isPresented: $isPresentingAddCategory) {
            AddCategoryView(type: newCategoryType)
        }
        .task {
            if authSession.isSignedIn && remoteStore.categories.isEmpty {
                await remoteStore.refreshAll()
            }
        }
    }

    private func localSection(title: String, type: TransactionType, items: [Category]) -> some View {
        Section {
            ForEach(items) { category in
                HStack {
                    CategoryIconView(category: category, size: 32)
                    Text(category.name)
                    Spacer()
                    if category.isDefault {
                        Text("базова")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onDelete { offsets in
                for index in offsets {
                    modelContext.delete(items[index])
                }
            }
        } header: {
            Text(title)
        } footer: {
            addButton(type: type)
        }
    }

    private func remoteSection(title: String, type: TransactionType) -> some View {
        let items = remoteStore.categories.filter { $0.type == type.protoType }
        return Section {
            ForEach(items, id: \.id) { category in
                HStack {
                    CategoryIconView(iconName: category.iconName, colorHex: category.colorHex, size: 32)
                    Text(category.name)
                    Spacer()
                    if category.isDefault {
                        Text("базова")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onDelete { offsets in
                for index in offsets {
                    let category = items[index]
                    Task {
                        do {
                            try await remoteStore.deleteCategory(id: category.id)
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                }
            }
        } header: {
            Text(title)
        } footer: {
            addButton(type: type)
        }
    }

    private func addButton(type: TransactionType) -> some View {
        Button {
            newCategoryType = type
            isPresentingAddCategory = true
        } label: {
            Label("Додати категорію", systemImage: "plus.circle")
        }
    }
}

#Preview {
    let authSession = AuthSession()
    let rateStore = ExchangeRateStore()
    NavigationStack {
        CategoriesView()
            .modelContainer(AppModelContainer.shared)
            .environment(authSession)
            .environment(RemoteStore(authSession: authSession, rateStore: rateStore))
    }
}
