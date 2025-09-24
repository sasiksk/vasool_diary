import 'package:flutter/material.dart';
import 'package:kskfinance/Data/Databasehelper.dart';
import 'package:kskfinance/Screens/Main/CollectionScreen.dart';
import 'package:intl/intl.dart';

class BulkInsertScreen extends StatefulWidget {
  const BulkInsertScreen({super.key});

  @override
  _BulkInsertScreenState createState() => _BulkInsertScreenState();
}

class _BulkInsertScreenState extends State<BulkInsertScreen> {
  List<String> _lineNames = [];
  String? _selectedLineName;
  List<String> _partyNames = [];
  List<Map<String, dynamic>> lendingDetails = [];
  List<bool> _isCheckedList = [];
  List<TextEditingController> _amountControllers = [];
  DateTime selectedDate = DateTime.now();
  final TextEditingController _dateController = TextEditingController(
    text: DateFormat('dd-MM-yyyy').format(DateTime.now()),
  );
  double totalAmount = 0.0;

  @override
  void initState() {
    super.initState();

    _loadLineNames();
  }

  Future<void> showSmsNotSentDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Notice'),
          content: const Text('SMS can\'t be sent through this entry.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadLineNames() async {
    final lineNames = await dbline.getLineNames();
    setState(() {
      _lineNames = lineNames;
      showSmsNotSentDialog();
    });
  }

  Future<void> _loadPartyNames(String lineName) async {
    final details = await dbLending.getLendingDetailsByLineName(lineName);
    if (details != null) {
      setState(() {
        lendingDetails = details;
        _partyNames = lendingDetails.map((detail) {
          final balanceAmt =
              (detail['amtgiven'] + detail['profit']) - detail['amtcollected'];
          return '${detail['PartyName']}';
        }).toList();
        _isCheckedList = List<bool>.filled(_partyNames.length, false);
        _amountControllers = lendingDetails.map((detail) {
          final perDayAmt =
              (detail['amtgiven'] + detail['profit']) / detail['duedays'];
          return TextEditingController(text: perDayAmt.toStringAsFixed(2));
        }).toList();
      });
    } else {
      setState(() {
        lendingDetails = [];
        _partyNames = [];
        _isCheckedList = [];
        _amountControllers = [];
      });
    }
  }

  void _updateSelectedPartyNamesAndAmounts() async {
    for (int i = 0; i < _partyNames.length; i++) {
      if (_isCheckedList[i]) {
        final lenId = lendingDetails[i]['LenId'];
        final collectedAmt = double.parse(_amountControllers[i].text);
        await CollectionScreen.updateLendingData(lenId, collectedAmt);
        await CollectionScreen.updateAmtRecieved(
            _selectedLineName!, collectedAmt);
        await CollectionScreen.insertCollection(
            lenId, collectedAmt, DateFormat('yyyy-MM-dd').format(selectedDate));
      }
    }

    // Show success alert dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: const Text('Successfully updated.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _updateTotalAmount() {
    setState(() {
      totalAmount = 0.0;
      for (int i = 0; i < _partyNames.length; i++) {
        if (_isCheckedList[i]) {
          totalAmount += double.tryParse(_amountControllers[i].text) ?? 0.0;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Insert'),
        backgroundColor: Colors.teal.shade900,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Bulk Entry Screen',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16.0),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Choose Your Line Name',
                border: OutlineInputBorder(),
                isDense: true, // Reduce height
                contentPadding: EdgeInsets.symmetric(
                    vertical: 8, horizontal: 10), // Reduce padding
              ),
              value: _selectedLineName,
              items: _lineNames.map((lineName) {
                return DropdownMenuItem<String>(
                  value: lineName,
                  child: Text(
                    lineName,
                    style: const TextStyle(fontSize: 14), // Reduce font size
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedLineName = value;
                  _loadPartyNames(value!);
                });
              },
              selectedItemBuilder: (BuildContext context) {
                return _lineNames.map<Widget>((String lineName) {
                  return Text(
                    _selectedLineName ?? 'Choose Your Line Name',
                    style: const TextStyle(
                      fontSize: 14, // Reduce font size
                      color: Colors.black,
                    ),
                  );
                }).toList();
              },
            ),
            const SizedBox(height: 8.0), // Reduce spacing
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Pick Date Field
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _dateController,
                    decoration: const InputDecoration(
                      labelText: 'Pick Date',
                      hintText: 'Select a date',
                      border: OutlineInputBorder(),
                      isDense: true, // Reduce height
                      contentPadding: EdgeInsets.symmetric(
                          vertical: 8, horizontal: 10), // Reduce padding
                      suffixIcon: Icon(Icons.calendar_today,
                          size: 18), // Reduce icon size
                    ),
                    style: const TextStyle(fontSize: 14), // Reduce font size
                    readOnly: true,
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          selectedDate = pickedDate;
                          _dateController.text =
                              DateFormat('yyyy-MM-dd').format(pickedDate);
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16.0), // Add spacing between the fields

                // Total Amount Display
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Total: ₹${totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),

            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Colors.grey,
                          width: 1), // Add border color and width
                      borderRadius: BorderRadius.circular(
                          8), // Optional: Add rounded corners
                    ),
                    child: DataTable(
                      columnSpacing: 15.0, // Adjust the spacing between columns
                      columns: const [
                        DataColumn(
                          label: Icon(Icons.check, size: 18),
                        ),
                        DataColumn(
                          label: SizedBox(
                            width: 90,
                            child: Text('Party Name',
                                style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        DataColumn(
                          label: SizedBox(
                            width: 70,
                            child: Text('Balance Amt',
                                style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        DataColumn(
                          label: SizedBox(
                            width: 70,
                            child:
                                Text('Amount', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                      rows: List<DataRow>.generate(
                        _partyNames.length,
                        (index) {
                          final detail = lendingDetails[index];
                          final balanceAmt =
                              (detail['amtgiven'] + detail['profit']) -
                                  detail['amtcollected'];
                          final partyName = detail['PartyName'] ?? '';
                          return DataRow(
                            cells: [
                              // 1. Tick icon (always visible)
                              DataCell(
                                IconButton(
                                  icon: Icon(
                                    Icons.check_circle,
                                    size: 28,
                                    color: _isCheckedList[index]
                                        ? Colors.blue
                                        : Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isCheckedList[index] =
                                          !_isCheckedList[index];
                                      _updateTotalAmount();
                                    });
                                  },
                                ),
                              ),
                              // 2. Party Name (wrap if too long)
                              DataCell(
                                SizedBox(
                                  width: 90,
                                  child: Text(
                                    partyName,
                                    style: const TextStyle(fontSize: 12),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: true,
                                  ),
                                ),
                              ),
                              // 3. Balance Amt
                              DataCell(
                                Text(
                                  balanceAmt.toStringAsFixed(2),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              // 4. Amount entry (auto-select tick on change)
                              DataCell(
                                SizedBox(
                                  width: 70,
                                  child: TextFormField(
                                    controller: _amountControllers[index],
                                    style: const TextStyle(fontSize: 12),
                                    keyboardType: TextInputType.number,
                                    onTap: () {
                                      _amountControllers[index].clear();
                                    },
                                    onChanged: (value) {
                                      setState(() {
                                        _isCheckedList[index] = true;
                                        _updateTotalAmount();
                                      });
                                    },
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                          vertical: 6, horizontal: 6),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      )..add(
                          DataRow(
                            cells: [
                              const DataCell(Text('')), // Empty for tick
                              const DataCell(Text('Total',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold))),
                              const DataCell(Text('',
                                  style:
                                      TextStyle(fontSize: 12))), // Empty cell
                              DataCell(Text(totalAmount.toStringAsFixed(2),
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple))),
                            ],
                          ),
                        ),
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: ElevatedButton(
                onPressed: _updateSelectedPartyNamesAndAmounts,
                child: const Text('Update Selected'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
