import Flutter
import UIKit

/// Queues files and `textara://book/<id>` links until Flutter drains them.
final class IncomingHub: NSObject {
  static let shared = IncomingHub()
  static let channelName = "com.textara.textara/incoming"

  private var pending: [[String: String]] = []
  private var channel: FlutterMethodChannel?

  func attach(messenger: FlutterBinaryMessenger) {
    let methodChannel = FlutterMethodChannel(
      name: IncomingHub.channelName,
      binaryMessenger: messenger
    )
    methodChannel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(nil)
        return
      }
      if call.method == "takePending" {
        let copy = self.pending
        self.pending.removeAll()
        result(copy)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    channel = methodChannel
    nudge()
  }

  func ingest(url: URL) {
    if url.scheme == "textara", url.host == "book" {
      let id = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        .split(separator: "/")
        .first
        .map(String.init) ?? ""
      if !id.isEmpty {
        enqueue(type: "book", value: id)
      }
      return
    }
    guard url.isFileURL else { return }
    let ext = url.pathExtension.lowercased()
    guard ext == "epub" || ext == "pdf" else { return }

    let accessing = url.startAccessingSecurityScopedResource()
    defer {
      if accessing {
        url.stopAccessingSecurityScopedResource()
      }
    }
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent("incoming", isDirectory: true)
    try? FileManager.default.createDirectory(
      at: directory,
      withIntermediateDirectories: true
    )
    let dest = directory.appendingPathComponent("\(UUID().uuidString)_\(url.lastPathComponent)")
    do {
      if FileManager.default.fileExists(atPath: dest.path) {
        try FileManager.default.removeItem(at: dest)
      }
      try FileManager.default.copyItem(at: url, to: dest)
      enqueue(type: "file", value: dest.path)
    } catch {
      // The importer never sees a file we could not copy.
    }
  }

  private func enqueue(type: String, value: String) {
    let item = ["type": type, "value": value]
    if Thread.isMainThread {
      pending.append(item)
      nudge()
    } else {
      DispatchQueue.main.async { [weak self] in
        self?.pending.append(item)
        self?.nudge()
      }
    }
  }

  private func nudge() {
    channel?.invokeMethod("incomingAvailable", arguments: nil)
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    IncomingHub.shared.attach(messenger: engineBridge.applicationRegistrar.messenger())
  }
}
