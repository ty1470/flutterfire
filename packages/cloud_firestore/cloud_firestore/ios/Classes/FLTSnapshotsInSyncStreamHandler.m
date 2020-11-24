//
//  FLTSnapshotsInSyncStreamHandler.m
//  cloud_firestore
//
//  Created by Sebastian Roth on 24/11/2020.
//

#import <Firebase/Firebase.h>
#import <firebase_core/FLTFirebasePluginRegistry.h>

#import "Private/FLTSnapshotsInSyncStreamHandler.h"
#import "Private/FLTFirebaseFirestoreUtils.h"

@implementation FLTSnapshotsInSyncStreamHandler {
  NSMutableDictionary<NSNumber *, id<FIRListenerRegistration>> *_listeners;
}

- (FlutterError *_Nullable)onListenWithArguments:(id _Nullable)arguments
                                       eventSink:(nonnull FlutterEventSink)events {
  
  NSNumber *handle = arguments[@"handle"];
  FIRFirestore *firestore = arguments[@"firestore"];
  
  id listener = ^() {
    events(@{ @"handle" : handle });
  };

  id<FIRListenerRegistration> listenerRegistration = [firestore addSnapshotsInSyncListener:listener];

  @synchronized(_listeners) {
    _listeners[handle] = listenerRegistration;
  }

  return nil;
}

- (FlutterError *_Nullable)onCancelWithArguments:(id _Nullable)arguments {
  NSNumber *handle = arguments[@"handle"];

  @synchronized(_listeners) {
    [_listeners[handle] remove];
    [_listeners removeObjectForKey:handle];
  }

  return nil;
}

@end
