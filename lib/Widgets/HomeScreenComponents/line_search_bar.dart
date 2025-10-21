import 'dart:async';
import 'package:flutter/material.dart';

class LineSearchBar extends StatefulWidget {
  final List<String> originalLineNames;
  final Function(List<String>) onSearchResults;

  const LineSearchBar({
    super.key,
    required this.originalLineNames,
    required this.onSearchResults,
  });

  @override
  State<LineSearchBar> createState() => _LineSearchBarState();
}

class _LineSearchBarState extends State<LineSearchBar> {
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    // Debounce search to improve performance
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        final filteredLines = widget.originalLineNames
            .where((lineName) =>
                lineName.toLowerCase().contains(value.toLowerCase()))
            .toList();
        widget.onSearchResults(filteredLines);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Search lines...',
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }
}
