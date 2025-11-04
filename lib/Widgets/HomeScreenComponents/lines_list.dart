import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kskfinance/Screens/Main/LineScreen.dart';
import 'package:kskfinance/Screens/Main/linedetailScreen.dart';
import 'package:kskfinance/finance_provider.dart';
import 'package:kskfinance/Data/Databasehelper.dart';
import 'package:easy_localization/easy_localization.dart';

class LinesList extends ConsumerWidget {
  final List<String> lineNames;
  final Map<String, Map<String, dynamic>> lineDetailsMap;
  final VoidCallback onDataChanged;

  const LinesList({
    super.key,
    required this.lineNames,
    required this.lineDetailsMap,
    required this.onDataChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'home.yourLines'.tr(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: lineNames.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: Colors.grey.withOpacity(0.2),
              indent: 20,
              endIndent: 20,
            ),
            itemBuilder: (context, index) {
              final lineName = lineNames[index];
              final lineDetails = lineDetailsMap[lineName] ?? {};
              final amtGiven =
                  (lineDetails['Amtgiven'] as num?)?.toDouble() ?? 0.0;
              final profit = (lineDetails['Profit'] as num?)?.toDouble() ?? 0.0;
              final expense =
                  (lineDetails['expense'] as num?)?.toDouble() ?? 0.0;
              final amtRecieved =
                  (lineDetails['Amtrecieved'] as num?)?.toDouble() ?? 0.0;
              final calculatedValue = amtGiven + profit - expense - amtRecieved;

              return LineListItem(
                lineName: lineName,
                lineDetails: lineDetails,
                calculatedValue: calculatedValue,
                onTap: () => _handleLineSelected(ref, lineName, context),
                onUpdate: () => _navigateToLineScreen(context, lineDetails),
                onDelete: () => _showDeleteDialog(context, lineName),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _handleLineSelected(
      WidgetRef ref, String lineName, BuildContext context) {
    ref.read(currentLineNameProvider.notifier).state = lineName;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LineDetailScreen()),
    );
  }

  void _navigateToLineScreen(
      BuildContext context, Map<String, dynamic> lineDetails) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LineScreen(entry: lineDetails),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String lineName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('lines.confirmDeletion'.tr()),
          content: Text('lines.deletionWarning'.tr()),
          actions: <Widget>[
            TextButton(
              child: Text('actions.cancel'.tr()),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('actions.delete'.tr(),
                  style: const TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop();
                final lenIds = await dbLending.getLenIdsByLineName(lineName);
                await dbline.deleteLine(lineName);
                await dbLending.deleteLendingByLineName(lineName);
                for (final lenId in lenIds) {
                  await CollectionDB.deleteEntriesByLenId(lenId);
                }
                onDataChanged();
              },
            ),
          ],
        );
      },
    );
  }
}

class LineListItem extends StatelessWidget {
  final String lineName;
  final Map<String, dynamic> lineDetails;
  final double calculatedValue;
  final VoidCallback onTap;
  final VoidCallback onUpdate;
  final VoidCallback onDelete;

  const LineListItem({
    super.key,
    required this.lineName,
    required this.lineDetails,
    required this.calculatedValue,
    required this.onTap,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey('line_$lineName'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0x1A2196F3),
          child: Text(
            lineName.isNotEmpty ? lineName[0].toUpperCase() : '?',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        title: Text(
          lineName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          '${'home.balance'.tr()}: ₹${calculatedValue.toStringAsFixed(0)}',
          style: TextStyle(
            color: calculatedValue >= 0 ? Colors.green : Colors.red,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (String value) {
            if (value == 'actions.update'.tr()) {
              onUpdate();
            } else if (value == 'actions.delete'.tr()) {
              onDelete();
            }
          },
          itemBuilder: (BuildContext context) {
            return ['actions.update'.tr(), 'actions.delete'.tr()]
                .map((String choice) {
              return PopupMenuItem<String>(
                value: choice,
                child: Text(choice),
              );
            }).toList();
          },
        ),
        onTap: onTap,
      ),
    );
  }
}
