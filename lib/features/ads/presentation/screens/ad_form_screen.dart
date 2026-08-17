import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/ad_model.dart';
import '../../data/repositories/user_ad_repository.dart';

class AdFormScreen extends StatefulWidget {
  final AdModel? ad;

  const AdFormScreen({super.key, this.ad});

  @override
  State<AdFormScreen> createState() => _AdFormScreenState();
}

class _AdFormScreenState extends State<AdFormScreen> {
  final UserAdRepository _repository = UserAdRepository();
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  final _titleController = TextEditingController();
  final _cityController = TextEditingController();
  final _areaController = TextEditingController();
  final _locationController = TextEditingController();
  final _rentController = TextEditingController();
  final _totalRentController = TextEditingController();
  final _seatsController = TextEditingController();
  final _capacityController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();

  String _roomType = 'shared';
  bool _hideAddress = false;
  final Set<String> _selectedAmenities = {'WiFi', 'Meal'};

  // Image Upload State
  List<AdImageItem> _existingImages = [];
  final List<int> _removedImageIds = [];
  final List<XFile> _newImages = [];

  static const List<Map<String, String>> _roomTypesInfo = [
    {
      'type': 'shared',
      'title': 'Shared Room',
      'subtitle': 'Multiple roommates sharing a room (2-4 persons)',
      'icon': 'bed_shared',
    },
    {
      'type': 'single',
      'title': 'Single Room',
      'subtitle': 'Private personal room for 1 person only',
      'icon': 'person_single',
    },
    {
      'type': 'semi-private',
      'title': 'Half Room / Semi-Private',
      'subtitle': 'Partitioned semi-private room space',
      'icon': 'door_half',
    },
    {
      'type': 'bunk',
      'title': 'Bunk Bed',
      'subtitle': 'Top or bottom bunk in hostel-style room',
      'icon': 'bunk_bed',
    },
  ];

  static const List<Map<String, dynamic>> _availableAmenitiesList = [
    {'name': 'WiFi', 'icon': Icons.wifi_rounded},
    {'name': 'Attached bath', 'icon': Icons.bathtub_outlined},
    {'name': 'Meal', 'icon': Icons.restaurant_rounded},
    {'name': 'CC TV', 'icon': Icons.videocam_outlined},
    {'name': 'AC', 'icon': Icons.ac_unit_rounded},
    {'name': 'Lift', 'icon': Icons.elevator_outlined},
    {'name': 'Fridge', 'icon': Icons.kitchen_outlined},
    {'name': 'Generator', 'icon': Icons.power_rounded},
    {'name': 'Laundry', 'icon': Icons.local_laundry_service_outlined},
    {'name': 'Parking', 'icon': Icons.local_parking_rounded},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.ad != null) {
      final ad = widget.ad!;
      _titleController.text = ad.title;
      _cityController.text = ad.city ?? 'Dhaka';
      _areaController.text = ad.area ?? '';
      _locationController.text = ad.location ?? '';
      _rentController.text = ad.rentPerSeat.toInt().toString();
      _totalRentController.text = ad.rentTotal != null ? ad.rentTotal!.toInt().toString() : '';
      _seatsController.text = ad.seatsAvailable.toString();
      _capacityController.text = ad.roomCapacity?.toString() ?? '3';
      _descriptionController.text = ad.description ?? '';
      _phoneController.text = ad.contactPhone ?? '';
      _whatsappController.text = ad.contactWhatsapp ?? '';
      _roomType = ad.roomType;
      _hideAddress = ad.hideAddress;
      if (ad.amenities.isNotEmpty) {
        _selectedAmenities.clear();
        _selectedAmenities.addAll(ad.amenities);
      }
      if (ad.rawImages.isNotEmpty) {
        _existingImages = List.from(ad.rawImages);
      }
    } else {
      _cityController.text = 'Dhaka';
      _seatsController.text = '1';
      _capacityController.text = '3';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _locationController.dispose();
    _rentController.dispose();
    _totalRentController.dispose();
    _seatsController.dispose();
    _capacityController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  int get _totalImageCount => _existingImages.length + _newImages.length;

  Future<void> _pickImages() async {
    final remainingSlots = 6 - _totalImageCount;
    if (remainingSlots <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 6 photos allowed per seat ad')),
      );
      return;
    }

    try {
      final List<XFile> picked = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (picked.isNotEmpty) {
        setState(() {
          final toAdd = picked.take(remainingSlots);
          _newImages.addAll(toAdd);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick images: $e')),
      );
    }
  }

  void _removeExistingImage(int index) {
    setState(() {
      final removed = _existingImages.removeAt(index);
      if (removed.id > 0) {
        _removedImageIds.add(removed.id);
      }
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    final title = _titleController.text.trim();
    final rentStr = _rentController.text.trim();
    final seatsStr = _seatsController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an ad title')),
      );
      return;
    }
    final rent = double.tryParse(rentStr);
    if (rent == null || rent <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid rent amount')),
      );
      return;
    }
    final seats = int.tryParse(seatsStr);
    if (seats == null || seats <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter available seats count')),
      );
      return;
    }

    final totalRentStr = _totalRentController.text.trim();
    final totalRent = double.tryParse(totalRentStr);
    final capacity = int.tryParse(_capacityController.text.trim());

    setState(() => _isSubmitting = true);
    try {
      await _repository.saveAd(
        id: widget.ad?.id,
        title: title,
        rentPerSeat: rent,
        rentTotal: totalRent,
        seatsAvailable: seats,
        roomCapacity: capacity,
        roomType: _roomType,
        city: _cityController.text.trim(),
        area: _areaController.text.trim(),
        location: _locationController.text.trim(),
        hideAddress: _hideAddress,
        description: _descriptionController.text.trim(),
        contactPhone: _phoneController.text.trim(),
        contactWhatsapp: _whatsappController.text.trim(),
        amenities: _selectedAmenities.toList(),
        newImagePaths: _newImages.map((x) => x.path).toList(),
        removeImageIds: _removedImageIds,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.ad == null
                ? 'Seat ad posted successfully!'
                : 'Seat ad updated successfully!',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save ad: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // --- ROOM TYPE BOTTOM SHEET ---
  void _showRoomTypeBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.paperRaised,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.paperLine,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Room Type',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Choose the layout that best describes your space',
                style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
              ),
              const SizedBox(height: 16),
              ..._roomTypesInfo.map((info) {
                final isSelected = _roomType == info['type'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () {
                      setState(() => _roomType = info['type']!);
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFFF8F2)
                            : AppColors.paper,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.brandDark
                              : AppColors.paperLine,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.brandDark
                                  : AppColors.paperLine.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getRoomTypeIcon(info['type']!),
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.inkSoft,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  info['title']!,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected
                                        ? AppColors.brandDark
                                        : AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  info['subtitle']!,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.inkSoft,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _customRadio(isSelected),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // --- AMENITIES BOTTOM SHEET ---
  void _showAmenitiesBottomSheet(BuildContext context) {
    final tempSelected = Set<String>.from(_selectedAmenities);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctxState, setSheetState) {
            final allChecked = tempSelected.length == _availableAmenitiesList.length;
            return Container(
              height: MediaQuery.of(context).size.height * 0.72,
              decoration: const BoxDecoration(
                color: AppColors.paperRaised,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.paperLine,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Amenities & Facilities',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.ink,
                              ),
                            ),
                            Text(
                              'Selected ${tempSelected.length} of ${_availableAmenitiesList.length}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.brandDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            setSheetState(() {
                              if (allChecked) {
                                tempSelected.clear();
                              } else {
                                tempSelected.addAll(
                                  _availableAmenitiesList.map(
                                    (e) => e['name'] as String,
                                  ),
                                );
                              }
                            });
                          },
                          child: Text(
                            allChecked ? 'Deselect All' : 'Select All',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.brandDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1, color: AppColors.paperLine),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: _availableAmenitiesList.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = _availableAmenitiesList[index];
                        final String name = item['name'];
                        final IconData icon = item['icon'];
                        final isChecked = tempSelected.contains(name);

                        return InkWell(
                          onTap: () {
                            setSheetState(() {
                              if (isChecked) {
                                tempSelected.remove(name);
                              } else {
                                tempSelected.add(name);
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isChecked
                                  ? const Color(0xFFFFF8F2)
                                  : AppColors.paper,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isChecked
                                    ? AppColors.brandDark
                                    : AppColors.paperLine,
                                width: isChecked ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isChecked
                                        ? AppColors.brandSoft
                                        : AppColors.paperLine.withValues(
                                            alpha: 0.4,
                                          ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    icon,
                                    size: 18,
                                    color: isChecked
                                        ? AppColors.brandDark
                                        : AppColors.inkSoft,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isChecked
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: isChecked
                                          ? AppColors.ink
                                          : AppColors.inkSoft,
                                    ),
                                  ),
                                ),
                                _customCheckbox(isChecked),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          setState(() {
                            _selectedAmenities.clear();
                            _selectedAmenities.addAll(tempSelected);
                          });
                          Navigator.pop(ctx);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.brandDark,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Apply Selection (${tempSelected.length})',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.ad != null;

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paperRaised,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isEdit ? 'Edit Seat Listing' : 'Post New Seat Listing',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.paperLine, height: 1),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- MEDIA / PHOTO UPLOAD SECTION ON TOP ---
                    _buildImageSection(),
                    const SizedBox(height: 20),

                    // --- SECTION 1: BASIC INFORMATION ---
                    _buildFormCard(
                      title: 'BASIC INFORMATION',
                      icon: Icons.info_outline_rounded,
                      children: [
                        _fieldLabel('AD TITLE *'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _titleController,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            hintText:
                                'e.g. 2 seats available in student mess — Mirpur 10',
                            prefixIcon: Icon(
                              Icons.subtitles_outlined,
                              size: 20,
                              color: AppColors.inkFaded,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _fieldLabel('RENT PER SEAT (৳) *'),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: _rentController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      hintText: 'e.g. 3500',
                                      prefixIcon: Icon(
                                        Icons.payments_outlined,
                                        size: 20,
                                        color: AppColors.inkFaded,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _fieldLabel('TOTAL ROOM RENT (৳)'),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: _totalRentController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      hintText: 'e.g. 10500',
                                      prefixIcon: Icon(
                                        Icons.price_change_outlined,
                                        size: 20,
                                        color: AppColors.inkFaded,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _fieldLabel('OPEN SEATS *'),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: _seatsController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      hintText: 'e.g. 2',
                                      prefixIcon: Icon(
                                        Icons.event_seat_outlined,
                                        size: 20,
                                        color: AppColors.inkFaded,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _fieldLabel('ROOM CAPACITY'),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: _capacityController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      hintText: 'e.g. 3 persons',
                                      prefixIcon: Icon(
                                        Icons.groups_outlined,
                                        size: 20,
                                        color: AppColors.inkFaded,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // --- SECTION 2: ROOM TYPE & AMENITIES CARD ---
                    _buildFormCard(
                      title: 'ROOM & FACILITIES',
                      icon: Icons.king_bed_outlined,
                      children: [
                        _fieldLabel('ROOM TYPE *'),
                        const SizedBox(height: 8),
                        _buildRoomTypeSelector(),
                        const SizedBox(height: 16),

                        _fieldLabel('AMENITIES & FACILITIES'),
                        const SizedBox(height: 8),
                        _buildAmenitiesSelector(),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // --- SECTION 3: LOCATION & PRIVACY ---
                    _buildFormCard(
                      title: 'LOCATION & ADDRESS',
                      icon: Icons.location_on_outlined,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _fieldLabel('CITY *'),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: _cityController,
                                    decoration: const InputDecoration(
                                      hintText: 'e.g. Dhaka',
                                      prefixIcon: Icon(
                                        Icons.location_city_outlined,
                                        size: 20,
                                        color: AppColors.inkFaded,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _fieldLabel('AREA / THANA'),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: _areaController,
                                    decoration: const InputDecoration(
                                      hintText: 'e.g. Mirpur 10',
                                      prefixIcon: Icon(
                                        Icons.map_outlined,
                                        size: 20,
                                        color: AppColors.inkFaded,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _fieldLabel('STREET ADDRESS / BUILDING LOCATION'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            hintText:
                                'e.g. House 14, Road 3, Block A, Mirpur 10',
                            prefixIcon: Icon(
                              Icons.home_outlined,
                              size: 20,
                              color: AppColors.inkFaded,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.paper,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.paperLine),
                          ),
                          child: SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 2,
                            ),
                            activeTrackColor: AppColors.brandDark,
                            title: const Text(
                              'Hide street address for privacy',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            subtitle: const Text(
                              'Only area & city will be visible on public listing',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.inkFaded,
                              ),
                            ),
                            value: _hideAddress,
                            onChanged: (val) =>
                                setState(() => _hideAddress = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // --- SECTION 4: DESCRIPTION & CONTACT ---
                    _buildFormCard(
                      title: 'DESCRIPTION & CONTACT',
                      icon: Icons.contact_phone_outlined,
                      children: [
                        _fieldLabel('ADDITIONAL DETAILS & RULES'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _descriptionController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText:
                                'Describe room environment, student/jobholder preference, university proximity, rules, etc.',
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _fieldLabel('CONTACT PHONE'),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    decoration: const InputDecoration(
                                      hintText: '01700000000',
                                      prefixIcon: Icon(
                                        Icons.phone_outlined,
                                        size: 20,
                                        color: AppColors.inkFaded,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _fieldLabel('WHATSAPP NUMBER'),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: _whatsappController,
                                    keyboardType: TextInputType.phone,
                                    decoration: const InputDecoration(
                                      hintText: '01700000000',
                                      prefixIcon: Icon(
                                        Icons.chat_bubble_outline_rounded,
                                        size: 20,
                                        color: AppColors.inkFaded,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // --- STICKY BOTTOM ACTION BAR ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.paperRaised,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
                border: const Border(
                  top: BorderSide(color: AppColors.paperLine),
                ),
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _submitForm,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isEdit ? 'Save Changes' : 'Publish Seat Listing',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- IMAGE SECTION BUILDER ---
  Widget _buildImageSection() {
    final hasImages = _totalImageCount > 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.paperRaised,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.paperLine),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.add_a_photo_outlined,
                    color: AppColors.brandDark,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'PROPERTY PHOTOS',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_totalImageCount / 6 Photos',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brandDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (!hasImages)
            InkWell(
              onTap: _pickImages,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.brandDark.withValues(alpha: 0.4),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: AppColors.brandSoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cloud_upload_outlined,
                        color: AppColors.brandDark,
                        size: 26,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Upload Room & Mess Photos',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tap to add up to 6 high quality images. First photo will be the cover.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11.5, color: AppColors.inkFaded),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Main Cover Image Preview
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _buildCoverImageWidget(),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.3),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.5),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brandDark,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.star_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'PRIMARY COVER',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Thumbnail Carousel / Grid Strip
            SizedBox(
              height: 70,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // Existing remote images
                  for (int i = 0; i < _existingImages.length; i++)
                    _buildThumbnailTile(
                      isCover: i == 0,
                      imageWidget: Image.network(
                        _existingImages[i].url,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: AppColors.paperLine,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                      onDelete: () => _removeExistingImage(i),
                    ),

                  // Newly picked local images
                  for (int i = 0; i < _newImages.length; i++)
                    _buildThumbnailTile(
                      isCover: _existingImages.isEmpty && i == 0,
                      imageWidget: Image.file(
                        File(_newImages[i].path),
                        fit: BoxFit.cover,
                      ),
                      onDelete: () => _removeNewImage(i),
                    ),

                  // Add Photo Button Tile
                  if (_totalImageCount < 6)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: _pickImages,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: AppColors.paper,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.brandDark,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                color: AppColors.brandDark,
                                size: 22,
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Add Photo',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.brandDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCoverImageWidget() {
    if (_existingImages.isNotEmpty) {
      return Image.network(
        _existingImages.first.url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: AppColors.paperLine,
          child: const Center(child: Icon(Icons.broken_image_outlined, size: 36)),
        ),
      );
    } else if (_newImages.isNotEmpty) {
      return Image.file(
        File(_newImages.first.path),
        fit: BoxFit.cover,
      );
    }
    return const SizedBox();
  }

  Widget _buildThumbnailTile({
    required bool isCover,
    required Widget imageWidget,
    required VoidCallback onDelete,
  }) {
    return Container(
      width: 70,
      height: 70,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox.expand(child: imageWidget),
          ),
          if (isCover)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: AppColors.brandDark.withValues(alpha: 0.85),
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: const Text(
                  'COVER',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- ROOM TYPE FIELD SELECTOR CARD ---
  Widget _buildRoomTypeSelector() {
    final currentInfo = _roomTypesInfo.firstWhere(
      (element) => element['type'] == _roomType,
      orElse: () => _roomTypesInfo.first,
    );

    return InkWell(
      onTap: () => _showRoomTypeBottomSheet(context),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.paperLine),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.brandSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getRoomTypeIcon(currentInfo['type']!),
                size: 20,
                color: AppColors.brandDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentInfo['title']!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currentInfo['subtitle']!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.inkFaded,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.brandSoft.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Text(
                    'Change',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandDark,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(
                    Icons.unfold_more_rounded,
                    size: 16,
                    color: AppColors.brandDark,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- AMENITIES FIELD SELECTOR CARD ---
  Widget _buildAmenitiesSelector() {
    return InkWell(
      onTap: () => _showAmenitiesBottomSheet(context),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.paperLine),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.checklist_rounded,
                  size: 20,
                  color: AppColors.brandDark,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_selectedAmenities.length} Amenities Selected',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brandSoft.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Text(
                        'Customize',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.brandDark,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Icons.edit_note_rounded,
                        size: 16,
                        color: AppColors.brandDark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_selectedAmenities.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _selectedAmenities.map((name) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.brandSoft,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.brandDark.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 12,
                          color: AppColors.brandDark,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brandDark,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- HELPERS & COMPONENTS ---
  Widget _buildFormCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.paperRaised,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.paperLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.brandDark, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppColors.inkSoft,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.paperLine),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: AppColors.inkSoft,
      ),
    );
  }

  IconData _getRoomTypeIcon(String type) {
    switch (type) {
      case 'single':
        return Icons.person_outline_rounded;
      case 'semi-private':
        return Icons.door_front_door_outlined;
      case 'bunk':
        return Icons.single_bed_outlined;
      case 'shared':
      default:
        return Icons.king_bed_outlined;
    }
  }

  Widget _customRadio(bool selected) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.brandDark : AppColors.inkFaded,
          width: selected ? 6 : 2,
        ),
        color: Colors.white,
      ),
    );
  }

  Widget _customCheckbox(bool checked) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: checked ? AppColors.brandDark : Colors.transparent,
        border: Border.all(
          color: checked ? AppColors.brandDark : AppColors.inkFaded,
          width: 2,
        ),
      ),
      child: checked
          ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
          : null,
    );
  }
}
