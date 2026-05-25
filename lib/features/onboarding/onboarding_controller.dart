import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../shared/providers/app_providers.dart';

class OnboardingController {
  final AppDatabase db;
  final Ref ref;

  OnboardingController({required this.db, required this.ref});

  Future<void> completeSetup({required String name, String? salary}) async {
    await db.into(db.userProfile).insertOnConflictUpdate(
      UserProfileCompanion.insert(key: name, value: name),
    );
    if (salary != null && salary.isNotEmpty) {
      await db.into(db.userProfile).insertOnConflictUpdate(
        UserProfileCompanion.insert(key: 'salary', value: salary),
      );
    }
    ref.read(isFirstLaunchProvider.notifier).state = false;
  }
}

final onboardingControllerProvider = Provider<OnboardingController>((ref) {
  return OnboardingController(db: ref.watch(databaseProvider), ref: ref);
});
