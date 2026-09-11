import SwiftUI

/// Lets a signed-in user connect their Monobank account so new card
/// transactions import automatically via a backend webhook. Requires the
/// backend to have a public HTTPS URL (PUBLIC_BASE_URL) — not available
/// while only running locally in kind.
struct MonobankSectionView: View {
    @Environment(AuthSession.self) private var authSession

    @State private var status: MonobankConnectionModel.Connection?
    @State private var tokenInput = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        Section("Monobank") {
            if let status, status.isConnected {
                connectedContent(status)
            } else {
                disconnectedContent
            }

            if isLoading {
                ProgressView()
            }
            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .task { await refresh() }
    }

    @ViewBuilder
    private func connectedContent(_ status: MonobankConnectionModel.Connection) -> some View {
        Label(status.maskedPan.isEmpty ? "Підключено" : status.maskedPan, systemImage: "creditcard.fill")
        if !status.lastSyncedAt.isEmpty {
            Text("Остання імпортована транзакція: \(status.lastSyncedAt)")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            Text("Ще не було жодної транзакції з моменту підключення")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        Button("Відключити", role: .destructive) { disconnect() }
    }

    @ViewBuilder
    private var disconnectedContent: some View {
        SecureField("Персональний токен Monobank", text: $tokenInput)
        Button("Підключити") { connect() }
            .disabled(tokenInput.isEmpty || isLoading)

        Text("Токен генерується в застосунку Monobank: Ще → Налаштування → Monobank API. Після підключення нові транзакції з картки прилітатимуть у застосунок автоматично.")
            .font(.caption2)
            .foregroundStyle(.secondary)
    }

    private func refresh() async {
        guard let token = authSession.accessToken else { return }
        status = try? await BackendClient.shared.monobankStatus(token: token)
    }

    private func connect() {
        guard let token = authSession.accessToken else { return }
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                status = try await BackendClient.shared.connectMonobank(token: token, personalToken: tokenInput)
                tokenInput = ""
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func disconnect() {
        guard let token = authSession.accessToken else { return }
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                try await BackendClient.shared.disconnectMonobank(token: token)
                status = nil
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
