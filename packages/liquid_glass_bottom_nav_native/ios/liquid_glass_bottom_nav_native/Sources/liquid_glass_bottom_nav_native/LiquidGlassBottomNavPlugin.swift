import Flutter
import UIKit

public class LiquidGlassBottomNavPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    registrar.register(
      LiquidGlassBottomNavViewFactory(messenger: registrar.messenger()),
      withId: "liquid_glass_bottom_nav"
    )
    registrar.register(
      LiquidGlassIconButtonViewFactory(messenger: registrar.messenger()),
      withId: "liquid_glass_icon_button"
    )
  }
}

final class LiquidGlassBottomNavViewFactory: NSObject, FlutterPlatformViewFactory {
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
    if #available(iOS 18.0, *) {
      return ModernBottomNavView(
        frame: frame,
        viewIdentifier: viewId,
        arguments: args,
        messenger: messenger
      )
    } else {
      return LegacyBottomNavView(
        frame: frame,
        viewIdentifier: viewId,
        arguments: args,
        messenger: messenger
      )
    }
  }
}

/// Builds a tab image for an SF Symbol name.
///
/// Tab bars automatically substitute the `.fill` variant of whatever symbol
/// they are given, so `play.rectangle` renders as the much heavier
/// `play.rectangle.fill`. Flattening the symbol into a plain template image
/// leaves nothing for that substitution to act on, so the variant the caller
/// actually asked for survives.
private func tabImage(named name: String) -> UIImage? {
  let configuration = UIImage.SymbolConfiguration(pointSize: 22, weight: .regular)
  guard let symbol = UIImage(systemName: name, withConfiguration: configuration) else {
    return nil
  }
  return UIGraphicsImageRenderer(size: symbol.size)
    .image { _ in symbol.draw(at: .zero) }
    .withRenderingMode(.alwaysTemplate)
}

private final class WindowAwareContainerView: UIView {
  var onDidMoveToWindow: (() -> Void)?

  override func didMoveToWindow() {
    super.didMoveToWindow()
    if window != nil {
      onDidMoveToWindow?()
    }
  }
}

/// Hosts a real `UITabBarController` inside a Flutter platform view.
///
/// On iOS 26 the system renders the genuine Liquid Glass treatment on its
/// own: the floating glass pill with the sliding selection platter, and —
/// when the search tab is enabled — the separated circular glass button
/// that morphs into the system search field, exactly as in Apple's apps.
/// On iOS 18–25 the same `UITab` path renders the classic flat tab bar.
///
/// This base class owns everything both OS paths share: the container
/// view, the method channel, embedding, and the search controller
/// plumbing. Subclasses decide how the tabs themselves are built
/// (`UITab` on iOS 18+, `UITabBarItem` on iOS 16–17).
private class BottomNavHostView: NSObject, FlutterPlatformView,
  UISearchControllerDelegate, UISearchResultsUpdating
{
  let containerView: WindowAwareContainerView
  let tabBarController = UITabBarController()
  let channel: FlutterMethodChannel
  let searchPlaceholder: String
  private var attachedToParent = false

  init(
    frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?,
    messenger: FlutterBinaryMessenger
  ) {
    let params = args as? [String: Any] ?? [:]
    containerView = WindowAwareContainerView(frame: frame)
    channel = FlutterMethodChannel(
      name: "liquid_glass_bottom_nav_\(viewId)",
      binaryMessenger: messenger
    )
    searchPlaceholder = params["searchPlaceholder"] as? String ?? "Search"
    super.init()

    configureTabs(params: params)
    embedTabBarController()

    containerView.onDidMoveToWindow = { [weak self] in
      self?.attachToParentControllerIfNeeded()
    }
  }

  func view() -> UIView {
    containerView
  }

  /// Overridden by subclasses to populate the tab bar controller.
  func configureTabs(params: [String: Any]) {}

  // MARK: - UISearchControllerDelegate / UISearchResultsUpdating

  func didDismissSearchController(_ searchController: UISearchController) {
    channel.invokeMethod("searchDismissed", arguments: nil)
  }

  func updateSearchResults(for searchController: UISearchController) {
    channel.invokeMethod(
      "searchChanged",
      arguments: searchController.searchBar.text ?? ""
    )
  }

  // MARK: - Search host

  func makeSearchController() -> UISearchController {
    let searchController = UISearchController(searchResultsController: nil)
    searchController.delegate = self
    searchController.searchResultsUpdater = self
    searchController.obscuresBackgroundDuringPresentation = false
    searchController.searchBar.placeholder = searchPlaceholder
    return searchController
  }

  func makeSearchHostController(searchController: UISearchController) -> UIViewController {
    let resultsHost = UIViewController()
    resultsHost.view.backgroundColor = .clear
    resultsHost.navigationItem.searchController = searchController
    resultsHost.navigationItem.hidesSearchBarWhenScrolling = false

    if #available(iOS 26.0, *) {
      // Integrated placement powers the circle-to-field morph; older
      // systems fall back to the standard stacked search bar.
      resultsHost.navigationItem.preferredSearchBarPlacement = .integrated
    }

    let navigationController = UINavigationController(rootViewController: resultsHost)
    navigationController.view.backgroundColor = .clear
    return navigationController
  }

  // MARK: - Embedding

  private func embedTabBarController() {
    containerView.backgroundColor = .clear
    containerView.isOpaque = false

    guard let hostedView = tabBarController.view else { return }
    hostedView.backgroundColor = .clear
    hostedView.translatesAutoresizingMaskIntoConstraints = false
    containerView.addSubview(hostedView)

    NSLayoutConstraint.activate([
      hostedView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
      hostedView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
      hostedView.topAnchor.constraint(equalTo: containerView.topAnchor),
      hostedView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
    ])
  }

  private func attachToParentControllerIfNeeded() {
    guard !attachedToParent,
          let parent = containerView.window?.rootViewController
    else { return }

    attachedToParent = true
    parent.addChild(tabBarController)
    tabBarController.didMove(toParent: parent)
  }
}

// MARK: - iOS 18+ (`UITab` / `UISearchTab`)

@available(iOS 18.0, *)
private final class ModernBottomNavView: BottomNavHostView, UITabBarControllerDelegate {
  private var contentTabs: [UITab] = []
  private var lastContentTab: UITab?
  private weak var searchController: UISearchController?

  override func configureTabs(params: [String: Any]) {
    let placeholder: (UITab) -> UIViewController = { _ in
      let controller = UIViewController()
      controller.view.backgroundColor = .clear
      return controller
    }

    let itemMaps = params["items"] as? [[String: Any]] ?? []
    contentTabs = itemMaps.enumerated().map { index, item in
      UITab(
        title: item["title"] as? String ?? "",
        image: tabImage(named: item["sfSymbol"] as? String ?? "circle"),
        identifier: "tab_\(index)",
        viewControllerProvider: placeholder
      )
    }

    guard !contentTabs.isEmpty else { return }

    var tabs = contentTabs
    if params["showSearchTab"] as? Bool ?? true {
      // The search tab hosts a real UISearchController with integrated
      // placement, so tapping the circular button morphs it into the
      // system search field. automaticallyActivatesSearch also restores
      // the previously selected tab when search is cancelled.
      let search = UISearchTab { [weak self] _ in
        guard let self else { return UIViewController() }
        let controller = self.makeSearchController()
        self.searchController = controller
        return self.makeSearchHostController(searchController: controller)
      }
      if #available(iOS 26.0, *) {
        search.automaticallyActivatesSearch = true
      }
      tabs.append(search)
    }

    tabBarController.delegate = self
    tabBarController.tabs = tabs

    let requestedIndex = params["selectedIndex"] as? Int ?? 0
    let initialTab = contentTabs[min(max(requestedIndex, 0), contentTabs.count - 1)]
    tabBarController.selectedTab = initialTab
    lastContentTab = initialTab
  }

  func tabBarController(
    _ tabBarController: UITabBarController,
    didSelectTab selectedTab: UITab,
    previousTab: UITab?
  ) {
    if selectedTab is UISearchTab {
      // The Flutter side grows the platform view to full screen so the
      // expanded search field and keyboard have room to render.
      channel.invokeMethod("searchActivated", arguments: nil)
      if #available(iOS 26.0, *) {
        // automaticallyActivatesSearch opens the field for us.
      } else {
        DispatchQueue.main.async { [weak self] in
          self?.searchController?.isActive = true
        }
      }
      return
    }

    lastContentTab = selectedTab
    if let index = contentTabs.firstIndex(of: selectedTab) {
      channel.invokeMethod("tabSelected", arguments: index)
    }
  }

  override func didDismissSearchController(_ searchController: UISearchController) {
    if #available(iOS 26.0, *) {
      // automaticallyActivatesSearch restores the previous tab itself.
    } else if let lastContentTab {
      tabBarController.selectedTab = lastContentTab
    }
    super.didDismissSearchController(searchController)
  }
}

// MARK: - iOS 16–17 (classic `viewControllers` + `UITabBarItem`)

private final class LegacyBottomNavView: BottomNavHostView, UITabBarControllerDelegate {
  private var contentControllers: [UIViewController] = []
  private var searchHostController: UIViewController?
  private weak var searchController: UISearchController?
  private var lastContentIndex = 0

  override func configureTabs(params: [String: Any]) {
    let itemMaps = params["items"] as? [[String: Any]] ?? []
    contentControllers = itemMaps.enumerated().map { index, item in
      let controller = UIViewController()
      controller.view.backgroundColor = .clear
      controller.tabBarItem = UITabBarItem(
        title: item["title"] as? String ?? "",
        image: tabImage(named: item["sfSymbol"] as? String ?? "circle"),
        tag: index
      )
      return controller
    }

    guard !contentControllers.isEmpty else { return }

    var controllers = contentControllers
    if params["showSearchTab"] as? Bool ?? true {
      let search = makeSearchController()
      searchController = search
      let host = makeSearchHostController(searchController: search)
      host.tabBarItem = UITabBarItem(tabBarSystemItem: .search, tag: controllers.count)
      searchHostController = host
      controllers.append(host)
    }

    tabBarController.delegate = self
    tabBarController.viewControllers = controllers

    let requestedIndex = params["selectedIndex"] as? Int ?? 0
    let initialIndex = min(max(requestedIndex, 0), contentControllers.count - 1)
    tabBarController.selectedIndex = initialIndex
    lastContentIndex = initialIndex
  }

  func tabBarController(
    _ tabBarController: UITabBarController,
    didSelect viewController: UIViewController
  ) {
    if viewController === searchHostController {
      channel.invokeMethod("searchActivated", arguments: nil)
      // No automaticallyActivatesSearch before iOS 18 — open the search
      // field manually once the tab switch has settled.
      DispatchQueue.main.async { [weak self] in
        self?.searchController?.isActive = true
      }
      return
    }

    if let index = contentControllers.firstIndex(where: { $0 === viewController }) {
      lastContentIndex = index
      channel.invokeMethod("tabSelected", arguments: index)
    }
  }

  override func didDismissSearchController(_ searchController: UISearchController) {
    // Mirror iOS 18's automaticallyActivatesSearch behaviour: cancelling
    // search returns to the previously selected content tab.
    tabBarController.selectedIndex = lastContentIndex
    super.didDismissSearchController(searchController)
  }
}
