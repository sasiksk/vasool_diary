import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kskfinance/finance_provider.dart';
import 'party_report_pdf.dart';
import 'package:kskfinance/Data/Databasehelper.dart';

class PartyReportPage extends ConsumerStatefulWidget {
  const PartyReportPage({Key? key}) : super(key: key);

  @override
  ConsumerState<PartyReportPage> createState() => _PartyReportPageState();
}

class _PartyReportPageState extends ConsumerState<PartyReportPage> {
  bool _loading = false;
  List<Map<String, dynamic>> _summaryList = [];
  List<String> _partyNames = [];
  List<String> _filteredPartyNames = [];
  String _selectedParty = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSummaryList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchSummaryList() async {
    final summaryList =
        await dbLending.getActiveLendingSummaryWithCollections();
    setState(() {
      _summaryList = summaryList;
      _partyNames = [
        'All',
        ...{for (var s in summaryList) (s['PartyName'] ?? '').toString()}
      ];
      _filteredPartyNames = List.from(_partyNames);
    });
  }

  void _filterPartyNames(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPartyNames = List.from(_partyNames);
      } else {
        _filteredPartyNames = _partyNames
            .where((name) => name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
      // Reset selection if current party is not in filtered list
      if (!_filteredPartyNames.contains(_selectedParty)) {
        _selectedParty =
            _filteredPartyNames.isNotEmpty ? _filteredPartyNames.first : 'All';
      }
    });
  }

  Future<void> _onGeneratePdfPressed() async {
    setState(() => _loading = true);

    final financeName = ref.watch(financeProvider);

    final filteredList = _selectedParty == 'All'
        ? _summaryList
        : _summaryList
            .where((s) => (s['PartyName'] ?? '') == _selectedParty)
            .toList();

    await generatePartyReportPdf(filteredList, financeName);

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('📄 Party-wise Lending Report'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '📋 Lending Summary',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColorDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'View detailed lending and collection history by party. '
                'Select a party or generate the full report.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),

              // Search & Select Section
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Search & Select Party',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),

                    // Search Field
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Type to search party names...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: _searchController.text.isNotEmpty
                                ? Colors.grey.shade600
                                : Colors.transparent,
                          ),
                          onPressed: _searchController.text.isNotEmpty
                              ? () {
                                  setState(() {
                                    _searchController.clear();
                                    _filteredPartyNames =
                                        List.from(_partyNames);
                                    // Reset to 'All' when clearing search
                                    _selectedParty = 'All';
                                  });
                                }
                              : null,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.blue.shade300),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      onChanged: (value) {
                        _filterPartyNames(value);
                        setState(
                            () {}); // Refresh to update clear button visibility
                      },
                    ),

                    const SizedBox(height: 12),

                    // Party Count Info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Select Party', style: theme.textTheme.bodyMedium),
                        Text('Found ${_filteredPartyNames.length} parties',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Filtered Dropdown
                    _filteredPartyNames.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: Colors.grey.shade500, size: 20),
                                const SizedBox(width: 8),
                                const Text('No parties found',
                                    style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          )
                        : DropdownButton<String>(
                            value: _filteredPartyNames.contains(_selectedParty)
                                ? _selectedParty
                                : (_filteredPartyNames.isNotEmpty
                                    ? _filteredPartyNames.first
                                    : 'All'),
                            isExpanded: true,
                            items: _filteredPartyNames
                                .map((name) => DropdownMenuItem(
                                      value: name,
                                      child: Row(
                                        children: [
                                          Icon(
                                            name == 'All'
                                                ? Icons.select_all
                                                : Icons.person_outline,
                                            size: 18,
                                            color: name == 'All'
                                                ? Colors.blue.shade600
                                                : Colors.grey.shade600,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(name.isEmpty
                                              ? '(Unnamed)'
                                              : name),
                                        ],
                                      ),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedParty = value);
                              }
                            },
                          ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '💡 This report helps you track each party’s total lent amount, due dates, and collections. '
                  'Perfect for printing or sharing as a professional PDF summary.',
                  style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16),
                  textAlign: TextAlign.justify,
                ),
              ),

              const SizedBox(height: 30),

              // Generate Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.picture_as_pdf),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      _loading ? 'Generating PDF...' : 'Download & Save PDF',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _loading ? null : _onGeneratePdfPressed,
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
