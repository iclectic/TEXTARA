import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    IncomingHub.shared.attach(messenger: flutterViewController.engine.binaryMessenger)
    registerForDraggedTypes([.fileURL])

    super.awakeFromNib()
  }

  override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
    .copy
  }

  override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
    guard let urls = sender.draggingPasteboard.readObjects(
      forClasses: [NSURL.self],
      options: nil
    ) as? [URL] else {
      return false
    }
    if urls.isEmpty { return false }
    for url in urls {
      IncomingHub.shared.ingest(url: url)
    }
    return true
  }
}
