import 'package:kskfinance/Utilities/Reports/PendingReport/LastWeekPaymentScreen.dart';
import 'package:kskfinance/Utilities/Reports/PendingReport/PartyPendingDetailsScreen.dart';
import 'package:flutter/material.dart';
import 'package:kskfinance/Utilities/Reports/CusFullTrans/ReportScreen2.dart';
import 'package:kskfinance/Utilities/Reports/Custrans/ReportScreen1.dart';
import 'package:kskfinance/Utilities/Reports/chartreport/ReportFilterScreen.dart';
import 'package:kskfinance/Utilities/Reports/Dailyreport/PartyReportPage.dart';
import 'package:easy_localization/easy_localization.dart';

class ViewReportsPage extends StatelessWidget {
  const ViewReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('reportsScreen.title'.tr()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'reportsScreen.customerReports'.tr(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Report 1
            _buildReportCard(
              context: context,
              icon: Icons.description,
              iconColor: Colors.blue,
              title: 'reportsScreen.customerTransactionsReport'.tr(),
              subtitle: 'reportsScreen.customerTransactionsSubtitle'.tr(),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ReportScreen2()),
              ),
            ),

            const SizedBox(height: 12),

            // Report 2
            _buildReportCard(
              context: context,
              icon: Icons.picture_as_pdf,
              iconColor: Colors.deepPurple,
              title: 'reportsScreen.customerListPdf'.tr(),
              subtitle: 'reportsScreen.customerListSubtitle'.tr(),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportScreen1()),
              ),
            ),
            // ...existing code...
            _buildReportCard(
              context: context,
              icon: Icons.description,
              iconColor: Colors.blue,
              title: 'reportsScreen.dailyTransactionChart'.tr(),
              subtitle: 'reportsScreen.dailyTransactionSubtitle'.tr(),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportFilterScreen()),
              ),
            ),
            _buildReportCard(
              context: context,
              icon: Icons.description,
              iconColor: Colors.blue,
              title: 'reportsScreen.pendingTransactionReport'.tr(),
              subtitle: 'reportsScreen.pendingTransactionSubtitle'.tr(),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const PartyPendingDetailsScreen()),
              ),
            ),
            _buildReportCard(
              context: context,
              icon: Icons.description,
              iconColor: Colors.blue,
              title: 'reportsScreen.activePartiesReport'.tr(),
              subtitle: 'reportsScreen.activePartiesSubtitle'.tr(),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PartyReportPage()),
              ),
            ),

// ...existing code...
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Icon(icon, color: iconColor, size: 28),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
