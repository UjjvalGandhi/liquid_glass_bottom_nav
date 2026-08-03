import Flutter
import UIKit

final class LiquidGlassIconButtonViewFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    LiquidGlassIconButtonView(
      frame: frame,
      viewIdentifier: viewId,
      arguments: args,
      messenger: messenger
    )
  }
}

/// Hosts a real `UIButton` using the system Liquid Glass button style.
///
/// On iOS 26+, `UIButton.Configuration.glass()` / `.prominentGlass()` is
/// genuine system chrome — the same refractive, capsule-shaped material as
/// the bottom tab bar, rendered by UIKit itself rather than drawn by this
/// plugin. Below iOS 26 there is no glass API to fall back to, so the
/// button uses a plain tinted style instead of faking the look.
private final class LiquidGlassIconButtonView: NSObject, FlutterPlatformView {
  let containerView: UIView
  let button = UIButton()
  let channel: FlutterMethodChannel

  init(
    frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?,
    messenger: FlutterBinaryMessenger
  ) {
    let params = args as? [String: Any] ?? [:]
    containerView = UIView(frame: frame)
    channel = FlutterMethodChannel(
      name: "liquid_glass_icon_button_\(viewId)",
      binaryMessenger: messenger
    )
    super.init()

    containerView.backgroundColor = .clear
    configureButton(params: params)
    embedButton()
  }

  func view() -> UIView {
    containerView
  }

  private func configureButton(params: [String: Any]) {
    let symbolName = params["sfSymbol"] as? String ?? "circle"
    let prominent = params["prominent"] as? Bool ?? false
    let pointSize = (params["pointSize"] as? NSNumber)?.doubleValue ?? 18

    var configuration: UIButton.Configuration
    if #available(iOS 26.0, *) {
      // Real system Liquid Glass material — capsule shape, specular
      // highlight, and refraction are all rendered by UIKit, not us.
      configuration = prominent ? .prominentGlass() : .glass()
    } else {
      // No glass API before iOS 26. A plain tinted capsule is an honest
      // downgrade rather than an approximation of a material that does
      // not exist on this OS version.
      configuration = prominent ? .filled() : .tinted()
    }

    configuration.image = UIImage(
      systemName: symbolName,
      withConfiguration: UIImage.SymbolConfiguration(
        pointSize: pointSize,
        weight: .medium
      )
    )
    configuration.cornerStyle = .capsule
    configuration.baseForegroundColor = .label

    button.configuration = configuration

    let menuItems = params["menuItems"] as? [String] ?? []
    if menuItems.isEmpty {
      button.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    } else {
      // A `UIMenu` anchored to the button, opened as its primary action.
      // On iOS 26 the system presents this in the same Liquid Glass
      // material as the button itself — real menu chrome, not a Flutter
      // popup drawn to look like one.
      let selectedItem = params["selectedMenuItem"] as? String
      button.menu = makeMenu(items: menuItems, selectedItem: selectedItem)
      button.showsMenuAsPrimaryAction = true
    }
  }

  private func makeMenu(items: [String], selectedItem: String?) -> UIMenu {
    let actions = items.map { item in
      UIAction(title: item, state: item == selectedItem ? .on : .off) {
        [weak self] _ in
        self?.channel.invokeMethod("menuItemSelected", arguments: item)
      }
    }
    return UIMenu(children: actions)
  }

  private func embedButton() {
    button.translatesAutoresizingMaskIntoConstraints = false
    containerView.addSubview(button)
    NSLayoutConstraint.activate([
      button.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
      button.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
      button.topAnchor.constraint(equalTo: containerView.topAnchor),
      button.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
    ])
  }

  @objc private func handleTap() {
    channel.invokeMethod("tap", arguments: nil)
  }
}
