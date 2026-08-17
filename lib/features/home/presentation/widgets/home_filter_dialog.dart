import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/searchable_dropdown.dart';
import '../../data/models/home_data_model.dart';

typedef OnApplyHomeFilter =
    void Function({
      String? city,
      String? area,
      String? roomType,
      String? query,
    });

/// Loads a page of cities for the dropdown.
typedef CityLoader = Future<({List<String> items, bool hasMore})> Function(
  String? search,
  int page,
);

/// Loads a page of areas for the dropdown, scoped to [city] (null = all areas).
typedef AreaLoader = Future<({List<String> items, bool hasMore})> Function(
  String? city,
  String? search,
  int page,
);

class HomeFilterDialog extends StatefulWidget {
  final List<RoomTypeOption> roomTypes;
  final String? initialCity;
  final String? initialArea;
  final String? initialRoomType;
  final String? initialQuery;
  final CityLoader loadCities;
  final AreaLoader loadAreas;
  final OnApplyHomeFilter onApply;

  const HomeFilterDialog({
    super.key,
    required this.roomTypes,
    this.initialCity,
    this.initialArea,
    this.initialRoomType,
    this.initialQuery,
    required this.loadCities,
    required this.loadAreas,
    required this.onApply,
  });

  static void show(
    BuildContext context, {
    required List<RoomTypeOption> roomTypes,
    String? initialCity,
    String? initialArea,
    String? initialRoomType,
    String? initialQuery,
    required CityLoader loadCities,
    required AreaLoader loadAreas,
    required OnApplyHomeFilter onApply,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => HomeFilterDialog(
        roomTypes: roomTypes,
        initialCity: initialCity,
        initialArea: initialArea,
        initialRoomType: initialRoomType,
        initialQuery: initialQuery,
        loadCities: loadCities,
        loadAreas: loadAreas,
        onApply: onApply,
      ),
    );
  }

  @override
  State<HomeFilterDialog> createState() => _HomeFilterDialogState();
}

class _HomeFilterDialogState extends State<HomeFilterDialog> {
  late String? _selectedCity;
  late String? _selectedArea;
  late String? _selectedRoomType;
  late TextEditingController _queryController;

  @override
  void initState() {
    super.initState();
    _selectedCity = widget.initialCity;
    _selectedArea = widget.initialArea;
    _selectedRoomType = widget.initialRoomType;
    _queryController = TextEditingController(text: widget.initialQuery ?? '');
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  bool get _hasFilterApplied =>
      _selectedCity != null ||
      _selectedArea != null ||
      _selectedRoomType != null ||
      _queryController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.paper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter Seat Listings',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                    letterSpacing: -0.4,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.brand,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search Keyword
            const _FieldLabel('Search Keyword'),
            const SizedBox(height: 6),
            TextField(
              controller: _queryController,
              onChanged: (_) => setState(() {}),
              decoration: _inputDecoration(
                hintText: 'Search title, area, or mess name…',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.inkFaded,
                  size: 20,
                ),
                suffixIcon: _queryController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppColors.inkFaded,
                        ),
                        onPressed: () {
                          setState(() {
                            _queryController.clear();
                          });
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),

            // City — searchable + paginated
            const _FieldLabel('Select City'),
            const SizedBox(height: 6),
            SearchableDropdown(
              value: _selectedCity,
              hint: 'All Cities',
              fetcher: widget.loadCities,
              onChanged: (value) {
                setState(() {
                  _selectedCity = value;
                  _selectedArea = null;
                });
              },
            ),
            const SizedBox(height: 16),

            // Area — always available: all areas when no city, city areas when selected
            const _FieldLabel('Select Area'),
            const SizedBox(height: 6),
            SearchableDropdown(
              key: ValueKey<String?>(_selectedCity),
              value: _selectedArea,
              hint: 'All Areas',
              fetcher: (search, page) => widget.loadAreas(
                _selectedCity,
                search,
                page,
              ),
              onChanged: (value) =>
                  setState(() => _selectedArea = value),
            ),
            const SizedBox(height: 16),

            // Room Type Dropdown
            const _FieldLabel('Room Type'),
            const SizedBox(height: 6),
            _FilterDropdown<RoomTypeOption>(
              value: widget.roomTypes
                  .where((rt) => rt.value == _selectedRoomType)
                  .firstOrNull,
              hint: 'All Types',
              items: widget.roomTypes,
              labelOf: (rt) => rt.label,
              onChanged: (value) =>
                  setState(() => _selectedRoomType = value?.value),
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      side: const BorderSide(color: AppColors.paperLine),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _hasFilterApplied
                        ? () {
                            setState(() {
                              _selectedCity = null;
                              _selectedArea = null;
                              _selectedRoomType = null;
                              _queryController.clear();
                            });
                          }
                        : () => Navigator.of(context).pop(),
                    child: Text(
                      _hasFilterApplied ? 'Reset' : 'Cancel',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      final qText = _queryController.text.trim();
                      widget.onApply(
                        city: _selectedCity,
                        area: _selectedArea,
                        roomType: _selectedRoomType,
                        query: qText.isEmpty ? null : qText,
                      );
                    },
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: AppColors.inkFaded, fontSize: 13.5),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: AppColors.paperRaised,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.paperLine),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.paperLine),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.brandDark, width: 1.5),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: AppColors.inkFaded,
      ),
    );
  }
}

/// Rounded dropdown with a filled background and chevron icon.
class _FilterDropdown<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String Function(T item)? labelOf;

  const _FilterDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
    this.labelOf,
  });

  String _label(T item) {
    if (labelOf != null) return labelOf!(item);
    return item.toString();
  }

  @override
  Widget build(BuildContext context) {
    final selected = items.where((e) => e == value).firstOrNull;

    return DropdownButtonFormField<T>(
      initialValue: selected,
      isExpanded: true,
      hint: Text(
        hint,
        style: const TextStyle(color: AppColors.inkFaded, fontSize: 13.5),
      ),
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.inkFaded,
        size: 22,
      ),
      dropdownColor: AppColors.paperRaised,
      style: const TextStyle(
        color: AppColors.ink,
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        filled: true,
        fillColor: AppColors.paperRaised,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.paperLine),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.paperLine),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.brandDark, width: 1.5),
        ),
      ),
      items: [
        DropdownMenuItem<T>(
          value: null,
          child: Text(
            hint,
            style: const TextStyle(
              color: AppColors.inkFaded,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...items.map((item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(_label(item), overflow: TextOverflow.ellipsis),
          );
        }),
      ],
      onChanged: onChanged,
    );
  }
}
