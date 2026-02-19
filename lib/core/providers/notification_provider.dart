import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import '../auth/auth_provider.dart';

/// Provider for the unread notification count
final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(currentUserProvider);
  
  if (user == null) {
    return Stream.value(0);
  }
  
  return NotificationService.getUnreadCount(user.uid);
});
