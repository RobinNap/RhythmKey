import SwiftUI
import StoreKit

struct InfoView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFeature: Feature?
    @State private var showingTipSheet = false
    @StateObject private var storeManager = StoreManager.shared
    
    enum Feature: String, Identifiable {
        case tapTempo, fineTuning, keyMatching, metronome
        
        var id: String { self.rawValue }
        
        var title: String {
            switch self {
            case .tapTempo: return "Tap Tempo"
            case .fineTuning: return "Fine Tuning"
            case .keyMatching: return "Key Matching"
            case .metronome: return "Metronome"
            }
        }
        
        var description: String {
            switch self {
            case .tapTempo:
                return """
                The large center button is your tempo input.
                
                • Tap it steadily to the beat of your music
                • More taps = more accurate reading
                • The app averages your recent taps
                • Tap at least 4 times for best results
                """
            case .fineTuning:
                return """
                Fine-tune the BPM by dragging the number:
                
                • Drag up to increase tempo
                • Drag down to decrease tempo
                • Small movements for precise control
                • Range: 30-300 BPM
                """
            case .keyMatching:
                return """
                Find musically related keys:
                
                • Tap any key to select it
                • Green keys are harmonically related
                • Red keys may cause dissonance
                • Switch between Major/Minor scales
                • Tap selected key again to clear
                """
            case .metronome:
                return """
                Feel the beat with haptic feedback:
                
                • Toggle with the wave icon
                • Vibrates on every beat
                • Automatically syncs with BPM
                """
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach([Feature.tapTempo, .fineTuning, .keyMatching, .metronome]) { feature in
                        Button(action: { selectedFeature = feature }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(feature.title)
                                        .font(.headline)
                                    Text("Tap to learn more")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Features")
                }
                
                Section {
                    Button(action: { showingTipSheet = true }) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.pink)
                            VStack(alignment: .leading) {
                                Text("Support Development")
                                    .foregroundColor(.primary)
                                Text("Buy me a croissant 🥐")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        if let url = URL(string: "mailto:support@lumonlabs.io") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Spacer()
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.accentColor)
                            Text("Contact Support")
                                .foregroundColor(.accentColor)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Information")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedFeature) { feature in
                NavigationView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(feature.title)
                            .font(.title)
                            .bold()
                        
                        Text(feature.description)
                            .lineSpacing(8)
                        
                        Spacer()
                    }
                    .padding()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                selectedFeature = nil
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingTipSheet) {
                TipView(storeManager: storeManager)
            }
            .task {
                if storeManager.products.isEmpty {
                    await storeManager.loadProducts()
                }
            }
        }
    }
}

struct TipView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var storeManager: StoreManager
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                HeaderSection()
                
                ProductSection(storeManager: storeManager)
                
                Spacer()
            }
            .padding(.top, 30)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Purchase Error", isPresented: $showingError, presenting: storeManager.purchaseError) { _ in
                Button("OK", role: .cancel) { }
            } message: { error in
                Text(error)
            }
            .alert("Thank You!", isPresented: .init(
                get: { storeManager.purchaseSuccess },
                set: { if !$0 { storeManager.resetPurchaseSuccess() } }
            )) {
                Button("OK") {
                    storeManager.resetPurchaseSuccess()
                    dismiss()
                }
            } message: {
                Text("Your support is greatly appreciated!")
            }
        }
    }
}

// Header section component
private struct HeaderSection: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Support RhythmKey")
                .font(.title2)
                .bold()
            
            Text("If you're enjoying RhythmKey and would like to support its development, consider treating me to a croissant! Your support helps keep the app ad-free and enables future updates.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}

// Product section component
private struct ProductSection: View {
    @ObservedObject var storeManager: StoreManager
    
    var body: some View {
        Group {
            if storeManager.isLoading {
                ProgressView()
                    .padding(.top, 30)
            } else if storeManager.products.isEmpty {
                VStack {
                    Text("Unable to load products")
                        .foregroundColor(.secondary)
                    Button("Try Again") {
                        Task {
                            await storeManager.reloadProducts()
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(.top, 30)
            } else {
                VStack(spacing: 12) {
                    ForEach(storeManager.products) { product in
                        TipButton(product: product)
                    }
                }
                .padding(.top)
            }
        }
    }
}

struct TipButton: View {
    let product: Product
    
    var body: some View {
        Button(action: {
            Task {
                await StoreManager.shared.purchase(product)
            }
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.displayName)
                        .font(.headline)
                    Text(product.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    Text(product.displayPrice)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "heart.fill")
                    .foregroundColor(.pink)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
    }
} 