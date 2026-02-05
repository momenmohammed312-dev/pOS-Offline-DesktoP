import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../services/license_manager.dart';

// Provider for license state
final licenseStateProvider = FutureProvider<bool>((ref) async {
  try {
    final licenseManager = LicenseManager();
    // Add timeout to prevent infinite loading
    return await licenseManager.isLicenseValid().timeout(
      const Duration(seconds: 5),
      onTimeout: () => false, // If timeout, assume no license
    );
  } catch (e) {
    return false; // If error, assume no license
  }
});

// Provider to trigger license refresh
final licenseRefreshProvider = StateProvider<int>((ref) => 0);

// Provider for current license
final currentLicenseProvider = FutureProvider((ref) async {
  final licenseManager = LicenseManager();
  return await licenseManager.getCurrentLicense();
});
