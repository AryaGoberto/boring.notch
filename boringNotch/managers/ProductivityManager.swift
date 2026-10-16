//
//  ProductivityManager.swift
//  boringNotch
//

import AppKit
import Combine
import Darwin
import Foundation
import SwiftUI

public struct ClipboardItem: Identifiable, Equatable {
    public let id: UUID
    public let text: String
    public let timestamp: Date

    public init(id: UUID = UUID(), text: String, timestamp: Date = Date()) {
        self.id = id
        self.text = text
        self.timestamp = timestamp
    }
}

public enum PomodoroMode: String, CaseIterable {
    case focus = "Focus"
    case shortBreak = "Break"

    public var totalSeconds: Int {
        switch self {
        case .focus: return 25 * 60
        case .shortBreak: return 5 * 60
        }
    }
}

public class ProductivityManager: ObservableObject {
    public static let shared = ProductivityManager()

    // MARK: - Clipboard History State
    @Published public var clipboardHistory: [ClipboardItem] = []
    @Published public var lastCopiedId: UUID? = nil
    private var lastChangeCount: Int = NSPasteboard.general.changeCount
    private var clipboardTimer: AnyCancellable?

    // MARK: - Pomodoro State
    @Published public var pomodoroMode: PomodoroMode = .focus
    @Published public var timeRemaining: Int = 25 * 60
    @Published public var isPomodoroRunning: Bool = false
    private var pomodoroTimer: AnyCancellable?

    // MARK: - Quick Actions State
    @Published public var isMicMuted: Bool = false

    private init() {
        checkMicMuted()
        startClipboardObserver()
    }

    // MARK: - Clipboard History Methods
    public func startClipboardObserver() {
        clipboardTimer = Timer.publish(every: 0.8, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkPasteboard()
            }
    }

    private func checkPasteboard() {
        let currentCount = NSPasteboard.general.changeCount
        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount

        guard let copiedString = NSPasteboard.general.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !copiedString.isEmpty else { return }

        // Don't add duplicate if it matches the latest item
        if let first = clipboardHistory.first, first.text == copiedString {
            return
        }

        let newItem = ClipboardItem(text: copiedString)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            clipboardHistory.insert(newItem, at: 0)
            if clipboardHistory.count > 25 {
                clipboardHistory.removeLast()
            }
        }
    }

    public func copyToClipboard(_ item: ClipboardItem) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(item.text, forType: .string)
        lastChangeCount = NSPasteboard.general.changeCount
        lastCopiedId = item.id

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            if self?.lastCopiedId == item.id {
                self?.lastCopiedId = nil
            }
        }
    }

    public func clearClipboardHistory() {
        withAnimation(.easeOut(duration: 0.2)) {
            clipboardHistory.removeAll()
        }
    }

    // MARK: - Pomodoro Methods
    public func togglePomodoro() {
        if isPomodoroRunning {
            pausePomodoro()
        } else {
            startPomodoro()
        }
    }

    public func startPomodoro() {
        guard !isPomodoroRunning else { return }
        isPomodoroRunning = true
        pomodoroTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tickPomodoro()
            }
    }

    public func pausePomodoro() {
        isPomodoroRunning = false
        pomodoroTimer?.cancel()
        pomodoroTimer = nil
    }

    public func resetPomodoro() {
        pausePomodoro()
        timeRemaining = pomodoroMode.totalSeconds
    }

    public func switchPomodoroMode(_ mode: PomodoroMode) {
        pomodoroMode = mode
        resetPomodoro()
    }

    private func tickPomodoro() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            // Timer Finished! Play alert beep and switch mode
            NSSound.beep()
            pausePomodoro()
            let nextMode: PomodoroMode = (pomodoroMode == .focus) ? .shortBreak : .focus
            switchPomodoroMode(nextMode)
        }
    }

    public var formattedPomodoroTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    public var pomodoroProgress: Double {
        let total = Double(pomodoroMode.totalSeconds)
        return total > 0 ? Double(pomodoroMode.totalSeconds - timeRemaining) / total : 0.0
    }

    // MARK: - Quick Actions
    public func toggleMicMute() {
        let targetVolume = isMicMuted ? 75 : 0
        let script = "set volume input volume \(targetVolume)"
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&error)
        }
        checkMicMuted()
    }

    public func checkMicMuted() {
        let script = "input volume of (get volume settings)"
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            let result = appleScript.executeAndReturnError(&error)
            if let volStr = result.stringValue, let vol = Int(volStr) {
                DispatchQueue.main.async {
                    self.isMicMuted = (vol == 0)
                }
                return
            }
        }
        isMicMuted = false
    }

    public func lockScreen() {
        typealias SACLockScreenImmediateFunc = @convention(c) () -> Void
        if let handle = dlopen("/System/Library/PrivateFrameworks/login.framework/Versions/Current/login", RTLD_LAZY) {
            if let sym = dlsym(handle, "SACLockScreenImmediate") {
                let lock = unsafeBitCast(sym, to: SACLockScreenImmediateFunc.self)
                lock()
                dlclose(handle)
                return
            }
            dlclose(handle)
        }
        // Fallback
        let task = Process()
        task.launchPath = "/usr/bin/pmset"
        task.arguments = ["displaysleepnow"]
        try? task.run()
    }

    public func sleepDisplay() {
        let task = Process()
        task.launchPath = "/usr/bin/pmset"
        task.arguments = ["displaysleepnow"]
        try? task.run()
    }

    public func openScreenshotTool() {
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Screenshot.app"))
    }
}
