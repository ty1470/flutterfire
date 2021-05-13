// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_functions_platform_interface/cloud_functions_platform_interface.dart';
import 'package:cloud_functions_platform_interface/src/method_channel/method_channel_firebase_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:meta/meta.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// The interface that implementations of `cloud_functions` must extend.
///
/// Platform implementations should extend this class rather than implement it
/// as `cloud_functions` does not consider newly added methods to be breaking
/// changes. Extending this class (using `extends`) ensures that the subclass
/// will get the default implementation, while platform implementations that
/// `implements` this interface will be broken by newly added
/// [FirebaseFunctionsPlatform] methods.
abstract class FirebaseFunctionsPlatform extends PlatformInterface {
  static final Object _token = Object();

  /// Create an instance using [app] and [region]
  FirebaseFunctionsPlatform(this.app, this.region) : super(token: _token);

  static FirebaseFunctionsPlatform _instance;

  /// The [FirebaseApp] this instance was initialized with
  final FirebaseApp app;

  /// The region for the HTTPS trigger, such as "us-central1".
  final String region;

  /// The current default [FirebaseFunctionsPlatform] instance.
  ///
  /// It will always default to [MethodChannelFirebaseFunctions]
  /// if no other implementation was provided.
  static FirebaseFunctionsPlatform get instance {
    if (_instance == null) {
      _instance = MethodChannelFirebaseFunctions.instance;
    }

    return _instance;
  }

  /// Sets the [FirebaseFunctionsPlatform.instance]
  static set instance(FirebaseFunctionsPlatform instance) {
    assert(instance != null);
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Create an instance using [app] using the existing implementation
  factory FirebaseFunctionsPlatform.instanceFor(
      {FirebaseApp app, String region}) {
    return FirebaseFunctionsPlatform.instance
        .delegateFor(app: app, region: region);
  }

  /// Enables delegates to create new instances of themselves if a none default
  /// [FirebaseApp] instance or region is required by the user.
  @protected
  FirebaseFunctionsPlatform delegateFor({FirebaseApp app, String region}) {
    throw UnimplementedError('delegateFor() is not implemented');
  }

  /// Creates a [HttpsCallablePlatform] instance
  HttpsCallablePlatform httpsCallable(
      String origin, String name, HttpsCallableOptions options) {
    throw UnimplementedError('httpsCallable() is not implemented');
  }
}
