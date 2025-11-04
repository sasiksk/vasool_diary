import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:kskfinance/Data/Databasehelper.dart';
import 'package:kskfinance/Utilities/CustomTextField.dart';
import 'package:kskfinance/Screens/Main/home_screen.dart';
import 'package:kskfinance/Utilities/AppBar.dart'; // Import CustomAppBar

class LineScreen extends StatefulWidget {
  final Map<String, dynamic>? entry;

  const LineScreen({super.key, this.entry});

  @override
  _LineScreenState createState() => _LineScreenState();
}

class _LineScreenState extends State<LineScreen> {
  final TextEditingController _lineNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      _lineNameController.text = widget.entry!['Linename'];
    }
  }

  @override
  void dispose() {
    _lineNameController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _lineNameController.clear();
  }

  void _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        if (widget.entry != null) {
          // Update existing entry in Line table
          await dbline.updateLine(
            lineName: widget.entry!['Linename'],
            updatedValues: {
              'Linename': _lineNameController.text,
            },
          );
          await dbline.updateLineNameInLending(
            oldLineName: widget.entry!['Linename'],
            newLineName: _lineNameController.text,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('lineScreen.bookEntryUpdated'.tr())),
          );
        } else {
          // Insert new entry
          await dbline.insertLine(
            _lineNameController.text,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('lineScreen.bookEntryAdded'.tr())),
          );
        }
        _resetForm();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.entry != null
            ? 'lineScreen.editBook'.tr()
            : 'lineScreen.addNewBook'.tr(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                controller: _lineNameController,
                labelText: 'lineScreen.enterLineName'.tr(),
                hintText: 'lineScreen.enterLineName'.tr(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'lineScreen.pleaseEnterName'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      child: Text(widget.entry != null
                          ? 'lineScreen.update'.tr()
                          : 'lineScreen.submit'.tr()),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _resetForm,
                      child: Text('lineScreen.reset'.tr()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                },
                child: Text('lineScreen.back'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
