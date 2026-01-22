import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pos_offline_desktop/core/database/app_database.dart';
import 'package:pos_offline_desktop/core/provider/app_database_provider.dart';
import 'package:pos_offline_desktop/ui/home/modern_home.dart';

GoRouter createRouter(AppDatabase db) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => ModernHomeScreen(db: db),
      ),
    ],
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return createRouter(db);
});
