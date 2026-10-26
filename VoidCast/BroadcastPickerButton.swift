import Foundation
import ReplayKit
import SwiftUI

/// Apple's system-owned control for starting a ReplayKit broadcast.
///
/// The system requires a deliberate tap and confirmation from the user. There is
/// intentionally no attempt to find the private UIButton or trigger it in code.
struct BroadcastPickerButton: UIViewRepresentable {
    private static let fallbackExtensionBundleIdentifier = "com.chujiamo.VoidCast.Sink"

    /// Resolve the identifier from the embedded extension at runtime. This keeps
    /// the picker working when a re-signing tool rewrites both bundle IDs.
    static var extensionBundleIdentifier: String {
        guard let plugInsURL = Bundle.main.builtInPlugInsURL,
              let extensionBundle = Bundle(
                  url: plugInsURL.appendingPathComponent("VoidCastSink.appex")
              ),
              let bundleIdentifier = extensionBundle.bundleIdentifier else {
            return fallbackExtensionBundleIdentifier
        }
        return bundleIdentifier
    }

    func makeUIView(context: Context) -> RPSystemBroadcastPickerView {
        let picker = RPSystemBroadcastPickerView(frame: .zero)
        picker.preferredExtension = Self.extensionBundleIdentifier
        picker.showsMicrophoneButton = false
        picker.tintColor = .white
        picker.backgroundColor = .clear
        return picker
    }

    func updateUIView(_ picker: RPSystemBroadcastPickerView, context: Context) {
        picker.preferredExtension = Self.extensionBundleIdentifier
        picker.showsMicrophoneButton = false
    }
}
