import StoreKit

@MainActor
class StoreManager: ObservableObject {
    static let shared = StoreManager()
    
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchaseError: String?
    @Published private(set) var purchaseSuccess = false
    @Published private(set) var isLoading = false
    
    private var transactionListener: Task<Void, Error>?
    
    private let productIdentifiers = [
        "com.robinnap.rhythmkey.smalltip",
        "com.robinnap.rhythmkey.mediumtip",
        "com.robinnap.rhythmkey.largetip"
    ]
    
    private init() {
        // Start listening for transactions
        transactionListener = listenForTransactions()
        
        // Preload products immediately
        Task { @MainActor in
            await loadProducts()
        }
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                await self.handle(transactionResult: result)
            }
        }
    }
    
    private func handle(transactionResult result: VerificationResult<Transaction>) async {
        let transaction: Transaction
        
        switch result {
        case .verified(let verifiedTransaction):
            transaction = verifiedTransaction
        case .unverified:
            // Handle unverified transaction if needed
            return
        }
        
        // Handle the transaction
        await transaction.finish()
        
        // Update UI on main actor
        await MainActor.run {
            self.purchaseSuccess = true
        }
    }
    
    func loadProducts() async {
        isLoading = true
        do {
            // Add debug print
            print("Starting to load products for IDs:", productIdentifiers)
            
            products = try await Product.products(for: productIdentifiers)
            products.sort { $0.price < $1.price }
            
            // Add debug print
            print("Successfully loaded \(products.count) products")
            for product in products {
                print("Product: \(product.displayName) - \(product.displayPrice)")
            }
            
        } catch {
            print("Failed to load products. Error:", error)
            purchaseError = "Failed to load products: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func purchase(_ product: Product) async {
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    // Finish the transaction
                    await transaction.finish()
                    purchaseSuccess = true
                    
                case .unverified(_, let error):
                    purchaseError = error.localizedDescription
                }
                
            case .userCancelled:
                break
                
            case .pending:
                purchaseError = "Purchase is pending approval"
                
            @unknown default:
                purchaseError = "Unknown error occurred"
            }
            
        } catch {
            purchaseError = error.localizedDescription
        }
    }
    
    func resetPurchaseSuccess() {
        purchaseSuccess = false
    }
    
    func reloadProducts() async {
        await loadProducts()
    }
} 