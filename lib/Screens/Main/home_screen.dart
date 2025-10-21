import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kskfinance/Data/Databasehelper.dart';
import 'package:kskfinance/Screens/Main/LineScreen.dart';
import 'package:kskfinance/Utilities/AppBar.dart';
import 'package:kskfinance/Utilities/drawer.dart';
import 'package:kskfinance/Utilities/FloatingActionButtonWithText.dart';
import 'package:kskfinance/Widgets/HomeScreenComponents/home_screen_components.dart';
import '../../finance_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  _ModernDashboardState createState() => _ModernDashboardState();
}

class _ModernDashboardState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<String> lineNames = [];
  List<String> originalLineNames = [];
  double totalAmtGiven = 0.0;
  double totalProfit = 0.0;
  double totalAmtRecieved = 0.0;
  Map<String, Map<String, dynamic>> lineDetailsMap = {};
  double todaysTotalDrAmt = 0.0;
  double todaysTotalCrAmt = 0.0;
  double totalexpense = 0.0;
  DateTime selectedDate = DateTime.now();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    loadData();
    _animationController.forward();

    Future.delayed(const Duration(seconds: 3), () {
      BackupSupportDialogs.checkDailyBackup(context);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    try {
      await Future.wait([
        loadLineNames(),
        loadLineDetails(),
        loadCollectionAndGivenByDate(selectedDate),
      ]);
    } catch (e) {
      debugPrint('Error loading data: $e');
      // Handle error gracefully without breaking the UI
    }
  }

  Future<void> loadLineNames() async {
    final names = await dbline.getLineNames();
    if (names.isEmpty) {
      setState(() {
        originalLineNames = [];
        lineNames = [];
        lineDetailsMap = {};
      });
      return;
    }

    // Process database calls more efficiently
    final details = await Future.wait(
      names.map((name) => dbline.getLineDetails(name)),
      eagerError: true,
    );

    if (mounted) {
      setState(() {
        originalLineNames = names;
        lineNames = names;
        lineDetailsMap = <String, Map<String, dynamic>>{};
        for (int i = 0; i < names.length; i++) {
          lineDetailsMap[names[i]] = details[i];
        }
      });
    }
  }

  Future<void> loadLineDetails() async {
    final details = await dbline.allLineDetails();
    if (mounted) {
      setState(() {
        totalAmtGiven = details['totalAmtGiven'] ?? 0.0;
        totalProfit = details['totalProfit'] ?? 0.0;
        totalAmtRecieved = details['totalAmtRecieved'] ?? 0.0;
        totalexpense = details['totalexpense'] ?? 0.0;
      });
    }
  }

  Future<void> loadCollectionAndGivenByDate(DateTime date) async {
    String queryDate = DateFormat('yyyy-MM-dd').format(date);
    final result = await CollectionDB.getCollectionAndGivenByDate(queryDate);
    if (mounted) {
      setState(() {
        todaysTotalDrAmt = result['totalDrAmt'] ?? 0.0;
        todaysTotalCrAmt = result['totalCrAmt'] ?? 0.0;
      });
    }
  }

  void _handleDateChanged(DateTime newDate) {
    setState(() {
      selectedDate = newDate;
    });
    loadCollectionAndGivenByDate(newDate);
  }

  void _handleSearchResults(List<String> results) {
    setState(() {
      lineNames = results;
    });
  }

  void _showCollectionTypeDialog() {
    CollectionTypeDialog.show(context);
  }

  void _showUpdateFinanceNameDialog(BuildContext context) {
    final TextEditingController financeNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Your Name'),
          content: TextField(
            controller: financeNameController,
            decoration: const InputDecoration(hintText: 'Enter Your Name'),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Update'),
              onPressed: () async {
                final newFinanceName = financeNameController.text;
                if (newFinanceName.isNotEmpty) {
                  await ref
                      .read(financeProvider.notifier)
                      .saveFinanceName(newFinanceName);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final financeName = ref.watch(financeProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CustomAppBar(
        title: financeName,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_outlined),
            onPressed: () => _showUpdateFinanceNameDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => loadData(),
          ),
        ],
      ),
      drawer: buildDrawer(context),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            child: Column(
              children: [
                FinancialOverviewCard(
                  totalAmtGiven: totalAmtGiven,
                  totalProfit: totalProfit,
                  totalAmtRecieved: totalAmtRecieved,
                ),
                DailyActivityCard(
                  selectedDate: selectedDate,
                  todaysTotalDrAmt: todaysTotalDrAmt,
                  todaysTotalCrAmt: todaysTotalCrAmt,
                  onDateChanged: _handleDateChanged,
                ),
                QuickActionsCard(
                  onCollectionEntryTap: _showCollectionTypeDialog,
                ),
                const SizedBox(height: 10),
                LineSearchBar(
                  originalLineNames: originalLineNames,
                  onSearchResults: _handleSearchResults,
                ),
                const SizedBox(height: 10),
                LinesList(
                  lineNames: lineNames,
                  lineDetailsMap: lineDetailsMap,
                  onDataChanged: loadData,
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: const FloatingActionButtonWithText(
        label: 'Add New Line',
        navigateTo: LineScreen(),
        icon: Icons.add,
      ),
    );
  }
}
