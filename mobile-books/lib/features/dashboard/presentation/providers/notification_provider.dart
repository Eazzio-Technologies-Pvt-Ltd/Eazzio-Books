import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/features/auth/presentation/providers/auth_provider.dart';
import 'package:mobile_books/features/dashboard/data/models/notification_model.dart';
import 'package:mobile_books/features/dashboard/data/services/notification_service.dart';

class NotificationListNotifier extends AsyncNotifier<List<NotificationModel>> {
  @override
  Future<List<NotificationModel>> build() async {
    // Watch auth status so notifications reload automatically when user logs in/switches orgs
    ref.watch(authNotifierProvider);
    return ref.watch(notificationServiceProvider).getNotifications();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return ref.read(notificationServiceProvider).getNotifications();
    });
  }
}

final notificationsProvider = AsyncNotifierProvider<NotificationListNotifier, List<NotificationModel>>(() {
  return NotificationListNotifier();
});
