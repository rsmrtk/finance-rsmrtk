import SwiftUI
import SwiftData

struct AddCategoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthSession.self) private var authSession
    @Environment(RemoteStore.self) private var remoteStore

    let type: TransactionType

    @State private var name = ""
    @State private var selectedIcon = availableIcons.first ?? "tag.fill"
    @State private var selectedColorHex = availableColors.first ?? "007AFF"
    @State private var isSaving = false
    @State private var errorMessage: String?

    private static let availableIcons = [
        "cart.fill", "car.fill", "house.fill", "gamecontroller.fill", "cross.case.fill",
        "tshirt.fill", "book.fill", "banknote.fill", "laptopcomputer", "gift.fill",
        "chart.line.uptrend.xyaxis", "airplane", "fork.knife", "pawprint.fill", "ellipsis.circle.fill"
    ]

    private static let availableColors = [
        "FF9500", "007AFF", "5856D6", "FF2D55", "34C759", "AF52DE", "5AC8FA", "8E8E93"
    ]

    private let columns = Array(repeating: GridItem(.flexible()), count: 5)

    var body: some View {
        NavigationStack {
            Form {
                Section("Назва") {
                    TextField("Наприклад, Кафе", text: $name)
                }

                Section("Іконка") {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(Self.availableIcons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title3)
                                .frame(width: 44, height: 44)
                                .background(selectedIcon == icon ? Color(hex: selectedColorHex).opacity(0.2) : Color(.secondarySystemBackground))
                                .foregroundStyle(selectedIcon == icon ? Color(hex: selectedColorHex) : .primary)
                                .clipShape(Circle())
                                .onTapGesture { selectedIcon = icon }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Колір") {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(Self.availableColors, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 32, height: 32)
                                .overlay {
                                    if selectedColorHex == hex {
                                        Circle().stroke(.primary, lineWidth: 2).padding(-3)
                                    }
                                }
                                .onTapGesture { selectedColorHex = hex }
                        }
                    }
                    .padding(.vertical, 4)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Нова категорія")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Скасувати") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Зберегти") { save() }
                            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
        }
    }

    private func save() {
        if authSession.isSignedIn {
            isSaving = true
            Task {
                defer { isSaving = false }
                do {
                    try await remoteStore.createCategory(
                        name: name, iconName: selectedIcon, colorHex: selectedColorHex, type: type.protoType
                    )
                    dismiss()
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        } else {
            let category = Category(name: name, iconName: selectedIcon, colorHex: selectedColorHex, type: type)
            modelContext.insert(category)
            dismiss()
        }
    }
}

#Preview {
    let authSession = AuthSession()
    let rateStore = ExchangeRateStore()
    AddCategoryView(type: .expense)
        .modelContainer(AppModelContainer.shared)
        .environment(authSession)
        .environment(RemoteStore(authSession: authSession, rateStore: rateStore))
}
