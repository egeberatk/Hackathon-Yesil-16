import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// No pending Android camera recovery when a test returns to a fresh home.
void mockPhotoPlatform() {
  const channel = MethodChannel('plugins.flutter.io/image_picker');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (_) async => null);
  addTearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
}

/// Keep catalog loading deterministic when a fresh home is built mid-test.
class HomeTestAssets extends CachingAssetBundle {
  HomeTestAssets(this.catalog);
  final String catalog;
  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      SynchronousFuture(
        key == 'assets/recipe_photos/manifest.json'
            ? '{"version":1,"photos":{}}'
            : catalog,
      );
  @override
  Future<ByteData> load(String key) => rootBundle.load(key);
}
