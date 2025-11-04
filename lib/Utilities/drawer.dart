import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:kskfinance/ContactUs.dart';
import 'package:kskfinance/Screens/Main/BulkInsert/AddressBasedBulkInsertScreen.dart';
import 'package:kskfinance/Screens/Main/BulkInsert/EnhancedBulkInsertScreen.dart';
import 'package:kskfinance/Screens/Main/OnboardingScreen.dart';
import 'package:kskfinance/Screens/Main/cashflowscreen.dart';
import 'package:kskfinance/Screens/TableDetailsScreen.dart';
import 'package:kskfinance/Screens/Main/PartySearchScreen.dart';

import 'package:kskfinance/Screens/UtilScreens/Backuppage.dart';
import 'package:kskfinance/Screens/premium_screen.dart';
import 'package:kskfinance/Screens/subscription_simulation_page.dart';
import 'package:kskfinance/Data/Databasehelper.dart';
import 'package:kskfinance/Screens/UtilScreens/Restore.dart';
import 'package:kskfinance/Utilities/Reports/CustomerReportScreen.dart';
import 'package:kskfinance/Screens/Main/home_screen.dart';
import 'package:kskfinance/Services/premium_service.dart';
import 'package:kskfinance/Utilities/app_rating_share.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget buildDrawer(BuildContext context) {
  return Drawer(
    // Add a key that changes with locale to force rebuild
    key: ValueKey(context.locale.languageCode),
    child: Column(
      children: [
        // Gradient Header with user info
        Container(
          padding: const EdgeInsets.only(top: 40, bottom: 20),
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2196F3), Color(0xFF42A5F5), Color(0xFF81D4FA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => _handleAvatarTap(context),
                    child: const CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person,
                          size: 40, color: Colors.blueAccent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'app.welcome'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'app.title'.tr(),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),

        // Drawer Items
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 10),
            children: [
              _buildDrawerItem(
                context,
                icon: Icons.home,
                title: 'navigation.home'.tr(),
                onTap: () => _navigateTo(context, const HomeScreen()),
              ),
              /*  _buildDrawerItem(
                context,
                icon: Icons.insert_drive_file,
                title: 'Bulk Insert',
                onTap: () => _navigateTo(context, const TableDetailsScreen()),
              ),*/
              _buildDrawerItem(
                context,
                icon: Icons.monetization_on,
                title: 'navigation.collections'.tr(),
                onTap: () {
                  Navigator.pop(context); // Close drawer first
                  _showCollectionTypeDialog(context);
                },
              ),
              _buildDrawerItem(
                context,
                icon: Icons.search,
                title: 'navigation.parties'.tr(),
                onTap: () => _navigateTo(context, const PartySearchScreen()),
              ),
              _buildDrawerItem(
                context,
                icon: Icons.backup,
                title: 'navigation.backup'.tr(),
                onTap: () => _navigateTo(context, const DownloadDBScreen()),
              ),
              _buildDrawerItem(
                context,
                icon: Icons.restore,
                title: 'navigation.restore'.tr(),
                onTap: () => _navigateTo(context, RestorePage()),
              ),
              // Auto Backup is now invisible - works automatically in background
              _buildDrawerItem(
                context,
                icon: Icons.picture_as_pdf,
                title: 'navigation.reports'.tr(),
                onTap: () => _navigateTo(context, const ViewReportsPage()),
              ),
              _buildDrawerItem(
                context,
                icon: Icons.picture_as_pdf,
                title: 'navigation.reports'.tr(),
                onTap: () => _navigateTo(context, const CashFlowScreen()),
              ),
              const Divider(thickness: 1),

              // Premium/Subscription Management
              FutureBuilder<bool>(
                future: _getHasPremiumAccess(),
                builder: (context, snapshot) {
                  final hasPremium = snapshot.data ?? false;

                  return _buildDrawerItem(
                    context,
                    icon: hasPremium ? Icons.star : Icons.star_outline,
                    title: hasPremium ? 'Premium Active' : 'Upgrade to Premium',
                    onTap: () => _navigateTo(context, const PremiumScreen()),
                  );
                },
              ),

              // Debug: Premium Simulation (only in debug mode)
              if (const bool.fromEnvironment('dart.vm.product') == false)
                _buildDrawerItem(
                  context,
                  icon: Icons.science,
                  title: '🔬 Premium Simulation',
                  onTap: () =>
                      _navigateTo(context, const SubscriptionSimulationPage()),
                ),

              const Divider(thickness: 1),

              // App Rating & Sharing Section
              _buildDrawerItem(
                context,
                icon: Icons.star,
                title: 'drawer.rateApp'.tr(),
                onTap: () {
                  Navigator.pop(context);
                  AppRatingShare.showRateAppDialog(context);
                },
              ),
              _buildDrawerItem(
                context,
                icon: Icons.share,
                title: 'drawer.shareApp'.tr(),
                onTap: () {
                  Navigator.pop(context);
                  AppRatingShare.showShareAppSheet(context);
                },
              ),
              _buildDrawerItem(
                context,
                icon: Icons.system_update,
                title: 'drawer.updateApp'.tr(),
                onTap: () {
                  Navigator.pop(context);
                  AppRatingShare.rateApp();
                },
              ),
              const Divider(thickness: 1),

              _buildDrawerItem(
                context,
                icon: Icons.restore_from_trash,
                title: 'drawer.resetAll'.tr(),
                onTap: () => _showResetConfirmationDialog(context),
              ),
              /* _buildDrawerItem(
                context,
                icon: Icons.app_registration,
                title: 'drawer.resetForRegistration'.tr(),
                onTap: () => _showRegistrationResetDialog(context),
              ),*/
              _buildDrawerItem(
                context,
                icon: Icons.contact_phone,
                title: 'settings.contactUs'.tr(),
                onTap: () => _navigateTo(context, const ContactPage()),
              ),
              _buildDrawerItem(
                context,
                icon: Icons.exit_to_app,
                title: 'drawer.exit'.tr(),
                onTap: () => SystemNavigator.pop(),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

void _showCollectionTypeDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.upload_file, color: Colors.purple, size: 28),
            const SizedBox(width: 8),
            Text('drawer.collectionType'.tr()),
          ],
        ),
        content: Text(
          'drawer.chooseCollectionType'.tr(),
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('actions.cancel'.tr(),
                style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EnhancedBulkInsertScreen(),
                ),
              );
            },
            icon: const Icon(Icons.list_alt, color: Colors.white),
            label: Text('drawer.allParties'.tr(),
                style: const TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddressBasedBulkInsertScreen(),
                ),
              );
            },
            icon: const Icon(Icons.location_on, color: Colors.white),
            label: Text('drawer.byArea'.tr(),
                style: const TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
            ),
          ),
        ],
      );
    },
  );
}

Widget _buildDrawerItem(
  BuildContext context, {
  required IconData icon,
  required String title,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.teal.shade700),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              softWrap: true,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ),
  );
}

// Reusable Drawer Item Widget

// Navigation Helper Function

// Reset Confirmation Dialog
void _showResetConfirmationDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('drawer.confirm'.tr()),
        content: Text('drawer.resetConfirmation'.tr()),
        actions: [
          TextButton(
            child: Text('actions.cancel'.tr()),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text('actions.confirm'.tr()),
            onPressed: () {
              DatabaseHelper.dropDatabase();
              Navigator.of(context).pop();
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('messages.success'.tr()),
                    content: Text('drawer.resetSuccess'.tr()),
                    actions: [
                      TextButton(
                        child: Text('actions.confirm'.tr()),
                        onPressed: () {
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      );
    },
  );
}

void _navigateTo(BuildContext context, Widget screen) {
  Navigator.pop(context);
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => screen),
  );
}

// Add this method to handle triple tap
int _avatarTapCount = 0;
DateTime? _avatarLastTapTime;

void _handleAvatarTap(BuildContext context) {
  final now = DateTime.now();

  // Reset counter if more than 2 seconds passed since last tap
  if (_avatarLastTapTime == null ||
      now.difference(_avatarLastTapTime!).inSeconds > 2) {
    _avatarTapCount = 1;
  } else {
    _avatarTapCount++;
  }

  _avatarLastTapTime = now;

  // If triple tap detected
  if (_avatarTapCount == 3) {
    _avatarTapCount = 0; // Reset counter
    _navigateTo(context, const TableDetailsScreen());

    // Optional: Show a brief message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('drawer.secretAccess'.tr()),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.green,
      ),
    );
  }
}

void _showRegistrationResetDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.app_registration, color: Colors.blue, size: 28),
            const SizedBox(width: 8),
            Text('drawer.registrationReset'.tr()),
          ],
        ),
        content: Text('drawer.registrationResetWarning'.tr()),
        actions: [
          TextButton(
            child: Text('actions.cancel'.tr()),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text('actions.confirm'.tr()),
            onPressed: () async {
              // Clear registration data
              await _clearRegistrationData();
              Navigator.of(context).pop();

              // Navigate to onboarding
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (context) => const OnboardingScreen()),
                (route) => false,
              );
            },
          ),
        ],
      );
    },
  );
}

Future<void> _clearRegistrationData() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstLaunch', true);
    await prefs.remove('userName');
    await prefs.remove('userPhone');
    await prefs.remove('deviceId');
  } catch (e) {
    print('Error clearing registration data: $e');
  }
}

// Helper function for premium status
Future<bool> _getHasPremiumAccess() async {
  try {
    final premiumService = PremiumService();
    await premiumService.initialize();
    return premiumService.hasPremiumAccess;
  } catch (e) {
    print('Error getting premium access: $e');
    return false;
  }
}
