import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'app/app.dart';
import 'core/services/storage_service.dart';
import 'core/services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await StorageService.init();

  // Initialize push notifications if user is already logged in
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    await PushNotificationService.init(currentUser.uid);
    await PushNotificationService.handleInitialMessage();
  }

  runApp(const ProviderScope(child: CareKudosApp()));
}
