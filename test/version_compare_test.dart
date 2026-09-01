import 'package:flutter_test/flutter_test.dart';

import 'package:pulse/core/update/version_compare.dart';

void main() {
  group('isVersionNewer', () {
    test('a higher patch version is newer', () {
      expect(isVersionNewer(current: '1.0.0', latest: '1.0.1'), isTrue);
    });

    test('an equal version is not newer', () {
      expect(isVersionNewer(current: '1.0.0', latest: '1.0.0'), isFalse);
    });

    test('a lower version is not newer', () {
      expect(isVersionNewer(current: '1.1.0', latest: '1.0.9'), isFalse);
    });

    test('tolerates a leading "v" on the latest tag', () {
      expect(isVersionNewer(current: '1.0.0', latest: 'v1.1.0'), isTrue);
    });

    test('ignores a "+build" suffix on the current version', () {
      expect(isVersionNewer(current: '1.0.0+3', latest: '1.0.0'), isFalse);
      expect(isVersionNewer(current: '1.0.0+3', latest: '1.0.1'), isTrue);
    });

    test('a higher major version wins regardless of minor/patch', () {
      expect(isVersionNewer(current: '1.9.9', latest: '2.0.0'), isTrue);
    });

    test('missing trailing components are treated as zero', () {
      expect(isVersionNewer(current: '1.0', latest: '1.0.1'), isTrue);
      expect(isVersionNewer(current: '1.0.0', latest: '1.0'), isFalse);
    });
  });
}
