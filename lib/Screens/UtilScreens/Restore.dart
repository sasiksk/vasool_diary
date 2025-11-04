import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:lottie/lottie.dart'; // For animations
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' as sql;
import 'package:easy_localization/easy_localization.dart';

class RestorePage extends StatefulWidget {
  @override
  _RestorePageState createState() => _RestorePageState();
}

class _RestorePageState extends State<RestorePage> {
  bool _isLoading = false;

  Future<void> restoreDatabase() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Request storage permissions
      if (/*await Permission.storage.request().isGranted ||
          await Permission.manageExternalStorage.request().isGranted*/
          1 == 1) {
        // Open file picker to select the database file
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.any, // Allow all file types
        );

        if (result != null && result.files.single.path != null) {
          // Get the selected file
          File selectedFile = File(result.files.single.path!);

          // Validate the file extension
          if (selectedFile.path.endsWith('.db')) {
            // Define the target database path
            final dbPath = await sql.getDatabasesPath();
            final dbFullPath = path.join(dbPath, 'finance3.db');

            // Delete the existing file if it exists
            File dbFile = File(dbFullPath);
            if (await dbFile.exists()) {
              await dbFile.delete();
            }

            // Copy the selected file to the app's database directory
            await selectedFile.copy(dbFullPath);

            // Show success animation
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return Center(
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Lottie.asset(
                            'assets/animations/sucess.json', // Add a Lottie animation for success
                            width: 150,
                            height: 150,
                            repeat: false,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'restoreScreen.databaseRestoredSuccessfully'.tr(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              exit(0); // Exit the application
                            },
                            child:
                                Text('restoreScreen.restartApplication'.tr()),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          } else {
            // Notify the user about the invalid file type
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('restoreScreen.invalidFileType'.tr()),
              ),
            );
          }
        } else {
          // User canceled the picker
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('restoreScreen.noFileSelected'.tr())),
          );
        }
      } else {
        // Permissions not granted
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('restoreScreen.storagePermissionsNotGranted'.tr())),
        );
      }
    } catch (e) {
      // Handle any errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('restoreScreen.errorRestoringDatabase'.tr(namedArgs: {
          'error': e.toString(),
        }))),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('restoreScreen.title'.tr()),
      ),
      body: Center(
        child: _isLoading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    'assets/animations/restore.json', // Add a Lottie animation for loading
                    width: 150,
                    height: 150,
                    repeat: true,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'restoreScreen.restoringDatabase'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    'assets/animations/restore.json', // Add a Lottie animation for restore
                    width: 200,
                    height: 200,
                    repeat: true,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'restoreScreen.restoreInstructions'.tr(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: restoreDatabase,
                    icon: const Icon(Icons.restore),
                    label: Text('restoreScreen.restoreYourDatabase'.tr()),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
