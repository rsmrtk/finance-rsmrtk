import SwiftUI
import AuthenticationServices

struct AccountSectionView: View {
    @Environment(AuthSession.self) private var authSession
    @Environment(RemoteStore.self) private var remoteStore

    @State private var isSigningIn = false
    @State private var errorMessage: String?

    var body: some View {
        Section("Обліковий запис") {
            if authSession.isSignedIn {
                signedInContent
            } else {
                signedOutContent
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    @ViewBuilder
    private var signedInContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(authSession.userEmail?.isEmpty == false ? authSession.userEmail! : "Увійшли через Apple ID")
                .font(.subheadline)
            Text("Дані синхронізуються з сервером і не зникнуть при перевстановленні")
                .font(.caption)
                .foregroundStyle(.secondary)
        }

        if remoteStore.isSyncing {
            HStack {
                ProgressView()
                Text("Синхронізація...")
                    .foregroundStyle(.secondary)
            }
        } else {
            Button("Синхронізувати зараз") {
                Task { await remoteStore.refreshAll() }
            }
        }

        Button("Вийти", role: .destructive) {
            authSession.signOut()
            remoteStore.reset()
        }
    }

    @ViewBuilder
    private var signedOutContent: some View {
        SignInWithAppleButton(.signIn) { request in
            request.requestedScopes = [.email]
        } onCompletion: { result in
            handle(result)
        }
        .signInWithAppleButtonStyle(.black)
        .frame(height: 44)
        .disabled(isSigningIn)

        Text("Увійдіть, щоб дані зберігались на сервері й переживали перевстановлення застосунку.")
            .font(.caption)
            .foregroundStyle(.secondary)

        if isSigningIn {
            ProgressView()
        }
    }

    private func handle(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .failure(let error):
            errorMessage = error.localizedDescription

        case .success(let authorization):
            guard
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = credential.identityToken,
                let identityToken = String(data: tokenData, encoding: .utf8)
            else {
                errorMessage = "Не вдалося отримати токен Apple"
                return
            }

            isSigningIn = true
            Task {
                defer { isSigningIn = false }
                do {
                    let reply = try await BackendClient.shared.signInWithApple(identityToken: identityToken)
                    authSession.store(accessToken: reply.accessToken, userID: reply.user.id, userEmail: reply.user.email)
                    errorMessage = nil
                    await remoteStore.refreshAll()
                } catch {
                    errorMessage = "Не вдалося увійти: \(error.localizedDescription)"
                }
            }
        }
    }
}
