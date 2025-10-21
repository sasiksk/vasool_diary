import 'package:flutter/material.dart';
import 'package:kskfinance/Screens/Main/BulkInsert/EnhancedBulkInsertScreen.dart';
import 'package:kskfinance/Screens/Main/BulkInsert/AddressBasedBulkInsertScreen.dart';

class CollectionTypeDialog {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.upload_file, color: Colors.purple, size: 28),
              SizedBox(width: 8),
              Text('Collection Entry Type'),
            ],
          ),
          content: const Text(
            'Choose the type of collection entry you want to perform:',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
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
              label: const Text('All Parties',
                  style: TextStyle(color: Colors.white)),
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
              label:
                  const Text('By Area', style: TextStyle(color: Colors.white)),
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
