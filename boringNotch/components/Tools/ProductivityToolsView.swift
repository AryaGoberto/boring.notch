//
//  ProductivityToolsView.swift
//  boringNotch
//

import SwiftUI

struct ProductivityToolsView: View {
    @ObservedObject var productivity = ProductivityManager.shared

    var body: some View {
        HStack(spacing: 12) {
            // MARK: - Column 1: Quick Actions & Pomodoro Timer
            ToolCard(title: "Focus & Actions", icon: "bolt.fill", accentColor: .yellow) {
                VStack(spacing: 8) {
                    // Quick Action Buttons Row
                    HStack(spacing: 6) {
                        // Mic Mute Toggle
                        Button(action: {
                            productivity.toggleMicMute()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: productivity.isMicMuted ? "mic.slash.fill" : "mic.fill")
                                    .font(.system(size: 11))
                                Text(productivity.isMicMuted ? "Muted" : "Mic On")
                                    .font(.system(size: 10, weight: .semibold))
                            }
                            .foregroundColor(productivity.isMicMuted ? .white : .white.opacity(0.85))
                            .padding(.horizontal, 8)
                            .frame(height: 26)
                            .background(
                                Capsule()
                                    .fill(productivity.isMicMuted ? Color.red.opacity(0.85) : Color.white.opacity(0.12))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())

                        // Lock Screen Button
                        Button(action: {
                            productivity.lockScreen()
                        }) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.85))
                                .frame(width: 26, height: 26)
                                .background(Circle().fill(Color.white.opacity(0.12)))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help("Lock Mac")

                        // Screenshot Tool
                        Button(action: {
                            productivity.openScreenshotTool()
                        }) {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.85))
                                .frame(width: 26, height: 26)
                                .background(Circle().fill(Color.white.opacity(0.12)))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help("Screenshot Tool")
                    }

                    Divider()
                        .background(Color.white.opacity(0.1))

                    // Pomodoro Focus Timer
                    VStack(spacing: 4) {
                        HStack {
                            // Mode Switcher
                            Button(action: {
                                let next: PomodoroMode = (productivity.pomodoroMode == .focus) ? .shortBreak : .focus
                                productivity.switchPomodoroMode(next)
                            }) {
                                Text(productivity.pomodoroMode.rawValue)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(productivity.pomodoroMode == .focus ? Color.orange : Color.green)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        (productivity.pomodoroMode == .focus ? Color.orange : Color.green).opacity(0.18)
                                    )
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(PlainButtonStyle())

                            Spacer()

                            // Timer Digits
                            Text(productivity.formattedPomodoroTime)
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .foregroundStyle(.white)
                        }

                        // Progress Bar & Controls
                        HStack(spacing: 8) {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.white.opacity(0.12))
                                        .frame(height: 4)
                                    Capsule()
                                        .fill(productivity.pomodoroMode == .focus ? Color.orange : Color.green)
                                        .frame(width: max(2, geo.size.width * CGFloat(productivity.pomodoroProgress)), height: 4)
                                }
                            }
                            .frame(height: 4)

                            // Play / Pause Button
                            Button(action: {
                                productivity.togglePomodoro()
                            }) {
                                Image(systemName: productivity.isPomodoroRunning ? "pause.fill" : "play.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white)
                                    .frame(width: 22, height: 22)
                                    .background(Circle().fill(Color.white.opacity(0.18)))
                            }
                            .buttonStyle(PlainButtonStyle())

                            // Reset Button
                            Button(action: {
                                productivity.resetPomodoro()
                            }) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 9))
                                    .foregroundColor(.white.opacity(0.6))
                                    .frame(width: 20, height: 20)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)

            // MARK: - Column 2: Clipboard History
            ToolCard(
                title: "Clipboard",
                icon: "doc.on.clipboard.fill",
                accentColor: .cyan,
                actionIcon: "trash",
                action: { productivity.clearClipboardHistory() }
            ) {
                if productivity.clipboardHistory.isEmpty {
                    VStack(spacing: 4) {
                        Image(systemName: "clipboard")
                            .font(.system(size: 20))
                            .foregroundStyle(.white.opacity(0.3))
                        Text("Copy teks apa saja (Cmd+C)")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 4) {
                            ForEach(productivity.clipboardHistory) { item in
                                Button(action: {
                                    productivity.copyToClipboard(item)
                                }) {
                                    HStack(spacing: 6) {
                                        if productivity.lastCopiedId == item.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 10))
                                                .foregroundStyle(.green)
                                        } else {
                                            Image(systemName: "doc.text")
                                                .font(.system(size: 9))
                                                .foregroundStyle(.white.opacity(0.4))
                                        }

                                        Text(item.text)
                                            .font(.system(size: 11, design: .rounded))
                                            .foregroundStyle(productivity.lastCopiedId == item.id ? Color.green : Color.white.opacity(0.85))
                                            .lineLimit(1)
                                            .truncationMode(.tail)

                                        Spacer()
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 5)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(productivity.lastCopiedId == item.id ? Color.green.opacity(0.15) : Color.white.opacity(0.06))
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .frame(maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Reusable Tool Card Frame
private struct ToolCard<Content: View, HeaderActions: View>: View {
    let title: String
    let icon: String
    let accentColor: Color
    var actionIcon: String? = nil
    var action: (() -> Void)? = nil
    @ViewBuilder var headerActions: () -> HeaderActions
    @ViewBuilder let content: Content

    init(
        title: String,
        icon: String,
        accentColor: Color,
        actionIcon: String? = nil,
        action: (() -> Void)? = nil,
        @ViewBuilder headerActions: @escaping () -> HeaderActions = { EmptyView() },
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.accentColor = accentColor
        self.actionIcon = actionIcon
        self.action = action
        self.headerActions = headerActions
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Card Header
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(accentColor)
                    Text(title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                }

                Spacer()

                headerActions()

                if let actionIcon = actionIcon, let action = action {
                    Button(action: action) {
                        Image(systemName: actionIcon)
                            .font(.system(size: 9))
                            .foregroundStyle(.white.opacity(0.5))
                            .frame(width: 18, height: 18)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            // Card Content Area
            content
                .frame(maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(10)
        .frame(height: 125)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(nsColor: .windowBackgroundColor).opacity(0.35))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}
