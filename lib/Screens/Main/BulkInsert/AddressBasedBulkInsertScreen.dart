import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:kskfinance/Data/Databasehelper.dart';
import 'package:kskfinance/Screens/Main/CollectionScreen.dart';
import 'package:intl/intl.dart';
import 'package:kskfinance/Sms.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddressBasedBulkInsertScreen extends StatefulWidget {
  const AddressBasedBulkInsertScreen({super.key});

  @override
  _AddressBasedBulkInsertScreenState createState() =>
      _AddressBasedBulkInsertScreenState();
}

class _AddressBasedBulkInsertScreenState
    extends State<AddressBasedBulkInsertScreen> {
  List<String> _lineNames = [];
  String? _selectedLineName;
  String? _selectedAddress;
  List<Map<String, dynamic>> lendingDetails = [];
  List<String> uniqueAddresses = [];
  Map<int, bool> selectedParties = {};
  Map<int, TextEditingController> amountControllers = {};
  Map<int, bool> hasCollectionToday = {};
  DateTime selectedDate = DateTime.now();
  final TextEditingController _dateController = TextEditingController(
    text: DateFormat('dd-MM-yyyy').format(DateTime.now()),
  );

  List<Map<String, String>> pendingSmsMessages = [];
  bool isProcessing = false;
  bool _isWeeklyView = false; // Daily by default

  @override
  void initState() {
    super.initState();
    _loadLineNames();
  }

  @override
  void dispose() {
    for (var controller in amountControllers.values) {
      controller.dispose();
    }
    _dateController.dispose();
    super.dispose();
  }

  // Reused functions from EnhancedBulkInsertScreen
  Future<void> _loadLineNames() async {
    final lineNames = await dbline.getLineNames();
    setState(() {
      _lineNames = lineNames;
    });
  }

  Future<void> _loadPartyNames(String lineName) async {
    final details =
        await dbLending.getLendingDetailsWithAddressByLineName(lineName);
    final addresses = await dbLending.getUniqueAddressesByLineName(lineName);

    if (details != null) {
      setState(() {
        lendingDetails = details
            .where((detail) => detail['status'] == 'active')
            .map((detail) => Map<String, dynamic>.from(detail))
            .toList();
        uniqueAddresses = addresses;
        _selectedAddress = null;
        _resetData();
        _initializeControllers();
      });
      await _checkCollectionsForDate();
    }
  }

  Future<bool> _hasCollectionForDate(int lenId, String date) async {
    final db = await DatabaseHelper.getDatabase();
    final List<Map<String, dynamic>> result = await db.query(
      'Collection',
      where: 'LenId = ? AND Date = ?',
      whereArgs: [lenId, date],
    );
    return result.isNotEmpty;
  }

  Future<void> _checkCollectionsForDate() async {
    final dateString = DateFormat('yyyy-MM-dd').format(selectedDate);
    hasCollectionToday.clear();

    for (var detail in lendingDetails) {
      final lenId = detail['LenId'];
      hasCollectionToday[lenId] =
          await _hasCollectionForDate(lenId, dateString);
    }

    setState(() {});
  }

  void _resetData() {
    selectedParties.clear();
    pendingSmsMessages.clear();
    for (var controller in amountControllers.values) {
      controller.dispose();
    }
    amountControllers.clear();
  }

  void _initializeControllers() {
    for (var detail in lendingDetails) {
      final lenId = detail['LenId'];
      final perDayAmt =
          (detail['amtgiven'] + detail['profit']) / detail['duedays'];

      // Calculate amount based on Daily/Weekly selection
      final displayAmount =
          _isWeeklyView ? (perDayAmt * 7).roundToDouble() : perDayAmt;

      amountControllers[lenId] =
          TextEditingController(text: displayAmount.toStringAsFixed(2));
      selectedParties[lenId] = false;
    }
  }

  void _refreshAmountsForToggle() {
    for (var detail in lendingDetails) {
      final lenId = detail['LenId'];
      final perDayAmt =
          (detail['amtgiven'] + detail['profit']) / detail['duedays'];

      // Calculate amount based on Daily/Weekly selection
      final displayAmount =
          _isWeeklyView ? (perDayAmt * 7).roundToDouble() : perDayAmt;

      if (amountControllers[lenId] != null) {
        amountControllers[lenId]!.text = displayAmount.toStringAsFixed(2);
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        _dateController.text = DateFormat('dd-MM-yyyy').format(picked);
      });
      if (lendingDetails.isNotEmpty) {
        await _checkCollectionsForDate();
      }
    }
  }

  double _calculateTotalSelected() {
    double total = 0.0;
    for (var party in filteredLendingDetails) {
      final lenId = party['LenId'];
      if (selectedParties[lenId] == true) {
        final controller = amountControllers[lenId];
        final amount = double.tryParse(controller?.text ?? '0') ?? 0.0;
        total += amount;
      }
    }
    return total;
  }

  void _togglePartySelection(int lenId) {
    setState(() {
      selectedParties[lenId] = !(selectedParties[lenId] ?? false);
    });
  }

  // Filter parties by selected address
  List<Map<String, dynamic>> get filteredLendingDetails {
    if (_selectedAddress == null || _selectedAddress!.isEmpty) {
      return lendingDetails;
    }
    return lendingDetails
        .where(
            (party) => party['PartyAdd']?.toString().trim() == _selectedAddress)
        .toList();
  }

  // Reused processing methods from EnhancedBulkInsertScreen
  void _processBulkUpdate() {
    List<Map<String, dynamic>> selectedEntries = [];
    double totalAmount = 0.0;

    for (var party in filteredLendingDetails) {
      final lenId = party['LenId'];
      if (selectedParties[lenId] == true) {
        final controller = amountControllers[lenId];
        final amount = double.tryParse(controller?.text ?? '0') ?? 0.0;
        if (amount > 0) {
          selectedEntries.add({
            'party': party,
            'amount': amount,
            'lenId': lenId,
          });
          totalAmount += amount;
        }
      }
    }

    if (selectedEntries.isEmpty) {
      _showSnackBar('bulkInsertScreen.noPartiesSelected'.tr(), Colors.orange);
      return;
    }

    _showBulkUpdateDialog(selectedEntries, totalAmount);
  }

  void _showBulkUpdateDialog(
      List<Map<String, dynamic>> entries, double totalAmount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('bulkInsertScreen.bulkUpdateConfirmation'.tr()),
          content: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxHeight: 300),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('bulkInsertScreen.line'.tr(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text(_selectedLineName ?? ''),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('bulkInsertScreen.address'.tr(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Flexible(
                                child: Text(_selectedAddress ?? 'All',
                                    overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('bulkInsertScreen.date'.tr(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text(DateFormat('dd-MM-yyyy').format(selectedDate)),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('bulkInsertScreen.parties'.tr(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text('${entries.length}'),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('bulkInsertScreen.total'.tr(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('₹${totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return ListTile(
                        dense: true,
                        title: Text(entry['party']['PartyName'] ?? 'Unknown',
                            style: const TextStyle(fontSize: 12)),
                        trailing: Text('₹${entry['amount'].toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold)),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('bulkInsertScreen.cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _executeUpdates(entries, totalAmount);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text('bulkInsertScreen.confirmUpdate'.tr(),
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _executeUpdates(
      List<Map<String, dynamic>> entries, double totalAmount) async {
    setState(() {
      isProcessing = true;
    });

    _showProcessingDialog(entries.length);

    try {
      final dateString = DateFormat('yyyy-MM-dd').format(selectedDate);
      List<Map<String, String>> smsQueue = [];
      int successCount = 0;

      for (var entry in entries) {
        try {
          final party = entry['party'];
          final amount = entry['amount'];
          final lenId = entry['lenId'];

          await CollectionScreen.updateLendingData(lenId, amount);
          await CollectionScreen.updateAmtRecieved(_selectedLineName!, amount);
          await CollectionScreen.insertCollection(lenId, amount, dateString);

          await _prepareSmsForParty(party, amount, smsQueue);

          final partyIndex =
              lendingDetails.indexWhere((p) => p['LenId'] == lenId);
          if (partyIndex != -1) {
            setState(() {
              lendingDetails[partyIndex]['amtcollected'] += amount;
              selectedParties[lenId] = false;
              amountControllers[lenId]?.clear();
            });
          }

          successCount++;
        } catch (e) {
          print('Error updating party ${entry['party']['PartyName']}: $e');
        }
      }

      Navigator.of(context).pop();

      if (smsQueue.isNotEmpty) {
        await _sendSmsSequentially(smsQueue);
      }

      _showSuccessDialog(successCount, totalAmount, smsQueue.length);
    } catch (e) {
      Navigator.of(context).pop();
      _showSnackBar(
          'bulkInsertScreen.updateFailed'.tr(namedArgs: {
            'error': e.toString(),
          }),
          Colors.red);
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  Future<void> _prepareSmsForParty(Map<String, dynamic> party, double amount,
      List<Map<String, String>> smsQueue) async {
    final int sms = party['sms'] ?? 0;
    final String phone = party['PartyPhnone'] ?? '';

    if (sms == 1 && phone.isNotEmpty && phone != 'Unknown') {
      final prefs = await SharedPreferences.getInstance();
      final financeName = prefs.getString('financeName') ?? '';
      final totalAmt = party['amtgiven'] + party['profit'];
      final newBalance = totalAmt - (party['amtcollected'] + amount);
      final dateForSms = DateFormat('dd-MM-yyyy').format(selectedDate);

      final smsMessage = 'bulkInsertScreen.smsPaymentReceived'.tr(namedArgs: {
        'date': dateForSms,
        'amount': amount.toStringAsFixed(2),
        'balance': newBalance.toStringAsFixed(2),
        'financeName': financeName,
      });

      smsQueue.add({
        'phone': phone,
        'message': smsMessage,
        'partyName': party['PartyName'] ?? 'Unknown',
      });
    }
  }

  Future<void> _sendSmsSequentially(List<Map<String, String>> smsQueue) async {
    for (int i = 0; i < smsQueue.length; i++) {
      if (!mounted) break;

      final smsData = smsQueue[i];
      bool? sendThis =
          await _showSmsConfirmationDialog(smsData, i + 1, smsQueue.length);

      if (sendThis == true) {
        try {
          await sendSms(smsData['phone']!, smsData['message']!);
          if (mounted) {
            _showSnackBar(
                'bulkInsertScreen.smsSent'.tr(namedArgs: {
                  'partyName': smsData['partyName']!,
                }),
                Colors.green);
          }
        } catch (e) {
          if (mounted) {
            _showSnackBar(
                'bulkInsertScreen.smsFailed'.tr(namedArgs: {
                  'partyName': smsData['partyName']!,
                }),
                Colors.red);
          }
        }
      } else if (sendThis == null) {
        break;
      }

      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  Future<bool?> _showSmsConfirmationDialog(
      Map<String, String> smsData, int current, int total) async {
    if (!mounted) return null;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('bulkInsertScreen.smsConfirmation'.tr(namedArgs: {
            'current': current.toString(),
            'total': total.toString(),
          })),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('bulkInsertScreen.party'.tr() + ' ${smsData['partyName']}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('bulkInsertScreen.phone'.tr() + ' ${smsData['phone']}'),
              const SizedBox(height: 8),
              Text('bulkInsertScreen.message'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(smsData['message'] ?? '',
                    style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text('bulkInsertScreen.cancelAll'.tr()),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('bulkInsertScreen.skip'.tr()),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text('bulkInsertScreen.sendSms'.tr(),
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showProcessingDialog(int count) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('bulkInsertScreen.processingCollections'.tr(namedArgs: {
                'count': count.toString(),
              })),
              Text('bulkInsertScreen.pleaseWait'.tr(),
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        );
      },
    );
  }

  void _showSuccessDialog(int count, double total, int smsCount) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('bulkInsertScreen.updateComplete'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('bulkInsertScreen.successfullyUpdated'.tr(namedArgs: {
                'count': count.toString(),
              })),
              Text('bulkInsertScreen.totalAmount'.tr(namedArgs: {
                'amount': total.toStringAsFixed(2),
              })),
              Text('bulkInsertScreen.smsProcessed'.tr(namedArgs: {
                'count': smsCount.toString(),
              })),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text('bulkInsertScreen.done'.tr(),
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: color),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal.shade900,
        elevation: 0,
        title: Text('bulkInsertScreen.addressWiseCollection'.tr(),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Header Controls
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'bulkInsertScreen.selectLine'.tr(),
                                border: const OutlineInputBorder(),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 10),
                              ),
                              value: _selectedLineName,
                              items: _lineNames
                                  .map((lineName) => DropdownMenuItem(
                                      value: lineName, child: Text(lineName)))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedLineName = value;
                                  // Clear existing data immediately to prevent showing old parties
                                  lendingDetails.clear();
                                  uniqueAddresses.clear();
                                  _selectedAddress = null;
                                  _resetData();
                                });
                                if (value != null) _loadPartyNames(value);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _dateController,
                              decoration: InputDecoration(
                                labelText: 'bulkInsertScreen.selectDate'.tr(),
                                border: const OutlineInputBorder(),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 10),
                                suffixIcon:
                                    const Icon(Icons.calendar_today, size: 12),
                              ),
                              readOnly: true,
                              onTap: _selectDate,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'bulkInsertScreen.selectAddress'.tr(),
                          border: const OutlineInputBorder(),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 10),
                          prefixIcon: const Icon(Icons.location_on, size: 18),
                        ),
                        value: _selectedAddress,
                        items: [
                          DropdownMenuItem(
                              value: null,
                              child:
                                  Text('bulkInsertScreen.allAddresses'.tr())),
                          ...uniqueAddresses
                              .map((address) => DropdownMenuItem(
                                  value: address,
                                  child: Text(address,
                                      overflow: TextOverflow.ellipsis)))
                              .toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedAddress = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      // Daily/Weekly Toggle
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.grey.shade50, Colors.grey.shade100],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.grey.shade300, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade200.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        height: 40,
                        child: Row(
                          children: [
                            Expanded(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeInOut,
                                height: 40,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(6),
                                      bottomLeft: Radius.circular(6),
                                    ),
                                    onTap: () {
                                      if (_isWeeklyView) {
                                        setState(() {
                                          _isWeeklyView = false;
                                        });
                                        _refreshAmountsForToggle();
                                      }
                                    },
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      curve: Curves.easeInOut,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                      decoration: BoxDecoration(
                                        gradient: !_isWeeklyView
                                            ? LinearGradient(
                                                colors: [
                                                  Colors.teal.shade700,
                                                  Colors.teal.shade800
                                                ],
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                              )
                                            : null,
                                        color: _isWeeklyView
                                            ? Colors.grey.shade100
                                            : null,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(6),
                                          bottomLeft: Radius.circular(6),
                                        ),
                                        border: Border.all(
                                          color: _isWeeklyView
                                              ? Colors.grey.shade300
                                              : Colors.transparent,
                                          width: 1,
                                        ),
                                        boxShadow: !_isWeeklyView
                                            ? [
                                                BoxShadow(
                                                  color: Colors.teal.shade800
                                                      .withOpacity(0.2),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            size: 16,
                                            color: !_isWeeklyView
                                                ? Colors.white
                                                : Colors.grey.shade600,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'bulkInsertScreen.dailyView'.tr(),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: !_isWeeklyView
                                                  ? Colors.white
                                                  : Colors.grey.shade700,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 1),
                            Expanded(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeInOut,
                                height: 40,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: const BorderRadius.only(
                                      topRight: Radius.circular(6),
                                      bottomRight: Radius.circular(6),
                                    ),
                                    onTap: () {
                                      if (!_isWeeklyView) {
                                        setState(() {
                                          _isWeeklyView = true;
                                        });
                                        _refreshAmountsForToggle();
                                      }
                                    },
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      curve: Curves.easeInOut,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                      decoration: BoxDecoration(
                                        gradient: _isWeeklyView
                                            ? LinearGradient(
                                                colors: [
                                                  Colors.teal.shade700,
                                                  Colors.teal.shade800
                                                ],
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                              )
                                            : null,
                                        color: !_isWeeklyView
                                            ? Colors.grey.shade100
                                            : null,
                                        borderRadius: const BorderRadius.only(
                                          topRight: Radius.circular(6),
                                          bottomRight: Radius.circular(6),
                                        ),
                                        border: Border.all(
                                          color: !_isWeeklyView
                                              ? Colors.grey.shade300
                                              : Colors.transparent,
                                          width: 1,
                                        ),
                                        boxShadow: _isWeeklyView
                                            ? [
                                                BoxShadow(
                                                  color: Colors.teal.shade800
                                                      .withOpacity(0.2),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.view_week,
                                            size: 16,
                                            color: _isWeeklyView
                                                ? Colors.white
                                                : Colors.grey.shade600,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'bulkInsertScreen.weeklyView'.tr(),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: _isWeeklyView
                                                  ? Colors.white
                                                  : Colors.grey.shade700,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Party List
              Expanded(
                child: filteredLendingDetails.isEmpty
                    ? Center(
                        child: Text(
                          'bulkInsertScreen.noPartiesFoundWithAddress'.tr(),
                          textAlign: TextAlign.center,
                          style:
                              const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredLendingDetails.length,
                        itemBuilder: (context, index) {
                          final detail = filteredLendingDetails[index];
                          final lenId = detail['LenId'];
                          final balanceAmt =
                              (detail['amtgiven'] + detail['profit']) -
                                  detail['amtcollected'];
                          final isSelected = selectedParties[lenId] ?? false;

                          return Card(
                            color: isSelected
                                ? Colors.teal.shade50
                                : (hasCollectionToday[lenId] == true
                                    ? Colors.orange.shade100
                                    : null),
                            child: ListTile(
                              leading: Checkbox(
                                value: isSelected,
                                onChanged: (value) =>
                                    _togglePartySelection(lenId),
                              ),
                              title: Text(detail['PartyName'] ?? 'Unknown',
                                  style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal)),
                              subtitle: Text(
                                  '${'bulkInsertScreen.balance'.tr()}: ₹${balanceAmt.toStringAsFixed(2)}'),
                              trailing: SizedBox(
                                width: 80,
                                child: TextFormField(
                                  controller: amountControllers[lenId],
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d{0,2}'))
                                  ],
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                        vertical: 6, horizontal: 6),
                                    border: OutlineInputBorder(),
                                  ),
                                  onTap: () {
                                    amountControllers[lenId]?.clear();
                                    if (!isSelected) {
                                      _togglePartySelection(lenId);
                                    }
                                  },
                                  onChanged: (value) {
                                    if (value.isNotEmpty && !isSelected) {
                                      _togglePartySelection(lenId);
                                    }
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Bottom Panel
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            '${'bulkInsertScreen.selected'.tr()}: ${selectedParties.values.where((selected) => selected).length}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                            '${'bulkInsertScreen.total'.tr()}: ₹${_calculateTotalSelected().toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: isProcessing ? null : _processBulkUpdate,
                        icon: isProcessing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.upload_file,
                                color: Colors.white),
                        label: Text(
                            isProcessing
                                ? 'bulkInsertScreen.processing'.tr()
                                : 'bulkInsertScreen.bulkUpdateSms'.tr(),
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isProcessing ? Colors.grey : Colors.green,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
