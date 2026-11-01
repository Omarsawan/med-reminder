// Firebase settings for the med-reminder-d82ba project, built from
// android/app/google-services.json and ios/Runner/GoogleService-Info.plist.
// These identify the project; access is controlled by firestore.rules.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => switch (defaultTargetPlatform) {
        TargetPlatform.android => android,
        TargetPlatform.iOS => ios,
        _ => throw UnsupportedError('Family sharing is only set up for Android and iOS.'),
      };

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBt7CqVs7GM9MOzzpITGnsU_D7Z7nWoaFw',
    appId: '1:335413852220:android:b879407c2e53cb8ceb6b39',
    messagingSenderId: '335413852220',
    projectId: 'med-reminder-d82ba',
    storageBucket: 'med-reminder-d82ba.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBgEu-uCgpr4XKZ-qiLPSoDCRSdY7lw0Ak',
    appId: '1:335413852220:ios:5bb70b732863ee18eb6b39',
    messagingSenderId: '335413852220',
    projectId: 'med-reminder-d82ba',
    storageBucket: 'med-reminder-d82ba.firebasestorage.app',
    iosBundleId: 'com.osawan.medReminder',
  );
}
