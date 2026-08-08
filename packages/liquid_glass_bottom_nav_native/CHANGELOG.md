## 0.2.1

* Fix demo GIF not rendering on pub.dev by using an absolute GitHub raw URL
  in the README instead of a relative path.

## 0.2.0

* Add `trailingButtonSymbol`, `trailingButtonTitle` and
  `onTrailingButtonTapped` to `LiquidGlassBottomNav`. Repurposes the search
  tab's separated-circle Liquid Glass treatment as a plain action button
  when a symbol is set. Mutually exclusive with `showSearchTab`.

## 0.1.0

* Initial release.
* `LiquidGlassBottomNav` hosts a real `UITabBarController` in a platform view,
  so iOS renders the bar itself: Liquid Glass on iOS 26+, the classic flat tab
  bar on iOS 16–25.
* Optional system search tab that morphs into the native search field, with
  `onSearchActivated`, `onSearchDismissed` and `onSearchChanged` callbacks.
* Tab icons keep the SF Symbol variant you name. Tab bars otherwise substitute
  the `.fill` variant automatically, which turned `play.rectangle` into the
  much heavier `play.rectangle.fill`.
* Renders `fallback` on non-iOS platforms.
