#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint liquid_glass_bottom_nav.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'liquid_glass_bottom_nav'
  s.version          = '0.1.0'
  s.summary          = 'Native iOS 26 Liquid Glass bottom tab bar for Flutter.'
  s.description      = <<-DESC
Embeds a real UITabBarController so the bottom navigation renders the
system Liquid Glass tab bar, including the morphing search tab.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'liquid_glass_bottom_nav/Sources/liquid_glass_bottom_nav/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '16.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'liquid_glass_bottom_nav_privacy' => ['liquid_glass_bottom_nav/Sources/liquid_glass_bottom_nav/PrivacyInfo.xcprivacy']}
end
