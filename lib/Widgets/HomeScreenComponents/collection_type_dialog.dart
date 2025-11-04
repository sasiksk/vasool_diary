import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:kskfinance/Screens/Main/BulkInsert/EnhancedBulkInsertScreen.dart';
import 'package:kskfinance/Screens/Main/BulkInsert/AddressBasedBulkInsertScreen.dart';

class CollectionTypeDialog {
  static void show(BuildContext context) {
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
}
