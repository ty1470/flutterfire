// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:async/async.dart';

import 'package:firebase_storage_platform_interface/firebase_storage_platform_interface.dart';
import 'package:firebase_storage_web/src/utils/errors.dart';

import 'interop/storage.dart' as storage_interop;
import 'utils/task.dart';

/// The web platform implementation of an (Upload)Task.
/// This class wraps a proper [storage_interop.UploadTask] and exposes bindings
/// to its functionality: Stream of changes, a Future notifying of
/// success/errors, and pause/resume/cancel methods.
class TaskWeb extends TaskPlatform {
  final ReferencePlatform _reference;

  final storage_interop.UploadTask _task;

  Future<TaskSnapshotPlatform> _onComplete;
  Stream<TaskSnapshotPlatform> _snapshotEvents;

  /// Creates a Task for web from a [ReferencePlatform] object and a native [storage_interop.UploadTask].
  /// The `reference` is used when creating [TaskSnapshotWeb] of this task.
  TaskWeb(ReferencePlatform reference, storage_interop.UploadTask task)
      : _reference = reference,
        _task = task,
        super();

  /// Returns a [Stream] of [TaskSnapshot] events.
  ///
  /// If the task is canceled or fails, the stream will send an error event.
  /// See [TaskState] for more information of the different event types.
  ///
  /// If you do not need to know about on-going stream events, you can instead
  /// wait for the stream to complete via [onComplete].
  @override
  Stream<TaskSnapshotPlatform> get snapshotEvents {
    if (_snapshotEvents == null) {
      // The mobile version of the plugin pushes a "success" snapshot to the
      // onStateChanged stream, but the Firebase JS SDK does *not*.
      // We use a StreamGroup + Future.asStream to simulate that feature:
      final group = StreamGroup<TaskSnapshotPlatform>.broadcast();

      // This stream converts the UploadTask Snapshots from JS to the plugins'
      // It can also throw a FirebaseError internally, so we handle it.
      final onStateChangedStream = _task.onStateChanged
          .map<TaskSnapshotPlatform>((snapshot) =>
              fbUploadTaskSnapshotToTaskSnapshot(_reference, snapshot))
          .handleError((e) {
        throw getFirebaseException(e);
      });

      group.add(onStateChangedStream);
      group.add(onComplete.asStream());

      _snapshotEvents = group.stream;
    }
    return _snapshotEvents;
  }

  /// Returns a [Future] once the task has completed.
  ///
  /// Waiting for the future is not required, instead you can wait for a
  /// completion event via [snapshotEvents].
  @override
  Future<TaskSnapshotPlatform> get onComplete {
    if (_onComplete == null) {
      // This future represents the internal state of the Task.
      // It not only signals when the Task is done, but also when it fails.
      // The frontend Task uses _delegate.onComplete when implementing the
      // Future interface, so we must ensure we reject with the correct
      // type of Exception.
      _onComplete = _task.future
          .then<TaskSnapshotPlatform>(
        (snapshot) => fbUploadTaskSnapshotToTaskSnapshot(_reference, snapshot),
      )
          .catchError((e) {
        throw getFirebaseException(e);
      });
    }
    return _onComplete;
  }

  /// The latest [TaskSnapshot] for this task.
  @override
  TaskSnapshotPlatform get snapshot {
    return fbUploadTaskSnapshotToTaskSnapshot(_reference, _task.snapshot);
  }

  /// Pauses the current task.
  ///
  /// Calling this method will trigger a snapshot event with a [TaskState.paused]
  /// state.
  @override
  Future<bool> pause() async {
    if (snapshot.state == TaskState.paused) {
      return true;
    }

    final paused = _task.pause();
    // Wait until the snapshot is paused, then return the value of paused...
    return snapshotEvents
        .takeWhile((snapshot) => snapshot.state != TaskState.paused)
        .last
        .then<bool>((_) => paused);
  }

  /// Resumes the current task.
  ///
  /// Calling this method will trigger a snapshot event with a [TaskState.running]
  /// state.
  @override
  Future<bool> resume() async {
    return _task.resume();
  }

  /// Cancels the current task.
  ///
  /// Calling this method will cause the task to fail. Both the Future ([onComplete])
  /// and stream ([streamEvents]) will trigger an error with a [FirebaseException].
  @override
  Future<bool> cancel() async {
    if (snapshot.state == TaskState.canceled) {
      return true;
    }

    final canceled = _task.cancel();
    // The snapshotEvents will eventually throw an exception when the user cancels.
    // Wait for that signal, and then return the value of "canceled" (or true).
    return snapshotEvents
        .drain()
        .then<bool>((_) => canceled, onError: (_) => canceled);
  }
}
