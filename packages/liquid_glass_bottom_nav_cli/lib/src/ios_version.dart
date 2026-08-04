/// Lowest iOS version `liquid_glass_bottom_nav_native` builds against.
const minimumDeploymentTarget = IosVersion(16, 0);

/// Lowest iOS version that renders the Liquid Glass treatment.
///
/// Below this the plugin still works — every iOS 26 API is behind an
/// `#available` guard — but the bar falls back to the classic flat tab bar,
/// which is a silent downgrade worth warning about.
const liquidGlassDeploymentTarget = IosVersion(26, 0);

/// A `major.minor` iOS version, as written in Xcode build settings.
class IosVersion implements Comparable<IosVersion> {
  const IosVersion(this.major, this.minor);

  final int major;
  final int minor;

  /// Parses leading `major[.minor]` digits, ignoring any trailing patch
  /// component. Returns null when [value] does not start with a number.
  static IosVersion? tryParse(String value) {
    final match = RegExp(r'^(\d+)(?:\.(\d+))?').firstMatch(value.trim());
    if (match == null) return null;
    return IosVersion(int.parse(match[1]!), int.parse(match[2] ?? '0'));
  }

  @override
  int compareTo(IosVersion other) => major != other.major
      ? major.compareTo(other.major)
      : minor.compareTo(other.minor);

  bool operator <(IosVersion other) => compareTo(other) < 0;
  bool operator >=(IosVersion other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) =>
      other is IosVersion && other.major == major && other.minor == minor;

  @override
  int get hashCode => Object.hash(major, minor);

  @override
  String toString() => '$major.$minor';
}
