import SwiftUI
import Foundation

// DEBUG: Monitor for main thread blocking
class MainThreadMonitor {
    static let shared = MainThreadMonitor()
    private var monitoringTask: Task<Void, Never>?
    private var lastHeartbeat = Date()
    private let heartbeatInterval: TimeInterval = 0.1 // 100ms
    
    private init() {}
    
    func startMonitoring() {
        print("🔍 Starting main thread monitoring...")
        
        monitoringTask = Task { @MainActor in
            while !Task.isCancelled {
                let now = Date()
                let timeSinceLastHeartbeat = now.timeIntervalSince(lastHeartbeat)
                
                // If more than 500ms since last heartbeat, main thread was blocked
                if timeSinceLastHeartbeat > 0.5 {
                    print("🚨 MAIN THREAD BLOCKED for \(String(format: "%.2f", timeSinceLastHeartbeat))s")
                    
                    // Print stack trace to help identify the blocking code
                    Thread.callStackSymbols.forEach { symbol in
                        print("  📍 \(symbol)")
                    }
                }
                
                lastHeartbeat = now
                
                // Wait for next heartbeat
                try? await Task.sleep(nanoseconds: UInt64(heartbeatInterval * 1_000_000_000))
            }
        }
    }
    
    func stopMonitoring() {
        monitoringTask?.cancel()
        monitoringTask = nil
        print("🔍 Stopped main thread monitoring")
    }
    
    deinit {
        stopMonitoring()
    }
}

// DEBUG: Performance timing wrapper
@propertyWrapper
struct Timed<T> {
    private var value: T
    private let operation: String
    
    init(wrappedValue: T, _ operation: String) {
        self.value = wrappedValue
        self.operation = operation
    }
    
    var wrappedValue: T {
        get {
            let start = CFAbsoluteTimeGetCurrent()
            defer {
                let duration = CFAbsoluteTimeGetCurrent() - start
                if duration > 0.1 {
                    print("⏱️ SLOW: \(operation) took \(String(format: "%.3f", duration))s")
                }
            }
            return value
        }
        set {
            value = newValue
        }
    }
}

// DEBUG: View modifier to track view lifecycle performance
struct PerformanceTracker: ViewModifier {
    let viewName: String
    @State private var appeared = false
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                let start = CFAbsoluteTimeGetCurrent()
                if !appeared {
                    print("👁️ \(viewName) first appear")
                    appeared = true
                    
                    // Check if this view is taking too long to appear
                    DispatchQueue.main.async {
                        let duration = CFAbsoluteTimeGetCurrent() - start
                        if duration > 0.5 {
                            print("🐌 SLOW VIEW: \(viewName) took \(String(format: "%.3f", duration))s to appear")
                        }
                    }
                }
            }
            .onDisappear {
                print("👁️ \(viewName) disappeared")
            }
    }
}

extension View {
    func trackPerformance(_ viewName: String) -> some View {
        self.modifier(PerformanceTracker(viewName: viewName))
    }
}

// DEBUG: Thread-safe logger
class ThreadSafeLogger {
    static let shared = ThreadSafeLogger()
    private let queue = DispatchQueue(label: "logger", qos: .utility)
    
    private init() {}
    
    func log(_ message: String, level: LogLevel = .info) {
        queue.async {
            let timestamp = DateFormatter.logFormatter.string(from: Date())
            let threadInfo = Thread.isMainThread ? "[MAIN]" : "[BG]"
            print("\(timestamp) \(threadInfo) \(level.prefix) \(message)")
        }
    }
}

enum LogLevel {
    case info, warning, error, performance
    
    var prefix: String {
        switch self {
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .performance: return "⏱️"
        }
    }
}

extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}

// DEBUG: Enhanced HomeView with monitoring
struct DebugHomeView: View {
    @State private var showingParentView = false
    @State private var showingsSubscriptionStatusView = false
    @StateObject private var container = PlaylistsContainer.shared
    @State private var showingParentAuth = false
    
    private static let initialColumns = 2
    @State private var gridColumns = Array(repeating: GridItem(.flexible()), count: initialColumns)
    
    var body: some View {
        NavigationStack {
            Color.white
                .overlay {
                    if container.isLoading {
                        LoadingView(message: container.loadingMessage)
                    } else if container.playlists.isEmpty && container.hasInitialized {
                        EmptyPlaylistView(showCreation: $showingParentView)
                    } else if !container.playlists.isEmpty {
                        PlaylistGridContent(container: container, gridColumns: gridColumns)
                    } else {
                        VStack {
                            Text("🎵")
                                .font(.largeTitle)
                            Text("Loading Tune Gallery...")
                                .captionBold()
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .navigationTitle("Tune Library")
                .appTitle()
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { showingParentAuth = true }) {
                            Image(systemName: "info")
                        }
                    }
                }
                .sheet(isPresented: $showingParentAuth) {
                    ParentAuthenticationView {
                        showingParentAuth = false
                        showingParentView = true
                    }
                }
                .sheet(isPresented: $showingParentView) {
                    ParentView()
                }
                .trackPerformance("HomeView")
                .onAppear {
                    // Start monitoring after home view appears
                    MainThreadMonitor.shared.startMonitoring()
                    ThreadSafeLogger.shared.log("HomeView appeared")
                }
                .onDisappear {
                    MainThreadMonitor.shared.stopMonitoring()
                    ThreadSafeLogger.shared.log("HomeView disappeared")
                }
        }
    }
}

// Use this in your ZiekieApp for debugging
extension ZiekieApp {
    static func enableDebugging() -> some View {
        AppRootView()
            .onAppear {
                MainThreadMonitor.shared.startMonitoring()
                ThreadSafeLogger.shared.log("App launched")
            }
    }
}