import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Fetcher signature: returns a page of items plus whether more pages exist.
typedef SearchPageFetcher = Future<({List<String> items, bool hasMore})> Function(
  String? search,
  int page,
);

/// Searchable dropdown backed by the API.
///
/// The collapsed field looks like the app's rounded dropdowns; tapping it
/// opens a bottom sheet with a search box, a paginated list ("Show more"),
/// and server-side filtered results. Used for city / area filters where
/// option lists can be long.
class SearchableDropdown extends StatefulWidget {
  final String? value;
  final String hint;
  final SearchPageFetcher fetcher;
  final ValueChanged<String?> onChanged;

  const SearchableDropdown({
    super.key,
    required this.value,
    required this.hint,
    required this.fetcher,
    required this.onChanged,
  });

  @override
  State<SearchableDropdown> createState() => _SearchableDropdownState();
}

class _SearchableDropdownState extends State<SearchableDropdown> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.value;
  }

  @override
  void didUpdateWidget(SearchableDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _selected = widget.value;
  }

  Future<void> _openPicker() async {
    await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _SearchPickerSheet(
        hint: widget.hint,
        initialValue: _selected,
        fetcher: widget.fetcher,
        onPick: (value) {
          Navigator.of(context).pop();
          if (!mounted) return;
          setState(() => _selected = value);
          widget.onChanged(value);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openPicker,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.paperRaised,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.paperLine),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _selected ?? widget.hint,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _selected == null
                      ? AppColors.inkFaded
                      : AppColors.ink,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.inkFaded,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom-sheet picker: search field + paginated option list.
class _SearchPickerSheet extends StatefulWidget {
  final String hint;
  final String? initialValue;
  final SearchPageFetcher fetcher;
  final ValueChanged<String?> onPick;

  const _SearchPickerSheet({
    required this.hint,
    required this.initialValue,
    required this.fetcher,
    required this.onPick,
  });

  @override
  State<_SearchPickerSheet> createState() => _SearchPickerSheetState();
}

class _SearchPickerSheetState extends State<_SearchPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<String> _items = const [];
  String? _selected;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  int _page = 1;
  int _requestSeq = 0;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialValue;
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
  }

  Future<void> _load() async {
    final seq = ++_requestSeq;
    final query = _searchController.text.trim();
    setState(() {
      _loading = true;
      _page = 1;
    });
    try {
      final result =
          await widget.fetcher(query.isEmpty ? null : query, 1);
      if (!mounted || seq != _requestSeq) return;
      setState(() {
        _items = result.items;
        _hasMore = result.hasMore;
        _page = 1;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || seq != _requestSeq) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _loading || !_hasMore) return;
    final seq = _requestSeq;
    final query = _searchController.text.trim();
    setState(() => _loadingMore = true);
    try {
      final result = await widget.fetcher(
        query.isEmpty ? null : query,
        _page + 1,
      );
      if (!mounted || seq != _requestSeq) return;
      setState(() {
        _items = [..._items, ...result.items];
        _hasMore = result.hasMore;
        _page += 1;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted || seq != _requestSeq) return;
      setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.62,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Select ${widget.hint.split(' ').last}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.inkFaded,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search…',
                  hintStyle: const TextStyle(
                    color: AppColors.inkFaded,
                    fontSize: 13.5,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: AppColors.inkFaded,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  filled: true,
                  fillColor: AppColors.paperRaised,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.paperLine),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.paperLine),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.brandDark,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: _buildList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            color: AppColors.brandDark,
          ),
        ),
      );
    }

    final entries = <Widget>[
      _OptionTile(
        label: widget.hint,
        selected: _selected == null,
        onTap: () => widget.onPick(null),
      ),
    ];

    if (_items.isEmpty) {
      entries.add(
        const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No matches',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.inkFaded,
              ),
            ),
          ),
        ),
      );
    } else {
      for (final item in _items) {
        entries.add(
           _OptionTile(
            label: item,
            selected: _selected == item,
            onTap: () => widget.onPick(item),
          ),
        );
      }
    }

    if (_hasMore) {
      entries.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Center(
            child: _loadingMore
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.brandDark,
                    ),
                  )
                : TextButton(
                    onPressed: _loadMore,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                    ),
                    child: const Text(
                      'Show more',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accentDark,
                      ),
                    ),
                  ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const Divider(
        height: 1,
        thickness: 0.5,
        color: AppColors.paperLine,
      ),
      itemBuilder: (context, index) => entries[index],
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? AppColors.brandDark : AppColors.ink,
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_rounded,
                size: 18,
                color: AppColors.brandDark,
              ),
          ],
        ),
      ),
    );
  }
}
