import 'package:flutter/material.dart';
import 'package:kskfinance/Utilities/Reports/Dailyreport/PartyReportPage.dart';
import 'package:kskfinance/Screens/UtilScreens/Backuppage.dart';
import 'package:kskfinance/Utilities/Reports/PendingReport/PartyPendingDetailsScreen.dart';
import 'package:kskfinance/Utilities/Reports/CustomerReportScreen.dart';

class QuickActionsCard extends StatelessWidget {
  final VoidCallback onCollectionEntryTap;

  const QuickActionsCard({
    super.key,
    required this.onCollectionEntryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.flash_on,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: 5,
              itemBuilder: (context, index) {
                final actions = [
                  {
                    'title': 'Collection\nEntry',
                    'icon': Icons.payments,
                    'color': const Color(0xFF667eea),
                    'isPrimary': true,
                    'onTap': onCollectionEntryTap,
                  },
                  {
                    'title': 'Party\nReport',
                    'icon': Icons.analytics,
                    'color': const Color(0xFF764ba2),
                    'isPrimary': true,
                    'onTap': () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const PartyReportPage()),
                        ),
                  },
                  {
                    'title': 'Backup\nData',
                    'icon': Icons.cloud_upload,
                    'color': const Color(0xFF42A5F5),
                    'isPrimary': false,
                    'onTap': () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const DownloadDBScreen()),
                        ),
                  },
                  {
                    'title': 'Follow Up',
                    'icon': Icons.schedule,
                    'color': const Color(0xFF81D4FA),
                    'isPrimary': false,
                    'onTap': () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const PartyPendingDetailsScreen(),
                          ),
                        ),
                  },
                  {
                    'title': 'All\nReports',
                    'icon': Icons.folder_open,
                    'color': const Color(0xFF2196F3),
                    'isPrimary': false,
                    'onTap': () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ViewReportsPage()),
                        ),
                  },
                ];

                final action = actions[index];
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: QuickActionButton(
                    title: action['title'] as String,
                    icon: action['icon'] as IconData,
                    color: action['color'] as Color,
                    onTap: action['onTap'] as VoidCallback,
                    isPrimary: action['isPrimary'] as bool,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class QuickActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isPrimary;

  const QuickActionButton({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    // Pre-calculate expensive operations for better performance
    final borderRadius = BorderRadius.circular(16);
    final decoration = BoxDecoration(
      gradient: isPrimary
          ? LinearGradient(
              colors: [color, color.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.15)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
      borderRadius: borderRadius,
      border: isPrimary
          ? null
          : Border.all(color: color.withOpacity(0.3), width: 1.5),
      boxShadow: isPrimary
          ? [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ]
          : [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Container(
          width: 100,
          padding: const EdgeInsets.all(12),
          decoration: decoration,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isPrimary ? Colors.white : color,
                size: isPrimary ? 32 : 28,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isPrimary ? 12 : 11,
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? Colors.white : color,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
