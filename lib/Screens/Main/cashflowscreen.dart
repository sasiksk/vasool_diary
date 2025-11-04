import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../Data/Databasehelper.dart';

class CashFlowScreen extends StatefulWidget {
  const CashFlowScreen({super.key});

  @override
  State<CashFlowScreen> createState() => _CashFlowScreenState();
}

class _CashFlowScreenState extends State<CashFlowScreen> {
  List<Map<String, dynamic>> _cashFlowEntries = [];
  bool _isLoading = false;
  int _filterType = 0; // 0: Month, 1: Date Range
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _showSummary = false;

  // Summary variables
  double _totalOpeningBalance = 0.0;
  double _totalCashIn = 0.0;
  double _totalCashOut = 0.0;
  double _totalProfit = 0.0;
  double _totalExpense = 0.0;
  double _totalClosingBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCashFlowData();
  }

  Future<void> _loadCashFlowData() async {
    setState(() => _isLoading = true);
    try {
      List<Map<String, dynamic>> data;
      if (_fromDate != null && _toDate != null) {
        data = await CashFlowDatabaseHelper.getCashFlowByDateRange(
            _fromDate!, _toDate!);
      } else {
        data = await CashFlowDatabaseHelper.getAllCashFlow();
      }
      setState(() {
        _cashFlowEntries = data;
        _calculateSummary();
      });
    } catch (e) {
      _showSnackBar('Error loading data: $e', true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _calculateSummary() {
    _totalOpeningBalance = 0.0;
    _totalCashIn = 0.0;
    _totalCashOut = 0.0;
    _totalProfit = 0.0;
    _totalExpense = 0.0;
    _totalClosingBalance = 0.0;

    for (var entry in _cashFlowEntries) {
      _totalOpeningBalance +=
          (entry['OpeningBalance'] as num?)?.toDouble() ?? 0.0;
      _totalCashIn += (entry['CashIn'] as num?)?.toDouble() ?? 0.0;
      _totalCashOut += (entry['CashOut'] as num?)?.toDouble() ?? 0.0;
      _totalProfit += (entry['Profit'] as num?)?.toDouble() ?? 0.0;
      _totalExpense += (entry['Expense'] as num?)?.toDouble() ?? 0.0;
      _totalClosingBalance +=
          (entry['ClosingBalance'] as num?)?.toDouble() ?? 0.0;
    }
  }

  Future<void> _selectMonth() async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select Month',
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );

    if (selectedDate != null) {
      setState(() {
        _fromDate = DateTime(selectedDate.year, selectedDate.month, 1);
        _toDate = DateTime(selectedDate.year, selectedDate.month + 1, 0);
      });
      await _loadCashFlowData();
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? selectedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
    );

    if (selectedRange != null) {
      setState(() {
        _fromDate = selectedRange.start;
        _toDate = selectedRange.end;
      });
      await _loadCashFlowData();
    }
  }

  void _clearFilters() {
    setState(() {
      _fromDate = null;
      _toDate = null;
    });
    _loadCashFlowData();
  }

  void _showSnackBar(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _formatCurrency(double amount) => '₹${amount.toStringAsFixed(2)}';
  String _formatDate(String dateStr) {
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(dateStr));
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cash Flow', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Toggle Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _FilterToggle(
                          text: 'Select Month',
                          isSelected: _filterType == 0,
                          onTap: () => setState(() => _filterType = 0),
                        ),
                      ),
                      Expanded(
                        child: _FilterToggle(
                          text: 'Date Range',
                          isSelected: _filterType == 1,
                          onTap: () => setState(() => _filterType = 1),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Filter Button
                ElevatedButton.icon(
                  onPressed: _filterType == 0 ? _selectMonth : _selectDateRange,
                  icon: Icon(_filterType == 0
                      ? Icons.calendar_month
                      : Icons.date_range),
                  label: Text(
                      _filterType == 0 ? 'Select Month' : 'Select Date Range'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),

                // Selected Date Range
                if (_fromDate != null && _toDate != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.date_range,
                            color: Colors.blue.shade600, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${_formatDate(_fromDate!.toIso8601String())} - ${_formatDate(_toDate!.toIso8601String())}',
                            style: TextStyle(color: Colors.blue.shade800),
                          ),
                        ),
                        IconButton(
                          onPressed: _clearFilters,
                          icon: Icon(Icons.clear, color: Colors.blue.shade600),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Summary Card (Collapsible)
          GestureDetector(
            onTap: () => setState(() => _showSummary = !_showSummary),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Summary',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      Icon(_showSummary ? Icons.expand_less : Icons.expand_more,
                          color: Colors.white),
                    ],
                  ),
                  if (_showSummary) ...[
                    const SizedBox(height: 16),
                    _buildSummaryGrid(),
                  ],
                ],
              ),
            ),
          ),

          // Cash Flow List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _cashFlowEntries.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _cashFlowEntries.length,
                        itemBuilder: (context, index) =>
                            _buildCashFlowCard(_cashFlowEntries[index]),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCashFlowDialog,
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryGrid() {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(1),
      },
      children: [
        TableRow(children: [
          _buildSummaryItem(
              'Opening Balance', _totalOpeningBalance, Colors.blue.shade200),
          _buildSummaryItem('Cash In', _totalCashIn, Colors.green.shade200),
        ]),
        TableRow(children: [
          _buildSummaryItem('Cash Out', _totalCashOut, Colors.red.shade200),
          _buildSummaryItem('Profit', _totalProfit, Colors.orange.shade200),
        ]),
        TableRow(children: [
          _buildSummaryItem('Expense', _totalExpense, Colors.purple.shade200),
          _buildSummaryItem(
              'Closing Balance', _totalClosingBalance, Colors.teal.shade200),
        ]),
      ],
    );
  }

  Widget _buildSummaryItem(String title, double amount, Color color) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(_formatCurrency(amount),
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet,
              size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No Cash Flow Records',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            _fromDate != null
                ? 'No records for selected dates'
                : 'Add your first entry',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildCashFlowCard(Map<String, dynamic> entry) {
    final date = _formatDate(entry['Date']);
    final openingBalance = (entry['OpeningBalance'] as num?)?.toDouble() ?? 0.0;
    final cashIn = (entry['CashIn'] as num?)?.toDouble() ?? 0.0;
    final cashOut = (entry['CashOut'] as num?)?.toDouble() ?? 0.0;
    final profit = (entry['Profit'] as num?)?.toDouble() ?? 0.0;
    final expense = (entry['Expense'] as num?)?.toDouble() ?? 0.0;
    final closingBalance = (entry['ClosingBalance'] as num?)?.toDouble() ?? 0.0;

    return GestureDetector(
      onTap: () => _showEditCashFlowDialog(entry),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Header
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      date,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                  Icon(Icons.edit, color: Colors.grey.shade500, size: 18),
                ],
              ),
              const SizedBox(height: 12),

              // Financial Data Grid - 3 rows with all fields
              Row(
                children: [
                  Expanded(
                      child: _buildCardItem(
                          'Opening',
                          _formatCurrency(openingBalance),
                          Colors.blue.shade700)),
                  Expanded(
                      child: _buildCardItem('Cash In', _formatCurrency(cashIn),
                          Colors.green.shade700)),
                  Expanded(
                      child: _buildCardItem('Cash Out',
                          _formatCurrency(cashOut), Colors.red.shade700)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                      child: _buildCardItem('Profit', _formatCurrency(profit),
                          Colors.orange.shade700)),
                  Expanded(
                      child: _buildCardItem('Expense', _formatCurrency(expense),
                          Colors.purple.shade700)),
                  Expanded(
                      child: _buildCardItem(
                          'Closing',
                          _formatCurrency(closingBalance),
                          Colors.teal.shade700)),
                ],
              ),
              const SizedBox(height: 8),

              // Net Flow Row
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Closing Balance :',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        )),
                    Text(_formatCurrency(cashIn - cashOut + profit - expense),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: (cashIn - cashOut + profit - expense) >= 0
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardItem(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Simplified Add/Edit Dialogs
  void _showAddCashFlowDialog() {
    _showCashFlowDialog(null);
  }

  void _showEditCashFlowDialog(Map<String, dynamic> entry) {
    _showCashFlowDialog(entry);
  }

  void _showCashFlowDialog(Map<String, dynamic>? existingEntry) {
    final isEdit = existingEntry != null;
    final controllers = _CashFlowControllers(existingEntry);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    isEdit ? Icons.edit : Icons.add_circle,
                    color: Colors.blue.shade700,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEdit ? 'Edit Cash Flow' : 'Add Cash Flow',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Form Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Date Field
                      _buildAttractiveFormField(
                        controllers.date,
                        'Date',
                        Icons.calendar_today,
                        Colors.blue.shade600,
                        readOnly: true,
                        onTap: () => _pickDate(controllers.date),
                      ),
                      const SizedBox(height: 16),

                      // Opening Balance
                      _buildAttractiveFormField(
                        controllers.openingBalance,
                        'Opening Balance',
                        Icons.account_balance_wallet,
                        Colors.blue.shade600,
                      ),
                      const SizedBox(height: 16),

                      // Cash In & Cash Out Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildAttractiveFormField(
                              controllers.cashIn,
                              'Cash In',
                              Icons.trending_up,
                              Colors.green.shade600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildAttractiveFormField(
                              controllers.cashOut,
                              'Cash Out',
                              Icons.trending_down,
                              Colors.red.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Profit & Expense Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildAttractiveFormField(
                              controllers.profit,
                              'Profit',
                              Icons.attach_money,
                              Colors.orange.shade600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildAttractiveFormField(
                              controllers.expense,
                              'Expense',
                              Icons.money_off,
                              Colors.purple.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Auto-calculated Closing Balance
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade50, Colors.blue.shade100],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calculate,
                                color: Colors.blue.shade700, size: 24),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Closing Balance',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                                Text(
                                  'Auto-calculated from your entries',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (isEdit)
                    ElevatedButton.icon(
                      onPressed: () => _deleteEntry(existingEntry['Date']),
                      icon: const Icon(Icons.delete, size: 20),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => _saveEntry(controllers, isEdit),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      isEdit ? 'Update' : 'Save',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttractiveFormField(
    TextEditingController controller,
    String label,
    IconData icon,
    Color color, {
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500),
        prefixIcon: Icon(icon, color: color),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    );
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(date);
    }
  }

  Future<void> _saveEntry(_CashFlowControllers controllers, bool isEdit) async {
    try {
      final closingBalance = double.parse(controllers.openingBalance.text) +
          double.parse(controllers.cashIn.text) -
          double.parse(controllers.cashOut.text) +
          double.parse(controllers.profit.text) -
          double.parse(controllers.expense.text);

      if (isEdit) {
        await CashFlowDatabaseHelper.updateCashFlow(
          date: controllers.date.text,
          openingBalance: double.parse(controllers.openingBalance.text),
          cashIn: double.parse(controllers.cashIn.text),
          cashOut: double.parse(controllers.cashOut.text),
          profit: double.parse(controllers.profit.text),
          expense: double.parse(controllers.expense.text),
          closingBalance: closingBalance,
        );
      } else {
        await CashFlowDatabaseHelper.insertCashFlow(
          date: controllers.date.text,
          openingBalance: double.parse(controllers.openingBalance.text),
          cashIn: double.parse(controllers.cashIn.text),
          cashOut: double.parse(controllers.cashOut.text),
          profit: double.parse(controllers.profit.text),
          expense: double.parse(controllers.expense.text),
          closingBalance: closingBalance,
        );
      }

      _showSnackBar(
          'Entry ${isEdit ? 'updated' : 'added'} successfully!', false);
      if (context.mounted) Navigator.pop(context);
      await _loadCashFlowData();
    } catch (e) {
      _showSnackBar('Error saving entry: $e', true);
    }
  }

  Future<void> _deleteEntry(String date) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: Text('Delete entry for $date?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await CashFlowDatabaseHelper.deleteCashFlow(date);
        _showSnackBar('Entry deleted!', false);
        if (context.mounted) Navigator.pop(context);
        await _loadCashFlowData();
      } catch (e) {
        _showSnackBar('Error deleting entry: $e', true);
      }
    }
  }
}

class _FilterToggle extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterToggle(
      {required this.text, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade700 : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.blue.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _CashFlowControllers {
  final TextEditingController date = TextEditingController();
  final TextEditingController openingBalance = TextEditingController();
  final TextEditingController cashIn = TextEditingController();
  final TextEditingController cashOut = TextEditingController();
  final TextEditingController profit = TextEditingController();
  final TextEditingController expense = TextEditingController();

  _CashFlowControllers(Map<String, dynamic>? existingEntry) {
    if (existingEntry != null) {
      date.text = existingEntry['Date'] ?? '';
      openingBalance.text =
          (existingEntry['OpeningBalance'] as num?)?.toString() ?? '0.0';
      cashIn.text = (existingEntry['CashIn'] as num?)?.toString() ?? '0.0';
      cashOut.text = (existingEntry['CashOut'] as num?)?.toString() ?? '0.0';
      profit.text = (existingEntry['Profit'] as num?)?.toString() ?? '0.0';
      expense.text = (existingEntry['Expense'] as num?)?.toString() ?? '0.0';
    } else {
      date.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
      openingBalance.text = '0.0';
      cashIn.text = '0.0';
      cashOut.text = '0.0';
      profit.text = '0.0';
      expense.text = '0.0';
    }
  }
}
