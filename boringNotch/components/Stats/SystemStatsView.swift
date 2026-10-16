//
//  SystemStatsView.swift
//  boringNotch
//

import SwiftUI

struct SystemStatsView: View {
    @ObservedObject var stats = SystemStatsManager.shared

    var body: some View {
        HStack(spacing: 12) {
            // MARK: - CPU Card
            StatCardView(
                title: "CPU Load",
                icon: "cpu",
                badge: "\(stats.coreCount) Cores",
                accentColor: cpuColor
            ) {
                HStack(spacing: 14) {
                    CircularProgressGauge(
                        percentage: stats.cpuUsage,
                        color: cpuColor,
                        centerText: "\(Int(stats.cpuUsage))%"
                    )
                    .frame(width: 62, height: 62)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Circle().fill(cpuColor).frame(width: 6, height: 6)
                            Text(String(format: "User: %.1f%%", stats.userCpuUsage))
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.85))
                        }
                        HStack(spacing: 4) {
                            Circle().fill(Color.orange.opacity(0.8)).frame(width: 6, height: 6)
                            Text(String(format: "System: %.1f%%", stats.systemCpuUsage))
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        HStack(spacing: 4) {
                            Circle().fill(Color.gray.opacity(0.5)).frame(width: 6, height: 6)
                            Text(String(format: "Idle: %.1f%%", max(0, 100.0 - stats.cpuUsage)))
                                .font(.system(size: 11, weight: .regular, design: .rounded))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)

            // MARK: - Memory (RAM) Card
            StatCardView(
                title: "Memory (RAM)",
                icon: "memorychip",
                badge: "\(Int(Double(stats.memoryTotalBytes) / (1024 * 1024 * 1024))) GB Total",
                accentColor: memoryColor
            ) {
                HStack(spacing: 14) {
                    CircularProgressGauge(
                        percentage: stats.memoryUsedPercentage,
                        color: memoryColor,
                        centerText: "\(Int(stats.memoryUsedPercentage))%"
                    )
                    .frame(width: 62, height: 62)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(stats.formattedMemoryString)
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.white)

                        Text("Used / Total")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))

                        // Mini progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.12))
                                    .frame(height: 5)
                                Capsule()
                                    .fill(memoryColor)
                                    .frame(width: max(4, geo.size.width * CGFloat(stats.memoryUsedPercentage / 100.0)), height: 5)
                            }
                        }
                        .frame(height: 5)
                    }
                }
            }
            .frame(maxWidth: .infinity)

            // MARK: - Hardware & System Info Card
            StatCardView(
                title: "Mac Hardware",
                icon: "laptopcomputer",
                badge: "macOS",
                accentColor: .blue
            ) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.7))
                        Text(stats.chipName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "cpu")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.6))
                        Text("\(stats.coreCount) Active Cores")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.75))
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 11))
                            .foregroundStyle(.cyan.opacity(0.8))
                        Text("Uptime: \(stats.uptimeString.isEmpty ? "Active" : stats.uptimeString)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.75))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 4)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .onAppear {
            stats.startMonitoring()
        }
    }

    private var cpuColor: Color {
        if stats.cpuUsage < 50 {
            return .cyan
        } else if stats.cpuUsage < 80 {
            return .yellow
        } else {
            return .red
        }
    }

    private var memoryColor: Color {
        if stats.memoryUsedPercentage < 70 {
            return .purple
        } else if stats.memoryUsedPercentage < 85 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Reusable Modern Stat Card
private struct StatCardView<Content: View>: View {
    let title: String
    let icon: String
    let badge: String
    let accentColor: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Card Header
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(accentColor)
                    Text(title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                }
                Spacer()
                Text(badge)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(accentColor.opacity(0.18))
                    .clipShape(Capsule())
            }

            // Card Content
            content
                .frame(maxHeight: .infinity, alignment: .center)
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

// MARK: - Circular Progress Gauge
private struct CircularProgressGauge: View {
    let percentage: Double
    let color: Color
    let centerText: String

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 6)

            Circle()
                .trim(from: 0.0, to: CGFloat(min(1.0, max(0.0, percentage / 100.0))))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [color.opacity(0.6), color]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.45, dampingFraction: 0.8), value: percentage)

            Text(centerText)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
    }
}


