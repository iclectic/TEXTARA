import Cocoa
import FlutterMacOS

/// Queues files dropped or opened on macOS, and `textara://book/<id>` links.
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
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func application(_ application: NSApplication, open urls: [URL]) {
    for url in urls {
      IncomingHub.shared.ingest(url: url)
    }
    super.application(application, open: urls)
  }
}
