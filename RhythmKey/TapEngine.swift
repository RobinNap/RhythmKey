import Foundation
import SwiftUI

class TapEngine: ObservableObject {
    @Published var currentBPM: Double = 125.0
    private var tapHistory: [(timestamp: TimeInterval, interval: TimeInterval)] = []
    private let maxHistorySize = 12
    private var lastTapTime: TimeInterval?
    private var confidenceLevel: Double = 0.0
    
    // Constants for BPM calculation
    private let minBPM: Double = 30.0
    private let maxBPM: Double = 300.0
    private let minInterval: TimeInterval = 0.2  // 300 BPM
    private let maxInterval: TimeInterval = 2.0   // 30 BPM
    
    func tap() {
        let now = ProcessInfo.processInfo.systemUptime
        
        if let lastTap = lastTapTime {
            let interval = now - lastTap
            
            // Only process taps within valid BPM range
            if interval >= minInterval && interval <= maxInterval {
                // Add new tap to history
                tapHistory.append((timestamp: now, interval: interval))
                
                // Keep history size limited
                if tapHistory.count > maxHistorySize {
                    tapHistory.removeFirst()
                }
                
                updateBPM()
            }
        }
        
        lastTapTime = now
        
        // Reset if there's been a long pause
        if let lastTap = lastTapTime,
           now - lastTap > maxInterval {
            reset()
        }
    }
    
    private func updateBPM() {
        guard tapHistory.count >= 2 else { return }
        
        // Calculate tempo clusters
        let clusters = analyzeTempoClusters()
        
        // Find the most consistent cluster
        if let dominantCluster = clusters.max(by: { $0.confidence < $1.confidence }) {
            let newBPM = 60.0 / dominantCluster.interval
            
            // Update confidence level
            confidenceLevel = dominantCluster.confidence
            
            // Apply adaptive smoothing based on confidence
            let smoothingFactor = calculateSmoothingFactor()
            currentBPM = lerp(currentBPM, newBPM, smoothingFactor)
            
            // Ensure BPM is within valid range
            currentBPM = currentBPM.clamped(to: minBPM...maxBPM)
        }
    }
    
    private func analyzeTempoClusters() -> [(interval: Double, confidence: Double)] {
        let intervals = tapHistory.map { $0.interval }
        var clusters: [(interval: Double, confidence: Double)] = []
        
        // Group similar intervals together
        for interval in intervals {
            if let existingClusterIndex = clusters.firstIndex(where: { abs($0.interval - interval) < 0.05 }) {
                // Update existing cluster
                clusters[existingClusterIndex].confidence += 1
            } else {
                // Create new cluster
                clusters.append((interval: interval, confidence: 1))
            }
        }
        
        // Normalize confidence values
        let totalConfidence = clusters.map(\.confidence).reduce(0, +)
        return clusters.map { ($0.interval, $0.confidence / totalConfidence) }
    }
    
    private func calculateSmoothingFactor() -> Double {
        // Adaptive smoothing based on confidence and history size
        let historyWeight = Double(tapHistory.count) / Double(maxHistorySize)
        let confidenceWeight = confidenceLevel
        return lerp(0.8, 0.2, historyWeight * confidenceWeight)
    }
    
    private func reset() {
        tapHistory.removeAll()
        confidenceLevel = 0.0
        lastTapTime = Optional.none
    }
    
    private func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double {
        return a + (b - a) * t
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        return min(max(self, range.lowerBound), range.upperBound)
    }
} 