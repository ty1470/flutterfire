// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage_platform_interface/firebase_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../mock.dart';

void main() {
  setupFirebaseStorageMocks();

  /*late*/ FirebaseStoragePlatform firebaseStoragePlatform;
  /*late*/ FirebaseApp app;
  /*late*/ TestListResultPlatform listResultPlatform;

  group('$ListResultPlatform()', () {
    setUpAll(() async {
      app = await Firebase.initializeApp();
      firebaseStoragePlatform = TestFirebaseStoragePlatform(app);
      listResultPlatform =
          TestListResultPlatform(firebaseStoragePlatform, 'foo');
    });

    test('Constructor', () {
      expect(listResultPlatform, isA<ListResultPlatform>());
      expect(listResultPlatform, isA<PlatformInterface>());
    });

    group('verifyExtends()', () {
      test('calls successfully', () {
        try {
          ListResultPlatform.verifyExtends(listResultPlatform);
          return;
        } catch (_) {
          fail('thrown an unexpected exception');
        }
      });

      test('throws an [AssertionError] exception when instance is null', () {
        expect(
            () => ListResultPlatform.verifyExtends(null), throwsAssertionError);
      });
    });

    test('throws if get.items', () async {
      try {
        await listResultPlatform.items;
      } on UnimplementedError catch (e) {
        expect(e.message, equals('items is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if get.prefixes', () async {
      try {
        await listResultPlatform.prefixes;
      } on UnimplementedError catch (e) {
        expect(e.message, equals('prefixes is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });
  });
}

class TestListResultPlatform extends ListResultPlatform {
  TestListResultPlatform(storage, nextPageToken)
      : super(storage, nextPageToken);
}

class TestFirebaseStoragePlatform extends FirebaseStoragePlatform {
  TestFirebaseStoragePlatform(FirebaseApp app) : super(appInstance: app);
}
