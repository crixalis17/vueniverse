import AVFoundation
import Foundation

guard CommandLine.arguments.count == 4 else {
  fputs(
    "usage: assemble_dynamic_app_take.swift MAIN_VIDEO TAIL_VIDEO OUTPUT_VIDEO\n",
    stderr
  )
  exit(2)
}

let mainAsset = AVURLAsset(url: URL(fileURLWithPath: CommandLine.arguments[1]))
let tailAsset = AVURLAsset(url: URL(fileURLWithPath: CommandLine.arguments[2]))
let outputURL = URL(fileURLWithPath: CommandLine.arguments[3])

try? FileManager.default.removeItem(at: outputURL)

let composition = AVMutableComposition()
guard
  let compositionTrack = composition.addMutableTrack(
    withMediaType: .video,
    preferredTrackID: kCMPersistentTrackID_Invalid
  ),
  let mainTrack = mainAsset.tracks(withMediaType: .video).first,
  let tailTrack = tailAsset.tracks(withMediaType: .video).first
else {
  fputs("Both inputs must contain video tracks.\n", stderr)
  exit(3)
}

compositionTrack.preferredTransform = mainTrack.preferredTransform
let scale: CMTimeScale = 600
let mainDuration = CMTime(seconds: 45, preferredTimescale: scale)
let tailStart = CMTime(seconds: 15, preferredTimescale: scale)
let tailDuration = CMTime(seconds: 13, preferredTimescale: scale)

try compositionTrack.insertTimeRange(
  CMTimeRange(start: .zero, duration: mainDuration),
  of: mainTrack,
  at: .zero
)
try compositionTrack.insertTimeRange(
  CMTimeRange(start: tailStart, duration: tailDuration),
  of: tailTrack,
  at: mainDuration
)

guard let exporter = AVAssetExportSession(
  asset: composition,
  presetName: AVAssetExportPresetHighestQuality
) else {
  fputs("Could not create the video exporter.\n", stderr)
  exit(4)
}

exporter.outputURL = outputURL
exporter.outputFileType = .mp4
exporter.shouldOptimizeForNetworkUse = true

let semaphore = DispatchSemaphore(value: 0)
exporter.exportAsynchronously { semaphore.signal() }
semaphore.wait()

guard exporter.status == .completed else {
  fputs("Export failed: \(String(describing: exporter.error))\n", stderr)
  exit(5)
}

print(outputURL.path)
