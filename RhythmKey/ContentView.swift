//
//  ContentView.swift
//  RhythmKey
//
//  Created by Robin Nap on 05/12/2024.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var tapEngine = TapEngine()
    @State private var lastTapTime: Date?
    @State private var taps: [TimeInterval] = []
    @State private var tapCount: Int = 0
    @State private var rollingWindowSize: Int = 4  // Reduced from 8 to 4 for faster response
    @State private var selectedKey: MusicKey = .C
    @State private var selectedNote: String? = nil
    @State private var dragOffset: CGFloat = 0
    @State private var previousTranslation: CGFloat = 0
    @State private var isMinorMode: Bool = false
    @Namespace private var animation
    @State private var isVibrating: Bool = false
    @State private var vibrateTimer: Timer?
    @State private var showingInfo = false
    
    // Music keys enum
    enum MusicKey: String, CaseIterable {
        case C, G, D, A, E, B = "B/C♭"
        case Gb = "F♯/G♭", Db = "C♯/D♭", Ab = "G♯/A♭", Eb = "D♯/E♭", Bb = "A♯/B♭", F
        
        var relatedKeys: [String] {
            switch self {
            case .C: return ["Am", "F", "Dm", "G", "Em"]
            case .G: return ["Em", "C", "Am", "D", "Bm"]
            case .D: return ["Bm", "G", "Em", "A", "F#m"]
            case .A: return ["F#m", "D", "Bm", "E", "C#m"]
            case .E: return ["C#m", "A", "F#m", "B", "G#m"]
            case .B: return ["G#m", "E", "C#m", "F#", "D#m"]
            case .Gb: return ["D#m", "B", "G#m", "C#", "A#m"]
            case .Db: return ["Bbm", "Gb", "Ebm", "Ab", "Fm"]
            case .Ab: return ["Fm", "Db", "Bbm", "Eb", "Cm"]
            case .Eb: return ["Cm", "Ab", "Fm", "Bb", "Gm"]
            case .Bb: return ["Gm", "Eb", "Cm", "F", "Dm"]
            case .F: return ["Dm", "Bb", "Gm", "C", "Am"]
            }
        }
    }
    
    struct KeyLabel: Identifiable {
        let id = UUID()
        let note: String
        var isSelected: Bool
        var isRelated: Bool
    }
    
    struct KeyGrid {
        static func generateKeys(selectedNote: String?, isMinor: Bool) -> [KeyLabel] {
            let notes = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
            
            // Define related notes for both major and minor keys
            let relatedNotes: [String: [String]] = isMinor ? [
                // Minor keys relationships
                "C": ["C", "D", "D♯", "F", "G", "G♯", "A♯"],  // C minor
                "C♯": ["C♯", "D♯", "E", "F♯", "G♯", "A", "B"],
                "D": ["D", "E", "F", "G", "A", "A♯", "C"],
                "D♯": ["D♯", "F", "F♯", "G♯", "A♯", "B", "C♯"],
                "E": ["E", "F♯", "G", "A", "B", "C", "D"],
                "F": ["F", "G", "G♯", "A♯", "C", "C♯", "D♯"],
                "F♯": ["F♯", "G♯", "A", "B", "C♯", "D", "E"],
                "G": ["G", "A", "A♯", "C", "D", "D♯", "F"],
                "G♯": ["G♯", "A♯", "B", "C♯", "D♯", "E", "F♯"],
                "A": ["A", "B", "C", "D", "E", "F", "G"],
                "A♯": ["A♯", "C", "C♯", "D♯", "F", "F♯", "G♯"],
                "B": ["B", "C♯", "D", "E", "F♯", "G", "A"]
            ] : [
                // Existing major keys relationships
                "C": ["C", "D", "E", "F", "G", "A", "B"],
                "C♯": ["C♯", "D♯", "F", "F♯", "G♯", "A♯"],
                "D": ["D", "E", "F", "G", "A", "B", "C"],
                "D♯": ["D♯", "F", "G", "G♯", "A♯", "C"],
                "E": ["E", "F♯", "G♯", "A", "B", "C♯", "D"],
                "F": ["F", "G", "A", "A♯", "C", "D", "E"],
                "F♯": ["F♯", "G♯", "A♯", "B", "C♯", "D♯"],
                "G": ["G", "A", "B", "C", "D", "E", "F♯"],
                "G♯": ["G♯", "A♯", "C", "C♯", "D♯", "F"],
                "A": ["A", "B", "C♯", "D", "E", "F♯", "G"],
                "A♯": ["A♯", "C", "D", "D♯", "F", "G"],
                "B": ["B", "C♯", "D♯", "E", "F♯", "G♯", "A"]
            ]
            
            return notes.map { note in
                KeyLabel(
                    note: note,
                    isSelected: note == selectedNote,
                    isRelated: selectedNote != nil ? (relatedNotes[selectedNote!]?.contains(note) ?? false) : false
                )
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(uiColor: .systemBackground)
                    .edgesIgnoringSafeArea(.all)
                
                // Info Button - top left corner
                Button(action: { showingInfo = true }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 22))
                        .foregroundColor(.secondary)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.secondary.opacity(0.2))
                        )
                }
                .position(x: geometry.size.width * 0.1, y: geometry.size.height * 0.06)
                .sheet(isPresented: $showingInfo) {
                    InfoView()
                }
                
                // Vibration Toggle Button - top right corner
                Button(action: toggleVibration) {
                    Image(systemName: isVibrating ? "waveform" : "waveform.slash")
                        .font(.system(size: 22))
                        .foregroundColor(isVibrating ? .accentColor : .secondary)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.secondary.opacity(0.2))
                        )
                }
                .position(x: geometry.size.width * 0.9, y: geometry.size.height * 0.06)
                
                // Top Content - BPM Display
                VStack(spacing: geometry.size.height * 0.02) {
                    Text(String(format: "%.1f", tapEngine.currentBPM))
                        .font(.system(size: min(80, geometry.size.width * 0.2), weight: .bold))
                        .foregroundColor(.primary)
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    let sensitivity: Double = 0.0025
                                    let delta = Double(previousTranslation - gesture.translation.height) * sensitivity
                                    
                                    // Update BPM with limits
                                    let newBPM = tapEngine.currentBPM + delta
                                    tapEngine.currentBPM = min(300, max(30, newBPM))
                                    
                                    // Store the current position for next comparison
                                    previousTranslation = gesture.translation.height
                                    
                                    // Update vibration timer if active
                                    updateVibrateTimer()
                                }
                                .onEnded { _ in
                                    // Reset tracking variables
                                    previousTranslation = 0
                                    dragOffset = 0
                                }
                        )
                        .animation(.interactiveSpring(), value: tapEngine.currentBPM)
                    
                    Text("BPM")
                        .font(.system(size: max(11, min(24, geometry.size.width * 0.06))))
                        .foregroundColor(.secondary)
                        .padding(.bottom, geometry.size.height * 0.01)
                    
                    // Half and Double time
                    HStack(spacing: min(40, geometry.size.width * 0.1)) {
                        VStack(spacing: 4) {
                            Text(String(format: "%.1f", tapEngine.currentBPM/2))
                                .font(.system(size: max(11, min(28, geometry.size.width * 0.07))))
                            Text("½ Time")
                                .font(.system(size: max(11, min(16, geometry.size.width * 0.04))))
                        }
                        .foregroundColor(.secondary)
                        
                        VStack(spacing: 4) {
                            Text(String(format: "%.1f", tapEngine.currentBPM*2))
                                .font(.system(size: max(11, min(28, geometry.size.width * 0.07))))
                            Text("2x Time")
                                .font(.system(size: max(11, min(16, geometry.size.width * 0.04))))
                        }
                        .foregroundColor(.secondary)
                    }
                }
                .position(x: geometry.size.width / 2, y: geometry.size.height * 0.18)
                
                // Center Tap Button
                Button(action: handleTap) {
                    Circle()
                        .fill(Color.accentColor.opacity(0.3))
                        .overlay(
                            Circle()
                                .stroke(Color.accentColor, lineWidth: 3)
                        )
                        .overlay(
                            Text("TAP")
                                .font(.system(size: max(11, min(32, geometry.size.width * 0.08)), weight: .bold))
                                .foregroundColor(.primary)
                        )
                        .frame(
                            width: min(160, max(geometry.size.width * 0.4, 88)),
                            height: min(160, max(geometry.size.width * 0.4, 88))
                        )
                }
                .position(x: geometry.size.width / 2, y: geometry.size.height * 0.48)
                
                // Key Grid
                VStack(spacing: min(12, geometry.size.height * 0.015)) {
                    HStack {
                        Text("Match Key")
                            .font(.system(size: max(11, min(20, geometry.size.width * 0.05))))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // Major/Minor toggle buttons - This part keeps its animation
                        HStack(spacing: 0) {
                            // Major button
                            Button(action: { 
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    isMinorMode = false 
                                }
                            }) {
                                Text("Major")
                                    .font(.system(size: max(11, min(16, geometry.size.width * 0.04))))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        ZStack {
                                            if !isMinorMode {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.accentColor)
                                                    .matchedGeometryEffect(id: "ModeBackground", in: animation)
                                            }
                                        }
                                    )
                                    .foregroundColor(isMinorMode ? .secondary : .primary)
                            }
                            
                            // Minor button
                            Button(action: { 
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    isMinorMode = true 
                                }
                            }) {
                                Text("Minor")
                                    .font(.system(size: max(11, min(16, geometry.size.width * 0.04))))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        ZStack {
                                            if isMinorMode {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.accentColor)
                                                    .matchedGeometryEffect(id: "ModeBackground", in: animation)
                                            }
                                        }
                                    )
                                    .foregroundColor(isMinorMode ? .primary : .secondary)
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.secondary.opacity(0.2))
                        )
                    }
                    
                    // Wrap the LazyVGrid in a non-animated container
                    let keys = KeyGrid.generateKeys(selectedNote: selectedNote, isMinor: isMinorMode)
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: min(12, geometry.size.width * 0.03)) {
                        ForEach(keys) { key in
                            Button(action: { 
                                selectedNote = selectedNote == key.note ? nil : key.note 
                            }) {
                                Text(key.note)
                                    .font(.system(size: max(11, min(20, geometry.size.width * 0.048)), weight: .medium))
                                    .frame(height: max(44, geometry.size.height * 0.055))
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(
                                                key.isSelected ? Color.accentColor :
                                                    selectedNote == nil ? Color.secondary.opacity(0.2) :
                                                    key.isRelated ? Color.green :
                                                    Color.red
                                            )
                                    )
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .animation(nil, value: isMinorMode) // Disable animation for the entire grid
                }
                .padding(.horizontal, min(16, geometry.size.width * 0.04))
                .position(x: geometry.size.width / 2, y: geometry.size.height * 0.82)
            }
            .ignoresSafeArea(.keyboard)
        }
        .task {
            await StoreManager.shared.loadProducts()
        }
    }
    
    private func handleTap() {
        tapEngine.tap()
        updateVibrateTimer()
    }
    
    private func toggleVibration() {
        isVibrating.toggle()
        
        if isVibrating {
            // Calculate interval in seconds from BPM
            let interval = 60.0 / tapEngine.currentBPM
            
            // Create and store the timer
            vibrateTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            }
        } else {
            // Stop and clear the timer
            vibrateTimer?.invalidate()
            vibrateTimer = nil
        }
    }
    
    private func updateVibrateTimer() {
        if isVibrating {
            // Stop current timer
            vibrateTimer?.invalidate()
            
            // Start new timer with updated interval
            let interval = 60.0 / tapEngine.currentBPM
            vibrateTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            }
        }
    }
}

// Add this extension for custom corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

#Preview {
    ContentView()
}
