import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/home_data_model.dart';

typedef OnApplyHomeFilter =
    void Function({
      String? city,
      String? area,
      String? roomType,
      String? query,
    });

class HomeFilterDialog extends StatefulWidget {
  final List<String> cities;
  final List<String> areas;
  final List<RoomTypeOption> roomTypes;
  final String? initialCity;
  final String? initialArea;
  final String? initialRoomType;
  final String? initialQuery;
  final OnApplyHomeFilter onApply;

  const HomeFilterDialog({
    super.key,
    required this.cities,
    required this.areas,
    required this.roomTypes,
    this.initialCity,
    this.initialArea,
    this.initialRoomType,
    this.initialQuery,
    required this.onApply,
  });

  static void show(
    BuildContext context, {
    required List<String> cities,
    required List<String> areas,
    required List<RoomTypeOption> roomTypes,
    String? initialCity,
    String? initialArea,
    String? initialRoomType,
    String? initialQuery,
    required OnApplyHomeFilter onApply,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => HomeFilterDialog(
        cities: cities,
        areas: areas,
        roomTypes: roomTypes,
        initialCity: initialCity,
        initialArea: initialArea,
        initialRoomType: initialRoomType,
        initialQuery: initialQuery,
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

  @override
  Widget build(BuildContext context) {
    final defaultRoomTypes = widget.roomTypes.isNotEmpty
        ? widget.roomTypes
        : const [
            RoomTypeOption(value: 'single', label: 'Single'),
            RoomTypeOption(value: 'shared', label: 'Shared'),
            RoomTypeOption(value: 'bunk', label: 'Bunk'),
            RoomTypeOption(value: 'semi-private', label: 'Semi-private'),
          ];

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

            // City Dropdown
            const _FieldLabel('Select City'),
            const SizedBox(height: 6),
            _FilterDropdown(
              value: _selectedCity,
              hint: 'All Cities',
              items: widget.cities,
              onChanged: (value) => setState(() => _selectedCity = value),
            ),
            const SizedBox(height: 16),

            // Area Dropdown
            if (widget.areas.isNotEmpty) ...[
              const _FieldLabel('Select Area'),
              const SizedBox(height: 6),
              _FilterDropdown(
                value: _selectedArea,
                hint: 'All Areas',
                items: widget.areas,
                onChanged: (value) => setState(() => _selectedArea = value),
              ),
              const SizedBox(height: 16),
            ],

            // Room Type Dropdown
            const _FieldLabel('Room Type'),
            const SizedBox(height: 6),
            _FilterDropdown<RoomTypeOption>(
              value: defaultRoomTypes
                  .where((rt) => rt.value == _selectedRoomType)
                  .firstOrNull,
              hint: 'All Types',
              items: defaultRoomTypes,
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
                    onPressed: () {
                      setState(() {
                        _selectedCity = null;
                        _selectedArea = null;
                        _selectedRoomType = null;
                        _queryController.clear();
                      });
                    },
                    child: const Text(
                      'Reset',
                      style: TextStyle(
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
