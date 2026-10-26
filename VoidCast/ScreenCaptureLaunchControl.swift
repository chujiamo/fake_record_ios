import SwiftUI
import UIKit

@available(iOS 27.0, *)
struct ScreenCaptureLaunchControl: View {
    @StateObject private var controller = ScreenCaptureDropController()

    private let cyan = Color(red: 0.25, green: 0.93, blue: 0.86)

    var body: some View {
        VStack(spacing: 12) {
            Button(action: primaryAction) {
                HStack(spacing: 12) {
                    Image(systemName: buttonIcon)
                        .font(.title3.weight(.semibold))
                    Text(buttonTitle)
                        .font(.headline)
                    Spacer()
                    if controller.status.isBusy {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                    }
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .frame(maxWidth: .infinity, minHeight: 58)
                .background(buttonColor, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(controller.status.isBusy)
            .accessibilityHint(buttonHint)

            HStack(spacing: 8) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(statusText)
        }
        .onChange(of: controller.status) { _, newStatus in
            announceIfNeeded(newStatus)
        }
    }

    private func primaryAction() {
        if isStopAction {
            controller.stopCapture()
        } else {
            controller.presentPicker()
        }
    }

    private var buttonTitle: String {
        switch controller.status {
        case .active:
            return "停止丢弃型捕获"
        case .selecting:
            return "重新打开系统选择器"
        case .starting:
            return "正在启动"
        case .stopping:
            return "正在停止"
        case .stopFailed:
            return "重试停止捕获"
        case .idle, .failed:
            return "打开系统屏幕共享选择器"
        }
    }

    private var buttonIcon: String {
        isStopAction ? "stop.fill" : "rectangle.inset.filled.and.person.filled"
    }

    private var buttonColor: Color {
        isStopAction ? .red.opacity(0.78) : cyan.opacity(0.36)
    }

    private var buttonHint: String {
        isStopAction
            ? "停止系统屏幕捕获并继续丢弃最后到达的采样"
            : "由系统请求选择整个屏幕，随后本软件立即丢弃所有采样"
    }

    private var statusColor: Color {
        switch controller.status {
        case .active:
            return cyan
        case .stopFailed, .failed:
            return .red
        case .selecting, .starting, .stopping:
            return .yellow
        case .idle:
            return .secondary
        }
    }

    private var statusText: String {
        switch controller.status {
        case .idle:
            return "未运行 · 由系统面板确认后才会开始"
        case .selecting:
            return "等待你在系统面板中选择捕获内容"
        case .starting:
            return "系统正在启动捕获流"
        case .active:
            return "正在捕获并立即丢弃采样"
        case .stopping:
            return "正在结束捕获流"
        case .stopFailed(let message):
            return "停止失败，捕获可能仍在运行：\(message)"
        case .failed(let message):
            return "未能启动：\(message)"
        }
    }

    private var isStopAction: Bool {
        switch controller.status {
        case .active, .stopFailed:
            return true
        default:
            return false
        }
    }

    private func announceIfNeeded(_ status: ScreenCaptureDropController.Status) {
        switch status {
        case .active, .stopFailed, .failed:
            UIAccessibility.post(notification: .announcement, argument: statusText)
        default:
            break
        }
    }
}
