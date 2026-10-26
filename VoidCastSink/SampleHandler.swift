import CoreMedia
import ReplayKit

/// ReplayKit delivers each transient screen/audio sample here.
///
/// Every callback deliberately returns without retaining, encoding, writing, or
/// transmitting the sample. Once the callback returns, this extension keeps no
/// reference to the buffer.
final class SampleHandler: RPBroadcastSampleHandler {
    override func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
        // No session, writer, connection, or destination is created.
    }

    override func broadcastPaused() {
        // Nothing is buffered, so there is nothing to pause or flush.
    }

    override func broadcastResumed() {
        // Nothing is buffered, so there is nothing to resume.
    }

    override func broadcastFinished() {
        // Nothing was retained and no cleanup of media is required.
    }

    override func processSampleBuffer(
        _ sampleBuffer: CMSampleBuffer,
        with sampleBufferType: RPSampleBufferType
    ) {
        switch sampleBufferType {
        case .video, .audioApp, .audioMic:
            return
        @unknown default:
            return
        }
    }
}
