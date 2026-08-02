import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Real app version/build number, read from the platform's own package
/// metadata at runtime — never hand-typed, so it can't silently drift
/// from what's actually declared in `pubspec.yaml`/the built binary.
final packageInfoProvider = FutureProvider<PackageInfo>((ref) {
  return PackageInfo.fromPlatform();
});
