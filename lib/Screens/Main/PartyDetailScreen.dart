import 'package:kskfinance/Utilities/Reports/CusFullTrans/ReportScreen2.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:kskfinance/Screens/Main/CollectionScreen.dart';
import 'package:kskfinance/Data/Databasehelper.dart';
import 'package:kskfinance/Screens/Main/LendingScreen.dart';

import 'package:kskfinance/Utilities/EmptyCard1.dart';

import 'package:kskfinance/Screens/Main/lendingScreen2.dart';
import 'package:kskfinance/Screens/Main/linedetailScreen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kskfinance/Utilities/premium_utils.dart';

import '../../finance_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class PartyDetailScreen extends ConsumerStatefulWidget {
  const PartyDetailScreen({super.key});

  @override
  _PartyDetailScreenState createState() => _PartyDetailScreenState();

  static Future<void> deleteEntry(BuildContext context, int cid,
      String linename, double drAmt, int lenId, String partyName) async {
    await CollectionDB.deleteEntry(cid);
    final lendingData = await dbLending.fetchLendingData(lenId);
    final amtrecievedLine = await dbline.fetchAmtRecieved(linename);
    final newamtrecived = amtrecievedLine + -drAmt;
    await dbline.updateLine(
      lineName: linename,
      updatedValues: {'Amtrecieved': newamtrecived},
    );

    final double currentAmtCollected = lendingData['amtcollected'];
    final double newAmtCollected = currentAmtCollected - drAmt;
    const String status = 'active';

    final updatedValues = {'amtcollected': newAmtCollected, 'status': status};
    await dbLending.updateAmtCollectedAndGiven(
      lineName: linename,
      partyName: partyName,
      lenId: lenId,
      updatedValues: updatedValues,
    );

    // Navigator.of(context).pop(); // Close the confirmation dialog
    // Close the options dialog
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const PartyDetailScreen(),
      ),
    );
  }
}

class _PartyDetailScreenState extends ConsumerState<PartyDetailScreen> {
  bool _isWeeklyView = false; // Local toggle state for weekly/daily view

  void _showActionMenuDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choose Action'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.add, color: Colors.purple),
                title: Text('You Gave'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final canProceed =
                      await PremiumUtils.checkPremiumForOperation(
                    context,
                    operationName: 'You Gave',
                  );
                  if (canProceed) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LendingCombinedDetailsScreen2(),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading:
                    Icon(Icons.picture_as_pdf_outlined, color: Colors.brown),
                title: Text('Report'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ReportScreen2(lenId: ref.watch(lenIdProvider)!),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.add, color: Colors.green),
                title: Text('You Got'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final canProceed =
                      await PremiumUtils.checkPremiumForOperation(
                    context,
                    operationName: 'You Got',
                  );
                  if (canProceed) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CollectionScreen(),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color,
      {String? additionalInfo}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: GoogleFonts.tinos(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: GoogleFonts.tinos(
            fontSize: 15,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (additionalInfo != null) // Display additional info in the next row
          Text(
            additionalInfo,
            style: GoogleFonts.tinos(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
            ),
          ),
      ],
    );
  }

  Future<String?> fetchPartyPhoneNumber(int lenId) async {
    try {
      final lendingData = await dbLending.fetchLendingData(lenId);
      return lendingData[
          'PartyPhnone']; // Ensure the column name matches your database
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('partyDetailScreen.errorFetchingPhone'.tr())),
      );
      return null;
    }
  }

  Future<void> makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('partyDetailScreen.couldNotLaunchDialer'.tr())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final linename = ref.watch(currentLineNameProvider);
    final partyName = ref.watch(currentPartyNameProvider);
    final lenId = ref.watch(lenIdProvider);
    final status = ref.watch(lenStatusProvider);
    final finname = ref.watch(financeNameProvider);
    double amt;

    return Scaffold(
      appBar: AppBar(
        title: Text(partyName ?? 'partyDetailScreen.title'.tr()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const LineDetailScreen(),
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_in_talk_outlined), // Call icon
            onPressed: () async {
              if (lenId != null) {
                final phoneNumber = await fetchPartyPhoneNumber(lenId);
                if (phoneNumber != null && phoneNumber.isNotEmpty) {
                  makePhoneCall(phoneNumber);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('partyDetailScreen.phoneNotAvailable'.tr())),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text('partyDetailScreen.invalidPartyDetails'.tr())),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Center(
            child: EmptyCard1(
              screenHeight: MediaQuery.of(context).size.height * 1.50,
              screenWidth: MediaQuery.of(context).size.width,
              title: 'partyDetailScreen.partyDetails'.tr(),
              content: Consumer(
                builder: (context, ref, child) {
                  final lenId = ref.watch(lenIdProvider);
                  return FutureBuilder<Map<String, dynamic>>(
                    future: dbLending.getPartySums(lenId!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData) {
                        return const Center(child: Text('No data found.'));
                      } else {
                        final data = snapshot.data!;
                        final convdate =
                            DateFormat('mm-dd-yyyy').parse(data['lentdate']);

                        final daysover = data['lentdate'].isNotEmpty
                            ? DateTime.now()
                                .difference(DateFormat('yyyy-MM-dd')
                                    .parse(data['lentdate']))
                                .inDays
                            : null;

                        final formattedDaysover = daysover != null
                            ? DateFormat('dd-MM-yyyy').format(DateTime.now()
                                .subtract(Duration(days: daysover)))
                            : null;
                        final daysrem =
                            data['duedays'] != null && daysover != null
                                ? data['duedays'] - daysover
                                : 0.0;

                        final duedate = data['lentdate'] != null &&
                                data['lentdate'].isNotEmpty
                            ? DateFormat('yyyy-MM-dd')
                                .parse(data['lentdate'])
                                .add(Duration(days: data['duedays']))
                                .toString()
                            : null;

                        final perrday = (data['totalAmtGiven'] != null &&
                                data['totalProfit'] != null &&
                                data['duedays'] != null &&
                                data['duedays'] != 0)
                            ? (data['totalAmtGiven'] + data['totalProfit']) /
                                data['duedays']
                            : 0.0;

                        final totalAmtCollected =
                            data['totalAmtCollected'] ?? 0.0;
                        final givendays =
                            perrday != 0 ? totalAmtCollected / perrday : 0.0;
                        double pendays;
                        if (daysrem > 0) {
                          pendays = ((daysover ?? 0) - givendays).toDouble();
                        } else {
                          pendays =
                              ((data['duedays'] ?? 0) - givendays).toDouble();
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Day View / Week View Toggle
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isWeeklyView = false;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: !_isWeeklyView
                                            ? Colors.blue
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'partyDetailScreen.dayView'.tr(),
                                        style: TextStyle(
                                          color: !_isWeeklyView
                                              ? Colors.white
                                              : Colors.black54,
                                          fontWeight: !_isWeeklyView
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isWeeklyView = true;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: _isWeeklyView
                                            ? Colors.blue
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'partyDetailScreen.weekView'.tr(),
                                        style: TextStyle(
                                          color: _isWeeklyView
                                              ? Colors.white
                                              : Colors.black54,
                                          fontWeight: _isWeeklyView
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'partyDetailScreen.totalGiven'.tr(),
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900),
                                    ),
                                    Text(
                                      '₹${(data['totalAmtGiven'] ?? 0.0) + (data['totalProfit'] ?? 0.0)}',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'partyDetailScreen.collected'.tr(),
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900),
                                    ),
                                    Text(
                                      '₹${data['totalAmtCollected']?.toStringAsFixed(2) ?? '0.00'}',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'partyDetailScreen.pending'.tr(),
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900),
                                    ),
                                    Text(
                                      '₹${(data['totalAmtGiven'] ?? 0.0) + (data['totalProfit'] ?? 0.0) - (data['totalAmtCollected'] ?? 0.0)}',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isWeeklyView
                                          ? 'partyDetailScreen.weeksOver'.tr()
                                          : 'partyDetailScreen.daysOver'.tr(),
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900),
                                    ),
                                    Text(
                                      _isWeeklyView
                                          ? '${((daysover ?? 0) / 7).toStringAsFixed(1)}'
                                          : '${daysover ?? 0}',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isWeeklyView
                                          ? 'partyDetailScreen.weeks'.tr()
                                          : 'partyDetailScreen.days'.tr(),
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900),
                                    ),
                                    Text(
                                      daysrem != null && daysrem < 0
                                          ? (_isWeeklyView
                                              ? '${'partyDetailScreen.overdue'.tr()} ${(daysrem.abs() / 7).toStringAsFixed(1)}'
                                              : '${'partyDetailScreen.overdue'.tr()} ${daysrem.abs()}')
                                          : (_isWeeklyView
                                              ? '${'partyDetailScreen.remaining'.tr()} ${(daysrem / 7).toStringAsFixed(1)}'
                                              : '${'partyDetailScreen.remaining'.tr()} $daysrem'),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: daysrem != null && daysrem < 0
                                            ? Colors.red
                                            : Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isWeeklyView
                                          ? 'partyDetailScreen.weeksPaid'.tr()
                                          : 'partyDetailScreen.daysPaid'.tr(),
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900),
                                    ),
                                    Text(
                                      _isWeeklyView
                                          ? '${(givendays / 7).toStringAsFixed(1)}'
                                          : '${givendays.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pendays < 0
                                          ? (_isWeeklyView
                                              ? '${'partyDetailScreen.advanceWeeksPaid'.tr()} ${(pendays.abs() / 7).toStringAsFixed(1)}'
                                              : '${'partyDetailScreen.advanceDaysPaid'.tr()} ${pendays.abs().toStringAsFixed(2)}')
                                          : (_isWeeklyView
                                              ? '${'partyDetailScreen.pendingWeeks'.tr()} ${(pendays / 7).toStringAsFixed(1)}'
                                              : '${'partyDetailScreen.pendingDays'.tr()} ${pendays.toStringAsFixed(2)}'),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: pendays < 0
                                            ? const Color.fromARGB(
                                                255, 94, 80, 3)
                                            : Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'partyDetailScreen.lentDate'.tr(),
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900),
                                    ),
                                    Text(
                                      data['lentdate']?.toString() ?? 'N/A',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'partyDetailScreen.dueDate'.tr(),
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900),
                                    ),
                                    Text(
                                      duedate != null
                                          ? DateFormat('dd-MM-yyyy')
                                              .format(DateTime.parse(duedate))
                                          : 'N/A',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ),

          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'partyDetailScreen.entryDetails'.tr(),
                style: GoogleFonts.tinos(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ),
          // i need a card with single row .which contains 3 icon buttons
          // 1. party report 2. sms reminder  3. watsup reminder

          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: CollectionDB.getCollectionEntries(lenId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                      child: Text('partyDetailScreen.noEntriesFound'.tr()));
                } else {
                  final List<Map<String, dynamic>> entries =
                      List.from(snapshot.data!);

                  // Sort by latest date
                  entries.sort((a, b) => DateFormat('yyyy-MM-dd')
                      .parse(b['Date'])
                      .compareTo(DateFormat('yyyy-MM-dd').parse(a['Date'])));

                  // Calculate totals
                  double totalCredit = 0, totalDebit = 0;
                  for (var entry in entries) {
                    totalCredit += entry['CrAmt'] ?? 0.0;
                    totalDebit += entry['DrAmt'] ?? 0.0;
                  }
                  double balance = totalDebit - totalCredit;

                  return RefreshIndicator(
                    onRefresh: () async {
                      setState(() {});
                    },
                    child: Column(
                      children: [
                        // Summary card
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: FutureBuilder<Map<String, dynamic>>(
                                future: dbLending.getLendingDetails(
                                    lenId!), // Fetch lending details
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  } else if (snapshot.hasError) {
                                    return Center(
                                        child:
                                            Text('Error: ${snapshot.error}'));
                                  } else if (!snapshot.hasData ||
                                      snapshot.data!.isEmpty) {
                                    return const Center(
                                        child: Text('No data found.'));
                                  } else {
                                    final data = snapshot.data!;
                                    final totalAmtGivenWithProfit =
                                        data['totalAmtGivenWithProfit'] ?? 0.0;
                                    final amtCollected =
                                        data['amtCollected'] ?? 0.0;
                                    final dueDays = data['dueDays'] ?? 0;
                                    final amtperday =
                                        data['totalAmtGivenWithProfit'] ??
                                            0.0 / data['dueDays'];

                                    // Calculate balance
                                    final balance =
                                        totalAmtGivenWithProfit - amtCollected;

                                    // Calculate per day amounts using dueDays
                                    final perdayamt =
                                        totalAmtGivenWithProfit / dueDays;

                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildSummaryItem(
                                          'partyDetailScreen.credit'.tr(),
                                          totalAmtGivenWithProfit,
                                          Colors.red,
                                          additionalInfo: dueDays > 0
                                              ? "(${dueDays.toStringAsFixed(2)})"
                                              : 'partyDetailScreen.notAvailable'
                                                  .tr(), // Add calculation for Credit
                                        ),
                                        _buildSummaryItem(
                                          'partyDetailScreen.debit'.tr(),
                                          amtCollected,
                                          Colors.green,
                                          additionalInfo: dueDays > 0
                                              ? "(${(amtCollected / perdayamt).toStringAsFixed(2)})"
                                              : 'partyDetailScreen.notAvailable'
                                                  .tr(), // Add calculation for Debit
                                        ),
                                        _buildSummaryItem(
                                          'partyDetailScreen.balance'.tr(),
                                          balance.abs(),
                                          balance >= 0
                                              ? const Color.fromARGB(
                                                  255, 10, 10, 10)
                                              : const Color.fromARGB(
                                                  255, 24, 2, 77),
                                          additionalInfo: dueDays > 0
                                              ? "(${(balance / perdayamt).abs().toStringAsFixed(2)})"
                                              : "(N/A)", // Add calculation for Balance
                                        ),
                                      ],
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                        ),

                        // Entry List
                        Expanded(
                          child: AnimationLimiter(
                            child: ListView.separated(
                              itemCount: entries.length,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 2),
                              itemBuilder: (context, index) {
                                final entry = entries[index];
                                final rawDate = entry['Date'];
                                final crAmt = entry['CrAmt'] ?? 0.0;
                                final drAmt = entry['DrAmt'] ?? 0.0;
                                final cid = entry['cid'];

                                final isCredit = crAmt > 0;
                                final formattedDate = DateFormat('dd MMM yyyy')
                                    .format(DateFormat('yyyy-MM-dd')
                                        .parse(rawDate));
                                final amountText = isCredit
                                    ? "${'partyDetailScreen.credit'.tr()}: ₹${crAmt.toStringAsFixed(2)}"
                                    : "${'partyDetailScreen.debit'.tr()}: ₹${drAmt.toStringAsFixed(2)}";
                                final amountColor = isCredit
                                    ? Colors.red.shade600
                                    : Colors.green.shade700;
                                final icon = isCredit
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward;

                                return AnimationConfiguration.staggeredList(
                                  position: index,
                                  duration: const Duration(milliseconds: 500),
                                  child: SlideAnimation(
                                    verticalOffset: 50.0,
                                    child: FadeInAnimation(
                                      child: GestureDetector(
                                        onTap: () async {
                                          if (drAmt > 0) {
                                            Navigator.of(context)
                                                .push(MaterialPageRoute(
                                              builder: (context) =>
                                                  CollectionScreen(
                                                preloadedDate: rawDate,
                                                preloadedAmtCollected: drAmt,
                                                preloadedCid: cid,
                                              ),
                                            ));
                                          } else if (crAmt > 0) {
                                            final partyDetails = await dbLending
                                                .getPartyDetails(lenId);
                                            amt = 0;
                                            Navigator.of(context)
                                                .push(MaterialPageRoute(
                                              builder: (context) =>
                                                  LendingCombinedDetailsScreen(
                                                preloadedamtgiven:
                                                    partyDetails?['amtgiven'] ??
                                                        0.0,
                                                preladedprofit:
                                                    partyDetails?['profit'] ??
                                                        0.0,
                                                preladedlendate:
                                                    partyDetails?['Lentdate'] ??
                                                        '',
                                                preladedduedays:
                                                    partyDetails?['duedays'] ??
                                                        0,
                                                cid: cid,
                                              ),
                                            ));
                                          }
                                        },
                                        child: Card(
                                          elevation: 3,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 4, horizontal: 6),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              border: Border(
                                                left: BorderSide(
                                                    color: amountColor,
                                                    width: 5),
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              color:
                                                  Theme.of(context).cardColor,
                                            ),
                                            child: ListTile(
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                      vertical: 10),
                                              leading: CircleAvatar(
                                                backgroundColor: amountColor
                                                    .withOpacity(0.9),
                                                child: Icon(icon,
                                                    color: Colors.white,
                                                    size: 20),
                                              ),
                                              title: Text(
                                                formattedDate,
                                                style: GoogleFonts.tinos(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context)
                                                      .textTheme
                                                      .bodyLarge
                                                      ?.color,
                                                ),
                                              ),
                                              subtitle: Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 4),
                                                child: Text(
                                                  amountText,
                                                  style: GoogleFonts.tinos(
                                                    fontSize: 13,
                                                    color: amountColor,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              trailing: const Icon(
                                                  Icons.chevron_right,
                                                  color: Colors.grey),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
      floatingActionButton: Container(
        margin:
            EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16),
        child: FloatingActionButton(
          onPressed: _showActionMenuDialog,
          backgroundColor: Colors.blue,
          child: Icon(Icons.add, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
