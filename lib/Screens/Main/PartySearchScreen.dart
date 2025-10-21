import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kskfinance/Data/Databasehelper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kskfinance/Screens/Main/PartyDetailScreen.dart';
import 'package:kskfinance/Utilities/AppBar.dart';
import 'package:kskfinance/Utilities/drawer.dart';
import '../../finance_provider.dart';

class PartySearchScreen extends ConsumerStatefulWidget {
  const PartySearchScreen({super.key});

  @override
  PartySearchScreenState createState() => PartySearchScreenState();
}

class PartySearchScreenState extends ConsumerState<PartySearchScreen> {
  List<Map<String, dynamic>> allParties = [];
  ValueNotifier<List<Map<String, dynamic>>> filteredPartiesNotifier =
      ValueNotifier([]);
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadAllParties();
  }

  void loadAllParties() async {
    try {
      final parties = await dbLending.getAllPartiesWithBalance();
      setState(() {
        allParties = parties;
        filteredPartiesNotifier.value = parties;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading parties: $e')),
        );
      }
    }
  }

  void filterParties(String query) {
    if (query.isEmpty) {
      filteredPartiesNotifier.value = allParties;
    } else {
      final filtered = allParties.where((party) {
        final partyName = (party['PartyName'] ?? '').toString().toLowerCase();
        final phoneNumber =
            (party['PartyPhnone'] ?? '').toString().toLowerCase();
        final searchQuery = query.toLowerCase();

        return partyName.contains(searchQuery) ||
            phoneNumber.contains(searchQuery);
      }).toList();
      filteredPartiesNotifier.value = filtered;
    }
  }

  Future<void> makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty || phoneNumber == 'null') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number not available')),
      );
      return;
    }

    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch phone dialer')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error making call: $e')),
        );
      }
    }
  }

  void handlePartySelected(Map<String, dynamic> party) async {
    try {
      final lenId = party['LenId'] as int?;
      final partyName = party['PartyName'] as String?;
      final lineName = party['LineName'] as String?;

      if (lenId != null && partyName != null && lineName != null) {
        // Set the current line and party in providers
        ref.read(currentLineNameProvider.notifier).state = lineName;
        ref.read(currentPartyNameProvider.notifier).state = partyName;
        await ref.read(lenIdProvider.notifier).saveLenId(lenId);

        // Get and set the status
        final String? status = await DatabaseHelper.getStatus(lenId);
        if (status != null) {
          ref.read(lenStatusProvider.notifier).updateLenStatus(status);
        }

        // Navigate to party detail screen
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PartyDetailScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error navigating to party details: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: buildDrawer(context),
      appBar: CustomAppBar(
        title: 'Search Parties',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                isLoading = true;
              });
              loadAllParties();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Box
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              style: TextStyle(
                color: Colors.black,
                fontFamily: GoogleFonts.tinos().fontFamily,
              ),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search by name or phone number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: filterParties,
            ),
          ),

          // Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Party Details',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: GoogleFonts.tinos().fontFamily,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Balance',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: GoogleFonts.tinos().fontFamily,
                    ),
                  ),
                ),
                const SizedBox(width: 50), // Space for call button
              ],
            ),
          ),

          // Party List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ValueListenableBuilder<List<Map<String, dynamic>>>(
                    valueListenable: filteredPartiesNotifier,
                    builder: (context, filteredParties, _) {
                      if (filteredParties.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off,
                                  size: 50, color: Colors.grey),
                              SizedBox(height: 10),
                              Text(
                                'No parties found',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return AnimationLimiter(
                        child: ListView.separated(
                          itemCount: filteredParties.length,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 4),
                          itemBuilder: (context, index) {
                            final party = filteredParties[index];
                            final partyName =
                                party['PartyName']?.toString() ?? 'Unknown';
                            final lineName =
                                party['LineName']?.toString() ?? 'Unknown';
                            final phoneNumber =
                                party['PartyPhnone']?.toString() ?? '';
                            final balance =
                                (party['balance'] as double?) ?? 0.0;

                            return AnimationConfiguration.staggeredList(
                              position: index,
                              duration: const Duration(milliseconds: 400),
                              child: SlideAnimation(
                                verticalOffset: 40.0,
                                child: FadeInAnimation(
                                  child: GestureDetector(
                                    onTap: () => handlePartySelected(party),
                                    child: Card(
                                      elevation: 6,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 4),
                                      child: Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF1E88E5), // Blue
                                              Color(0xFF0D47A1), // Dark Blue
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withAlpha(
                                                  (0.1 * 255).toInt()),
                                              blurRadius: 6,
                                              offset: const Offset(2, 3),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            // Avatar
                                            CircleAvatar(
                                              backgroundColor: Colors.white
                                                  .withAlpha(
                                                      (0.2 * 255).toInt()),
                                              radius: 24,
                                              child: const Icon(
                                                Icons.account_circle,
                                                color: Colors.white,
                                                size: 28,
                                              ),
                                            ),
                                            const SizedBox(width: 12),

                                            // Party Details
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  // Party Name
                                                  Text(
                                                    partyName,
                                                    style: GoogleFonts.tinos(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  // Line Name
                                                  Text(
                                                    'Line: $lineName',
                                                    style: GoogleFonts.tinos(
                                                      fontSize: 12,
                                                      color: Colors.white
                                                          .withAlpha((0.8 * 255)
                                                              .toInt()),
                                                    ),
                                                  ),
                                                  if (phoneNumber.isNotEmpty &&
                                                      phoneNumber !=
                                                          'null') ...[
                                                    const SizedBox(height: 2),
                                                    // Phone Number
                                                    Text(
                                                      'Ph: $phoneNumber',
                                                      style: GoogleFonts.tinos(
                                                        fontSize: 12,
                                                        color: Colors.white
                                                            .withAlpha(
                                                                (0.8 * 255)
                                                                    .toInt()),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),

                                            // Balance Display
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withAlpha(
                                                    (0.15 * 255).toInt()),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                '₹${balance.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (match) => '${match[1]},')}',
                                                style: GoogleFonts.tinos(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),

                                            const SizedBox(width: 8),

                                            // Call Button
                                            if (phoneNumber.isNotEmpty &&
                                                phoneNumber != 'null')
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.green,
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: IconButton(
                                                  icon: const Icon(
                                                    Icons.phone,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                  onPressed: () =>
                                                      makePhoneCall(
                                                          phoneNumber),
                                                  tooltip: 'Call $partyName',
                                                ),
                                              )
                                            else
                                              Container(
                                                width: 48,
                                                height: 48,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.withAlpha(
                                                      (0.3 * 255).toInt()),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Icon(
                                                  Icons.phone_disabled,
                                                  color: Colors.white.withAlpha(
                                                      (0.5 * 255).toInt()),
                                                  size: 20,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),

          // Total Count Display
          ValueListenableBuilder<List<Map<String, dynamic>>>(
            valueListenable: filteredPartiesNotifier,
            builder: (context, filteredParties, _) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border(top: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people, color: Colors.grey[600], size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '${filteredParties.length} ${filteredParties.length == 1 ? 'party' : 'parties'} found',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                        fontFamily: GoogleFonts.tinos().fontFamily,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    filteredPartiesNotifier.dispose();
    super.dispose();
  }
}
