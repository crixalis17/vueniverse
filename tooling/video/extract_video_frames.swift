import AVFoundation
import AppKit
import Foundation

guard CommandLine.arguments.count == 3 else {
  fputs("usage: extract_video_frames.swift INPUT_VIDEO OUTPUT_DIRECTORY\n", stderr)
  exit(2)
}

let inputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
try FileManager.default.createDirectory(
  at: outputURL,
  withIntermediateDirectories: true
)

let asset = AVURLAsset(url: inputURL)
let generator = AVAssetImageGenerator(asset: asset)
generator.appliesPreferredTrackTransform = true
generator.requestedTimeToleranceBefore = .zero
generator.requestedTimeToleranceAfter = .zero

let durationSeconds = CMTimeGetSeconds(asset.duration)
for second in [
  2, 5, 10, 15, 16, 17, 18, 19, 20, 25, 30, 35, 40, 44, 45, 46,
  48, 50, 52, 54, 56, 60, 65, 67, 70, 75, 80, 85, 90, 95, 100, 105,
  110, 114,
] {
  guard Double(second) < durationSeconds else { continue }
  let image = try generator.copyCGImage(
    at: CMTime(seconds: Double(second), preferredTimescale: 600),
    actualTime: nil
  )
  let representation = NSBitmapImageRep(cgImage: image)
  guard let png = representation.representation(using: .png, properties: [:])
  else {
    throw NSError(
      domain: "VueniverseVideoQA",
      code: 1,
      userInfo: [NSLocalizedDescriptionKey: "Could not encode frame at \(second)s"]
    )
  }
  try png.write(to: outputURL.appendingPathComponent("frame-\(second)s.png"))
}
