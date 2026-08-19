import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../storage/app_preferences.dart';

/// UUID v4 sinh 1 lần, lưu vĩnh viễn — dùng cho header `x-anonymous-id` khi
/// người dùng ở chế độ khách.
final anonymousIdProvider = FutureProvider<String>((ref) async {
  final prefs = await ref.watch(appPreferencesProvider.future);
  final existing = prefs.anonymousId;
  if (existing != null) return existing;

  final generated = const Uuid().v4();
  await prefs.setAnonymousId(generated);
  return generated;
}, name: 'anonymousIdProvider');
