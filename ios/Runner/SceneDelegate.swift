import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  private let dropDelegate = TextaraDropDelegate()
  private var didAttachDrop = false

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    for context in connectionOptions.urlContexts {
      IncomingHub.shared.ingest(url: context.url)
    }
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    attachDropIfNeeded()
  }

  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    for context in URLContexts {
      IncomingHub.shared.ingest(url: context.url)
    }
    super.scene(scene, openURLContexts: URLContexts)
  }

  override func sceneDidBecomeActive(_ scene: UIScene) {
    super.sceneDidBecomeActive(scene)
    attachDropIfNeeded()
  }

  private func attachDropIfNeeded() {
    guard !didAttachDrop, let view = window?.rootViewController?.view else { return }
    didAttachDrop = true
    view.addInteraction(UIDropInteraction(delegate: dropDelegate))
  }
}

/// Accepts EPUB and PDF drops onto the running iPad or iPhone window.
final class TextaraDropDelegate: NSObject, UIDropInteractionDelegate {
  private let typeIdentifiers = [
    "org.idpf.epub-container",
    "com.apple.ibooks.epub",
    "com.adobe.pdf",
    "public.pdf",
  ]

  func dropInteraction(
    _ interaction: UIDropInteraction,
    canHandle session: UIDropSession
  ) -> Bool {
    session.hasItemsConforming(toTypeIdentifiers: typeIdentifiers)
  }

  func dropInteraction(
    _ interaction: UIDropInteraction,
    sessionDidUpdate session: UIDropSession
  ) -> UIDropProposal {
    UIDropProposal(operation: .copy)
  }

  func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
    for item in session.items {
      let provider = item.itemProvider
      let type = typeIdentifiers.first { provider.hasItemConformingToTypeIdentifier($0) }
      guard let type else { continue }
      provider.loadFileRepresentation(forTypeIdentifier: type) { url, _ in
        guard let url else { return }
        IncomingHub.shared.ingest(url: url)
      }
    }
  }
}
