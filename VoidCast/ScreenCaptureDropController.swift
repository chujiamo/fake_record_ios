import Combine
import CoreMedia
import Foundation
#if !targetEnvironment(simulator)
import ScreenCaptureKit
#endif

#if targetEnvironment(simulator)
/// Simulator-only facade: system-wide ScreenCaptureKit capture requires a device.
@available(iOS 27.0, *)
final class ScreenCaptureDropController: ObservableObject {
    enum Status: Equatable {
        case idle
        case selecting
        case starting
        case active
        case stopping
        case stopFailed(String)
        case failed(String)

        var isBusy: Bool {
            switch self {
            case .starting, .stopping:
                return true
            case .idle, .selecting, .active, .stopFailed, .failed:
                return false
            }
        }
    }

    @Published private(set) var status: Status = .idle

    func presentPicker() {
        status = .failed("系统屏幕捕获只能在真机上测试")
    }

    func stopCapture() {
        status = .idle
    }
}
#else

/// iOS 27's ScreenCaptureKit replacement for ReplayKit broadcast extensions.
///
/// The controller asks the system picker for a full-display filter, attaches
/// transient sample outputs, and intentionally does nothing with every sample.
/// No recording, clip-buffering, file, Photos, or network output is created.
@available(iOS 27.0, *)
final class ScreenCaptureDropController: NSObject, ObservableObject {
    enum Status: Equatable {
        case idle
        case selecting
        case starting
        case active
        case stopping
        case stopFailed(String)
        case failed(String)

        var isBusy: Bool {
            switch self {
            case .starting, .stopping:
                return true
            case .idle, .selecting, .active, .stopFailed, .failed:
                return false
            }
        }
    }

    @Published private(set) var status: Status = .idle

    private let picker = SCContentSharingPicker.shared
    private let sampleQueue = DispatchQueue(
        label: "com.chujiamo.VoidCast.drop-samples",
        qos: .userInitiated,
        autoreleaseFrequency: .workItem
    )
    private var currentStream: SCStream?
    private var isObservingPicker = false

    override init() {
        super.init()
        updatePickerConfiguration()
    }

    deinit {
        deactivatePicker()
    }

    func presentPicker() {
        guard picker.isAvailable else {
            deactivatePicker()
            status = .failed("此设备当前不允许屏幕捕获")
            return
        }

        updatePickerConfiguration()
        activatePicker()
        status = .selecting
        picker.present()
    }

    func stopCapture() {
        guard let stream = currentStream else {
            deactivatePicker()
            status = .idle
            return
        }

        status = .stopping
        stream.stopCapture { [weak self] error in
            DispatchQueue.main.async {
                guard let self, self.currentStream === stream else { return }
                if let error, !Self.isExpectedStop(error) {
                    // Keep the reference: capture may still be active, so the
                    // user must retain a working "retry stop" action.
                    self.status = .stopFailed(Self.userFacingMessage(for: error))
                } else {
                    self.currentStream = nil
                    self.deactivatePicker()
                    self.status = .idle
                }
            }
        }
    }

    private func updatePickerConfiguration() {
        var configuration = SCContentSharingPickerConfiguration()
        configuration.showsMicrophoneControl = false
        configuration.showsCameraControl = false
        picker.defaultConfiguration = configuration
    }

    private func activatePicker() {
        if !isObservingPicker {
            picker.add(self)
            isObservingPicker = true
        }
        picker.isActive = true
    }

    private func deactivatePicker() {
        picker.isActive = false
        if isObservingPicker {
            picker.remove(self)
            isObservingPicker = false
        }
    }

    private func replaceStream(with filter: SCContentFilter) {
        guard let existing = currentStream else {
            startStream(with: filter)
            return
        }

        status = .stopping
        existing.stopCapture { [weak self] error in
            DispatchQueue.main.async {
                guard let self, self.currentStream === existing else { return }
                if let error, !Self.isExpectedStop(error) {
                    self.status = .stopFailed(Self.userFacingMessage(for: error))
                    return
                }
                self.currentStream = nil
                self.startStream(with: filter)
            }
        }
    }

    private func startStream(with filter: SCContentFilter) {
        let configuration = SCStreamConfiguration()
        configuration.capturesAudio = true

        let stream = SCStream(
            filter: filter,
            configuration: configuration,
            delegate: self
        )

        do {
            try stream.addStreamOutput(
                self,
                type: .screen,
                sampleHandlerQueue: sampleQueue
            )
            try stream.addStreamOutput(
                self,
                type: .audio,
                sampleHandlerQueue: sampleQueue
            )
        } catch {
            deactivatePicker()
            status = .failed(Self.userFacingMessage(for: error))
            return
        }

        currentStream = stream
        status = .starting
        stream.startCapture { [weak self] error in
            DispatchQueue.main.async {
                guard let self, self.currentStream === stream else { return }
                if let error {
                    self.currentStream = nil
                    self.deactivatePicker()
                    self.status = .failed(Self.userFacingMessage(for: error))
                } else {
                    self.status = .active
                }
            }
        }
    }

    private static func isExpectedStop(_ error: Error) -> Bool {
        let nsError = error as NSError
        guard nsError.domain == SCStreamErrorDomain,
              let code = SCStreamError.Code(rawValue: nsError.code) else {
            return false
        }
        return code == .userStopped || code == .systemStoppedStream
    }

    private static func userFacingMessage(for error: Error) -> String {
        let nsError = error as NSError
        guard nsError.domain == SCStreamErrorDomain,
              let code = SCStreamError.Code(rawValue: nsError.code) else {
            return error.localizedDescription
        }

        switch code {
        case .userDeclined:
            return "你没有允许屏幕捕获"
        case .missingEntitlements:
            return "签名缺少屏幕捕获权限"
        case .missingBackgroundMode:
            return "签名后的 App 缺少屏幕捕获后台模式"
        case .notSupported:
            return "当前设备或所选内容不支持屏幕捕获"
        case .failedToStart, .failedToStartAudioCapture:
            return "系统未能启动屏幕或音频捕获"
        case .userStopped, .systemStoppedStream:
            return "捕获已经停止"
        default:
            return "系统屏幕捕获出错（代码 \(nsError.code)）"
        }
    }
}

@available(iOS 27.0, *)
extension ScreenCaptureDropController: SCContentSharingPickerObserver {
    func contentSharingPicker(
        _ picker: SCContentSharingPicker,
        didCancelFor stream: SCStream?
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self, self.status == .selecting else { return }
            self.deactivatePicker()
            self.status = .idle
        }
    }

    func contentSharingPicker(
        _ picker: SCContentSharingPicker,
        didUpdateWith filter: SCContentFilter,
        for stream: SCStream?
    ) {
        DispatchQueue.main.async { [weak self] in
            self?.replaceStream(with: filter)
        }
    }

    func contentSharingPickerStartDidFailWithError(_ error: Error) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.deactivatePicker()
            self.status = .failed(Self.userFacingMessage(for: error))
        }
    }
}

@available(iOS 27.0, *)
extension ScreenCaptureDropController: SCStreamOutput {
    func stream(
        _ stream: SCStream,
        didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
        of outputType: SCStreamOutputType
    ) {
        // Deliberately drop screen, system-audio, and any future sample types.
        return
    }
}

@available(iOS 27.0, *)
extension ScreenCaptureDropController: SCStreamDelegate {
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            guard let self, self.currentStream === stream else { return }
            self.currentStream = nil
            self.deactivatePicker()
            if Self.isExpectedStop(error) {
                self.status = .idle
            } else {
                self.status = .failed(Self.userFacingMessage(for: error))
            }
        }
    }
}
#endif
