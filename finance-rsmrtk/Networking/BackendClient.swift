import Foundation
import GRPCCore
import GRPCNIOTransportHTTP2
import SwiftProtobuf

/// Thin wrapper around the generated gRPC clients for the finance-engine
/// backend. One long-lived `GRPCClient` for the app's lifetime; each call
/// attaches the current access token (if any) as a Bearer authorization
/// header.
@MainActor
final class BackendClient {
    static let shared = BackendClient()

    private let grpcClient: GRPCClient<HTTP2ClientTransport.TransportServices>

    private init() {
        let transport: HTTP2ClientTransport.TransportServices
        do {
            transport = try HTTP2ClientTransport.TransportServices(
                target: .dns(host: APIConfig.host, port: APIConfig.port),
                transportSecurity: APIConfig.useTLS ? .tls : .plaintext
            )
        } catch {
            fatalError("Failed to create gRPC transport: \(error)")
        }

        let client = GRPCClient(transport: transport)
        grpcClient = client

        Task {
            try? await client.runConnections()
        }
    }

    private func metadata(token: String?) -> Metadata {
        guard let token else { return [:] }
        return ["authorization": "Bearer \(token)"]
    }

    // MARK: Auth

    func signInWithApple(identityToken: String) async throws -> SignInWithAppleReply {
        let client = AuthService.Client(wrapping: grpcClient)
        let request = SignInWithAppleRequest.with { $0.identityToken = identityToken }
        return try await client.signInWithApple(request)
    }

    // MARK: Categories

    func listCategories(token: String) async throws -> [CategoryModel.Category] {
        let client = CategoryService.Client(wrapping: grpcClient)
        let reply = try await client.categoryList(CategoryListRequest(), metadata: metadata(token: token))
        return reply.categories
    }

    func createCategory(
        token: String,
        name: String,
        iconName: String,
        colorHex: String,
        type: TransactionTypeModel.TransactionType
    ) async throws -> CategoryModel.Category {
        let client = CategoryService.Client(wrapping: grpcClient)
        let request = CategoryCreateRequest.with {
            $0.name = name
            $0.iconName = iconName
            $0.colorHex = colorHex
            $0.type = type
        }
        let reply = try await client.categoryCreate(request, metadata: metadata(token: token))
        return reply.category
    }

    func deleteCategory(token: String, categoryID: String) async throws {
        let client = CategoryService.Client(wrapping: grpcClient)
        let request = CategoryDeleteRequest.with { $0.categoryID = categoryID }
        _ = try await client.categoryDelete(request, metadata: metadata(token: token))
    }

    // MARK: Transactions

    func listTransactions(token: String) async throws -> [TransactionModel.Transaction] {
        let client = TransactionService.Client(wrapping: grpcClient)
        let reply = try await client.transactionList(TransactionListRequest(), metadata: metadata(token: token))
        return reply.transactions
    }

    func createTransaction(
        token: String,
        amount: String,
        currency: CurrencyModel.Currency,
        type: TransactionTypeModel.TransactionType,
        date: String,
        note: String,
        categoryID: String
    ) async throws -> TransactionModel.Transaction {
        let client = TransactionService.Client(wrapping: grpcClient)
        let request = TransactionCreateRequest.with {
            $0.amount = amount
            $0.currency = currency
            $0.type = type
            $0.date = date
            $0.note = note
            $0.categoryID = categoryID
        }
        let reply = try await client.transactionCreate(request, metadata: metadata(token: token))
        return reply.transaction
    }

    func deleteTransaction(token: String, transactionID: String) async throws {
        let client = TransactionService.Client(wrapping: grpcClient)
        let request = TransactionDeleteRequest.with { $0.transactionID = transactionID }
        _ = try await client.transactionDelete(request, metadata: metadata(token: token))
    }

    // MARK: Rates

    func listRates(token: String) async throws -> [RateModel.Rate] {
        let client = RateService.Client(wrapping: grpcClient)
        let reply = try await client.rateList(RateListRequest(), metadata: metadata(token: token))
        return reply.rates
    }
}
