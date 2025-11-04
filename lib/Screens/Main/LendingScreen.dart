import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kskfinance/Data/Databasehelper.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:kskfinance/Utilities/AppBar.dart';
import 'package:kskfinance/Utilities/CustomDatePicker.dart';
import 'package:kskfinance/Utilities/CustomTextField.dart';
import 'package:kskfinance/finance_provider.dart';

class LendingCombinedDetailsScreen extends ConsumerWidget {
  final double preloadedamtgiven;
  final double preladedprofit;
  final String preladedlendate;
  final int preladedduedays;
  final int cid;

  LendingCombinedDetailsScreen({
    super.key,
    this.preloadedamtgiven = 0,
    this.preladedprofit = 0,
    this.preladedlendate = '',
    this.preladedduedays = 0,
    this.cid = 0,
  });

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amtGivenController = TextEditingController();
  final TextEditingController _profitController = TextEditingController();
  final TextEditingController _totalController = TextEditingController();
  final TextEditingController _lentDateController = TextEditingController();
  final TextEditingController _dueDaysController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();

  void _updateLending(
    BuildContext context,
    String lineName,
    String partyName,
    int lentid,
    double preloadedamtgiven,
  ) async {
    if (_formKey.currentState?.validate() == true) {
      try {
        final double amtGiven = double.parse(_amtGivenController.text);
        final double profit = double.parse(_profitController.text);
        final total = amtGiven + profit;

        final amtcolldata = await dbLending.getPartyDetails(lentid);

        final double existingAmtcollected = amtcolldata!['amtcollected'];

        if (total >= existingAmtcollected) {
          final updatedValues = {
            'LenId': lentid,
            'amtgiven': amtGiven,
            'profit': profit,
            'Lentdate': DateFormat(
              'yyyy-MM-dd',
            ).format(DateFormat('dd-MM-yyyy').parse(_lentDateController.text)),
            'duedays': int.parse(_dueDaysController.text),
            'status': 'active',
          };

          await CollectionDB.updateCollection(
            cid: cid,
            lenId: lentid,
            date: DateFormat(
              'yyyy-MM-dd',
            ).format(DateFormat('dd-MM-yyyy').parse(_lentDateController.text)),
            crAmt: total,
            drAmt: 0.0,
          );
          await dbLending.updateLending2(
            lineName: lineName,
            partyName: partyName,
            lenId: lentid,
            updatedValues: updatedValues,
          );

          // Fetch existing values from the Line table
          final db = await DatabaseHelper.getDatabase();
          final List<Map<String, dynamic>> existingEntries = await db.query(
            'Line',
            where: 'LOWER(Linename) = ?',
            whereArgs: [lineName.toLowerCase()],
          );

          if (existingEntries.isNotEmpty) {
            final existingEntry = existingEntries.first;
            final double existingAmtGiven = existingEntry['Amtgiven'];
            final double existingProfit = existingEntry['Profit'];

            final double newAmtGiven =
                existingAmtGiven - preloadedamtgiven + amtGiven;

            final double newProfit = existingProfit - preladedprofit + profit;

            // Update the Line table with new values
            await dbline.updateLineAmounts(
              lineName: lineName,
              amtGiven: newAmtGiven,
              profit: newProfit,
            );
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('lendingScreen.lendingUpdatedSuccess'.tr())),
          );

          /*Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => PartyDetailScreen()),
          );*/
          Navigator.of(context).pop();
        } else {
          // filepath: /path/to/CollectionScreen.dart
          Future.delayed(Duration.zero, () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text("messages.error".tr()),
                  content: Text('lendingScreen.invalidTotalAmount'.tr()),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text("actions.ok".tr()),
                    ),
                  ],
                );
              },
            );
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'lendingScreen.updateError'.tr()}: $e')),
        );
      }
    }
  }

  void _calculateTotal() {
    final amtGiven = double.tryParse(_amtGivenController.text) ?? 0.0;
    final profit = double.tryParse(_profitController.text) ?? 0.0;
    final total = amtGiven + profit;
    _totalController.text = total.toString();
  }

  void _calculateDueDate() {
    if (_lentDateController.text.isNotEmpty &&
        _dueDaysController.text.isNotEmpty) {
      DateTime lentDate = DateFormat(
        'dd-MM-yyyy',
      ).parse(_lentDateController.text);
      int dueDays = int.parse(_dueDaysController.text);
      DateTime dueDate = lentDate.add(Duration(days: dueDays));
      _dueDateController.text = DateFormat('dd-MM-yyyy').format(dueDate);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _amtGivenController.text = preloadedamtgiven.toString();
    _profitController.text = preladedprofit.toString();
    if (preladedlendate.isNotEmpty) {
      _lentDateController.text = DateFormat(
        'dd-MM-yyyy',
      ).format(DateFormat('yyyy-MM-dd').parse(preladedlendate));
    }
    _dueDaysController.text = preladedduedays.toString();

    // Call the calculation methods to update the total and due date
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateTotal();
      _calculateDueDate();
    });

    final lineName = ref.watch(currentLineNameProvider);
    final partyName = ref.watch(currentPartyNameProvider);
    final lenId = ref.watch(lenIdProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: "${'lendingScreen.title'.tr()} - ${partyName ?? ''}",
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Financial Details Form Section
                Center(
                  child: Text(
                    'lendingScreen.details'.tr(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _amtGivenController,
                  decoration: InputDecoration(
                    labelText: 'lendingScreen.amountGiven'.tr(),
                    hintText: 'lendingScreen.enterAmountGiven'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'lendingScreen.amountGivenRequired'.tr();
                    }
                    return null;
                  },
                  onChanged: (value) => _calculateTotal(),
                  onTap: () {
                    _amtGivenController.clear();
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _profitController,
                  decoration: InputDecoration(
                    labelText: 'lendingScreen.profit'.tr(),
                    hintText: 'lendingScreen.enterProfit'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'lendingScreen.profitRequired'.tr();
                    }
                    return null;
                  },
                  onChanged: (value) => _calculateTotal(),
                  onTap: () {
                    _profitController.clear();
                  },
                ),
                const SizedBox(height: 10),
                CustomTextField(
                  controller: _totalController,
                  labelText: 'lendingScreen.total'.tr(),
                  hintText: 'lendingScreen.enterTotal'.tr(),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'lendingScreen.totalRequired'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: CustomDatePicker(
                        controller: _lentDateController,
                        labelText: 'lendingScreen.lentDate'.tr(),
                        hintText: 'lendingScreen.pickLentDate'.tr(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _dueDaysController,
                        decoration: InputDecoration(
                          labelText: 'lendingScreen.dueDays'.tr(),
                          hintText: 'lendingScreen.enterDueDays'.tr(),
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'lendingScreen.dueDaysRequired'.tr();
                          }
                          return null;
                        },
                        onTap: () {
                          _dueDaysController.clear();
                        },
                        onChanged: (value) => _calculateDueDate(),
                        onFieldSubmitted: (value) => _calculateDueDate(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _dueDateController,
                        labelText: 'lendingScreen.dueDate'.tr(),
                        hintText: 'lendingScreen.calculatedDueDate'.tr(),
                        readOnly: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Submit Button
                Center(
                  child: SizedBox(
                    width: 250,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (_formKey.currentState?.validate() == true) {
                          DatabaseHelper.getLenId(lineName!, partyName!).then((
                            lenid,
                          ) async {
                            if (lenid != null) {
                              final lenStatus =
                                  await dbLending.getStatusByLenId(lenid);
                              if (lenStatus == 'passive' ||
                                  preloadedamtgiven > 0) {
                                _updateLending(
                                  context,
                                  lineName,
                                  partyName,
                                  lenid,
                                  preloadedamtgiven,
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'lendingScreen.cannotLendToActive'.tr(),
                                    ),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'lendingScreen.lenIdError'.tr(),
                                  ),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          });
                        }
                      },
                      icon: Icon(
                        preloadedamtgiven > 0
                            ? Icons.update_rounded
                            : Icons.send_rounded,
                        size: 24,
                      ),
                      label: Text(
                        preloadedamtgiven >= 0
                            ? 'lendingScreen.updateLending'.tr()
                            : 'lendingScreen.submitLending'.tr(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: preloadedamtgiven > 0
                            ? Colors.deepOrange
                            : Colors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
