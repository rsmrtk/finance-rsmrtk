import SwiftUI
import SwiftData

struct AddTransactionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(ExchangeRateStore.self) private var rateStore
    @Environment(AuthSession.self) private var authSession
    @Environment(RemoteStore.self) private var remoteStore
    @Query private var localCategories: [Category]

    @State private var type: TransactionType = .expense
    @State private var amountText = ""
    @State private var currency: Currency = .default
    @State private var selectedCategory: PickableCategory?
    @State private var date: Date = .now
    @State private var note = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var availableCategories: [PickableCategory] {
        if authSession.isSignedIn {
            return remoteStore.categories
                .filter { $0.type == type.protoType }
                .map { .remote($0) }
        } else {
            return localCategories
                .filter { $0.type == type }
                .map { .local($0) }
        }
    }

    private var amount: Decimal? {
        let normalized = amountText.replacingOccurrences(of: ",", with: ".")
        return Decimal(string: normalized)
    }

    private var canSave: Bool {
        guard let amount, amount > 0, !isSaving else { return false }
        return selectedCategory != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Тип", selection: $type) {
                        ForEach(TransactionType.allCases) { type in
                            Text(type.title).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: type) { selectedCategory = nil }
                }

                Section("Сума") {
                    HStack {
                        TextField("0", text: $amountText)
                            .keyboardType(.decimalPad)
                            .font(.title2.weight(.semibold))
                        Picker("Валюта", selection: $currency) {
                            ForEach(Currency.allCases) { currency in
                                Text(currency.code).tag(currency)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                Section("Категорія") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(availableCategories) { category in
                                categoryChip(category)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section {
                    DatePicker("Дата", selection: $date, displayedComponents: .date)
                    TextField("Нотатка (необов'язково)", text: $note)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(type == .expense ? "Нова витрата" : "Новий дохід")
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
                            .disabled(!canSave)
                    }
                }
            }
            .onAppear {
                currency = rateStore.baseCurrency
                if selectedCategory == nil {
                    selectedCategory = availableCategories.first
                }
            }
        }
    }

    private func categoryChip(_ category: PickableCategory) -> some View {
        let isSelected = selectedCategory?.id == category.id
        return VStack(spacing: 6) {
            CategoryIconView(iconName: category.iconName, colorHex: category.colorHex, size: 48)
                .overlay {
                    if isSelected {
                        Circle().stroke(Color(hex: category.colorHex), lineWidth: 2).padding(-3)
                    }
                }
            Text(category.name)
                .font(.caption2)
                .lineLimit(1)
        }
        .frame(width: 64)
        .contentShape(Rectangle())
        .onTapGesture { selectedCategory = category }
    }

    private func save() {
        guard let amount, let selectedCategory else { return }

        if authSession.isSignedIn {
            isSaving = true
            Task {
                defer { isSaving = false }
                do {
                    let dateString = ISO8601DateFormatter().string(from: date)
                    try await remoteStore.createTransaction(
                        amount: amountText.replacingOccurrences(of: ",", with: "."),
                        currency: currency.protoCurrency,
                        type: type.protoType,
                        date: dateString,
                        note: note,
                        categoryID: selectedCategory.id
                    )
                    dismiss()
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        } else {
            guard case .local(let localCategory) = selectedCategory else { return }
            let transaction = Transaction(
                amount: amount,
                currency: currency,
                type: type,
                date: date,
                note: note,
                category: localCategory
            )
            modelContext.insert(transaction)
            dismiss()
        }
    }
}

#Preview {
    let authSession = AuthSession()
    let rateStore = ExchangeRateStore()
    AddTransactionView()
        .modelContainer(AppModelContainer.shared)
        .environment(rateStore)
        .environment(authSession)
        .environment(RemoteStore(authSession: authSession, rateStore: rateStore))
}
