//
//  MainThreadMonitor.swift
//  Ziekie
//
//  Created by Suzanne Lustenhouwer on 13/07/2025.
//

import SwiftUI
import Foundation

// MARK: - Main Thread Monitor

/// Enhanced main thread monitor for development debugging
class MainThreadMonitor {
    static let shared = MainThreadMonitor()
    
    // MARK: - Properties
    private var monitoringTask: Task<Void, Never>?
    private var lastHeartbeat = Date()
    private var performanceMetrics = PerformanceMetrics()
    
    // MARK: - Configuration
    private let heartbeatInterval: TimeInterval = 0.1 // 100ms
    private let blockingThreshold: TimeInterval = 0.5 // 500ms
    private let warningThreshold: TimeInterval = 0.3 // 300ms
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Start monitoring the main thread
    func startMonitoring() {
        guard monitoringTask == nil else {
            print("🔍 Main thread monitoring already running")
            return
        }
        
        print("🔍 Starting enhanced main thread monitoring...")
        performanceMetrics.reset()
        
        monitoringTask = Task { @MainActor in
            while !Task.isCancelled {
                await self.performHeartbeatCheck()
                
                // Wait for next heartbeat
                try? await Task.sleep(nanoseconds: UInt64(self.heartbeatInterval * 1_000_000_000))
            }
        }
    }
    
    /// Stop monitoring the main thread
    func stopMonitoring() {
        monitoringTask?.cancel()
        monitoringTask = nil
        
        print("🔍 Stopped main thread monitoring")
        print("📊 Final performance metrics:")
        print("   - Total blocks: \(performanceMetrics.totalBlocks)")
        print("   - Total warnings: \(performanceMetrics.totalWarnings)")
        print("   - Longest block: \(String(format: "%.2f", performanceMetrics.longestBlockDuration))s")
        print("   - Average block: \(String(format: "%.2f", performanceMetrics.averageBlockDuration))s")
    }
    
    /// Log a custom performance marker
    func logPerformanceMarker(_ operation: String, duration: TimeInterval) {
        let emoji = duration > 0.5 ? "🐌" : duration > 0.1 ? "⚠️" : "✅"
        print("\(emoji) PERFORMANCE: \(operation) took \(String(format: "%.3f", duration))s")
        
        if duration > 0.1 {
            performanceMetrics.recordOperation(operation, duration: duration)
        }
    }
    
    // MARK: - Private Methods
    
    @MainActor
    private func performHeartbeatCheck() async {
        let now = Date()
        let timeSinceLastHeartbeat = now.timeIntervalSince(lastHeartbeat)
        
        if timeSinceLastHeartbeat > blockingThreshold {
            handleMainThreadBlock(duration: timeSinceLastHeartbeat)
        } else if timeSinceLastHeartbeat > warningThreshold {
            handleMainThreadWarning(duration: timeSinceLastHeartbeat)
        }
        
        lastHeartbeat = now
    }
    
    private func handleMainThreadBlock(duration: TimeInterval) {
        performanceMetrics.recordBlock(duration: duration)
        
        print("🚨 MAIN THREAD BLOCKED for \(String(format: "%.2f", duration))s")
        print("📍 Stack trace:")
        
        // Print relevant stack trace (filter out system calls)
        let relevantSymbols = Thread.callStackSymbols.filter { symbol in
            !symbol.contains("libdispatch") &&
            !symbol.contains("Foundation") &&
            !symbol.contains("UIKit") &&
            !symbol.contains("SwiftUI") &&
            !symbol.contains("CoreFoundation")
        }
        
        for (index, symbol) in relevantSymbols.prefix(5).enumerated() {
            print("   \(index + 1). \(symbol)")
        }
        
        // Provide helpful suggestions
        provideSuggestions(for: duration)
    }
    
    private func handleMainThreadWarning(duration: TimeInterval) {
        performanceMetrics.recordWarning(duration: duration)
        print("⚠️ MAIN THREAD WARNING: \(String(format: "%.2f", duration))s - Consider optimizing")
    }
    
    private func provideSuggestions(for duration: TimeInterval) {
        print("💡 Performance suggestions:")
        
        if duration > 2.0 {
            print("   • Consider using Task.detached for heavy operations")
            print("   • Check for synchronous file I/O operations")
            print("   • Look for blocking network calls")
        } else if duration > 1.0 {
            print("   • Consider using async/await for data operations")
            print("   • Check for heavy computations in view updates")
        } else {
            print("   • Consider lazy loading for large datasets")
            print("   • Check for inefficient view rendering")
        }
    }
    
    deinit {
        stopMonitoring()
    }
}

// MARK: - Performance Metrics

private class PerformanceMetrics {
    private(set) var totalBlocks = 0
    private(set) var totalWarnings = 0
    private(set) var longestBlockDuration: TimeInterval = 0
    private(set) var totalBlockDuration: TimeInterval = 0
    private var operations: [String: TimeInterval] = [:]
    
    var averageBlockDuration: TimeInterval {
        guard totalBlocks > 0 else { return 0 }
        return totalBlockDuration / Double(totalBlocks)
    }
    
    func recordBlock(duration: TimeInterval) {
        totalBlocks += 1
        totalBlockDuration += duration
        longestBlockDuration = max(longestBlockDuration, duration)
    }
    
    func recordWarning(duration: TimeInterval) {
        totalWarnings += 1
    }
    
    func recordOperation(_ operation: String, duration: TimeInterval) {
        operations[operation] = max(operations[operation] ?? 0, duration)
    }
    
    func reset() {
        totalBlocks = 0
        totalWarnings = 0
        longestBlockDuration = 0
        totalBlockDuration = 0
        operations.removeAll()
    }
}

// MARK: - Performance Timing Wrapper

/// A property wrapper to time operations automatically
@propertyWrapper
struct TimedOperation<T> {
    private var value: T
    private let operation: String
    private let threshold: TimeInterval
    
    init(wrappedValue: T, _ operation: String, threshold: TimeInterval = 0.1) {
        self.value = wrappedValue
        self.operation = operation
        self.threshold = threshold
    }
    
    var wrappedValue: T {
        get {
            let startTime = CFAbsoluteTimeGetCurrent()
            defer {
                let duration = CFAbsoluteTimeGetCurrent() - startTime
                if duration > threshold {
                    MainThreadMonitor.shared.logPerformanceMarker(operation, duration: duration)
                }
            }
            return value
        }
        set {
            value = newValue
        }
    }
}

// MARK: - View Performance Tracker

/// Enhanced view performance tracker with better insights
struct ViewPerformanceTracker: ViewModifier {
    let viewName: String
    let trackingLevel: TrackingLevel
    
    @State private var appeared = false
    @State private var appearTime: CFAbsoluteTime?
    
    enum TrackingLevel {
        case basic      // Only track appear/disappear
        case detailed   // Track timing and performance
        case full       // Track everything including state changes
    }
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                handleViewAppear()
            }
            .onDisappear {
                handleViewDisappear()
            }
    }
    
    private func handleViewAppear() {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        if !appeared {
            appeared = true
            appearTime = startTime
            
            switch trackingLevel {
            case .basic:
                print("👁️ \(viewName) appeared")
            case .detailed, .full:
                print("👁️ \(viewName) first appearance")
                
                // Check if view takes too long to appear
                DispatchQueue.main.async {
                    let duration = CFAbsoluteTimeGetCurrent() - startTime
                    if duration > 0.5 {
                        print("🐌 SLOW VIEW: \(viewName) took \(String(format: "%.3f", duration))s to appear")
                    } else if duration > 0.2 {
                        print("⚠️ MODERATE: \(viewName) took \(String(format: "%.3f", duration))s to appear")
                    }
                }
            }
        }
    }
    
    private func handleViewDisappear() {
        switch trackingLevel {
        case .basic:
            print("👁️ \(viewName) disappeared")
        case .detailed, .full:
            if let appearTime = appearTime {
                let totalTime = CFAbsoluteTimeGetCurrent() - appearTime
                print("👁️ \(viewName) disappeared (visible for \(String(format: "%.2f", totalTime))s)")
            } else {
                print("👁️ \(viewName) disappeared")
            }
        }
        
        appeared = false
        appearTime = nil
    }
}

// MARK: - View Extensions

extension View {
    /// Track basic view performance
    func trackPerformance(_ viewName: String) -> some View {
        self.modifier(ViewPerformanceTracker(viewName: viewName, trackingLevel: .basic))
    }
    
    /// Track detailed view performance
    func trackDetailedPerformance(_ viewName: String) -> some View {
        self.modifier(ViewPerformanceTracker(viewName: viewName, trackingLevel: .detailed))
    }
    
    /// Track full view performance
    func trackFullPerformance(_ viewName: String) -> some View {
        self.modifier(ViewPerformanceTracker(viewName: viewName, trackingLevel: .full))
    }
}

// MARK: - Thread-Safe Logger

/// Enhanced thread-safe logger with better formatting and filtering
class ThreadSafeLogger {
    static let shared = ThreadSafeLogger()
    
    private let queue = DispatchQueue(label: "com.ziekie.logger", qos: .utility)
    private let dateFormatter: DateFormatter
    
    private init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss.SSS"
    }
    
    func log(_ message: String, level: LogLevel = .info, category: String? = nil) {
        queue.async {
            let timestamp = self.dateFormatter.string(from: Date())
            let threadInfo = Thread.isMainThread ? "[MAIN]" : "[BG]"
            let categoryInfo = category.map { "[\($0)]" } ?? ""
            
            print("\(timestamp) \(threadInfo)\(categoryInfo) \(level.prefix) \(message)")
        }
    }
    
    func logPerformance(_ operation: String, duration: TimeInterval, threshold: TimeInterval = 0.1) {
        guard duration > threshold else { return }
        
        let level: LogLevel = duration > 0.5 ? .error : duration > 0.2 ? .warning : .performance
        log("\(operation) took \(String(format: "%.3f", duration))s", level: level, category: "PERF")
    }
}

enum LogLevel {
    case info, warning, error, performance, debug
    
    var prefix: String {
        switch self {
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .performance: return "⏱️"
        case .debug: return "🔧"
        }
    }
}

// MARK: - Enhanced Development Tools

/// Development-only view monitoring tools
struct DevelopmentTools {
    
    /// Log view hierarchy changes
    static func logViewHierarchy(_ viewName: String, action: String) {
        #if DEBUG
        ThreadSafeLogger.shared.log("\(viewName) - \(action)", level: .debug, category: "VIEW")
        #endif
    }
    
    /// Track network requests
    static func trackNetworkRequest(_ url: String, duration: TimeInterval) {
        ThreadSafeLogger.shared.logPerformance("Network request to \(url)", duration: duration, threshold: 0.5)
    }
    
    /// Track database operations
    static func trackDatabaseOperation(_ operation: String, duration: TimeInterval) {
        ThreadSafeLogger.shared.logPerformance("Database \(operation)", duration: duration, threshold: 0.1)
    }
}

// MARK: - App Integration

extension ZiekieApp {
    /// Enable comprehensive debugging for development
    static func enableDevelopmentDebugging() -> some View {
        AppRootView()
            .onAppear {
                MainThreadMonitor.shared.startMonitoring()
                ThreadSafeLogger.shared.log("App launched with development debugging enabled", level: .info, category: "APP")
            }
            .onDisappear {
                MainThreadMonitor.shared.stopMonitoring()
                ThreadSafeLogger.shared.log("App disappeared", level: .info, category: "APP")
            }
    }
}
