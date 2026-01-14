import 'package:firebase_core/firebase_core.dart';

class FirebaseService {
  static Future<void> init() async {
    await Firebase.initializeApp();
  }
}
