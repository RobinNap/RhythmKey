import SwiftUI

struct InfoView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFeature: Feature?
    
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
        }
    }
} 