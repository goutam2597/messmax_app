import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _isSubmitting = false;

  final _titleController = TextEditingController();
  final _cityController = TextEditingController();
  final _areaController = TextEditingController();
  final _locationController = TextEditingController();
  final _rentController = TextEditingController();
  final _seatsController = TextEditingController();
  final _capacityController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();

  String _roomType = 'shared';
  bool _hideAddress = false;
  final Set<String> _selectedAmenities = {'WiFi', 'Meal'};

  static const _availableAmenities = [
    'WiFi',
    'Attached bath',
    'Meal',
    'CC TV',
    'AC',
    'Lift',
    'Fridge',
    'Generator',
    'Laundry',
    'Parking',
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
    _seatsController.dispose();
    _capacityController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    super.dispose();
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

    setState(() => _isSubmitting = true);
    try {
      await _repository.saveAd(
        id: widget.ad?.id,
        title: title,
        rentPerSeat: rent,
        seatsAvailable: seats,
        roomType: _roomType,
        city: _cityController.text.trim(),
        area: _areaController.text.trim(),
        location: _locationController.text.trim(),
        hideAddress: _hideAddress,
        description: _descriptionController.text.trim(),
        contactPhone: _phoneController.text.trim(),
        contactWhatsapp: _whatsappController.text.trim(),
        amenities: _selectedAmenities.toList(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.ad == null ? 'Seat ad posted successfully!' : 'Seat ad updated!')),
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

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.ad != null;
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isEdit ? 'Edit Seat Ad' : 'Post New Seat Ad',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fieldGroup('AD TITLE *', TextField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(hintText: 'e.g. 2 seats available in student mess — Mirpur 10'),
              )),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _fieldGroup('RENT PER SEAT (৳/mo) *', TextField(
                      controller: _rentController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'e.g. 3500'),
                    )),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _fieldGroup('OPEN SEATS *', TextField(
                      controller: _seatsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'e.g. 2'),
                    )),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Text('ROOM TYPE *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.inkSoft)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _roomTypeChip('shared', 'Shared Room'),
                  _roomTypeChip('single', 'Single Room'),
                  _roomTypeChip('semi-private', 'Half Room'),
                  _roomTypeChip('bunk', 'Bunk Bed'),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _fieldGroup('CITY', TextField(
                      controller: _cityController,
                      decoration: const InputDecoration(hintText: 'e.g. Dhaka'),
                    )),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _fieldGroup('AREA / THANA', TextField(
                      controller: _areaController,
                      decoration: const InputDecoration(hintText: 'e.g. Mirpur 10'),
                    )),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _fieldGroup('STREET ADDRESS / LOCATION', TextField(
                controller: _locationController,
                decoration: const InputDecoration(hintText: 'e.g. House 14, Road 3, Block A'),
              )),
              const SizedBox(height: 8),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeTrackColor: AppColors.brandDark,
                title: const Text('Hide street address for privacy', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
                subtitle: const Text('Show area/city only; full address revealed on request.', style: TextStyle(fontSize: 11.5, color: AppColors.inkFaded)),
                value: _hideAddress,
                onChanged: (val) => setState(() => _hideAddress = val),
              ),
              const SizedBox(height: 14),

              const Text('AMENITIES & FACILITIES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.inkSoft)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableAmenities.map((amenity) {
                  final isSelected = _selectedAmenities.contains(amenity);
                  return FilterChip(
                    label: Text(amenity),
                    selected: isSelected,
                    selectedColor: AppColors.brandSoft,
                    checkmarkColor: AppColors.brandDark,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? AppColors.brandDark : AppColors.inkSoft,
                    ),
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedAmenities.add(amenity);
                        } else {
                          _selectedAmenities.remove(amenity);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              _fieldGroup('DESCRIPTION', TextField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(hintText: 'Describe room rules, environment, University proximity, etc.'),
              )),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _fieldGroup('CONTACT PHONE', TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(hintText: '01700000000'),
                    )),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _fieldGroup('WHATSAPP NUMBER', TextField(
                      controller: _whatsappController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(hintText: '01700000000'),
                    )),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: FilledButton.styleFrom(backgroundColor: AppColors.brandDark),
                  child: _isSubmitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(isEdit ? 'Save Changes' : 'Publish Seat Ad'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldGroup(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.inkSoft)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _roomTypeChip(String type, String label) {
    final isSelected = _roomType == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.brandDark,
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w800,
        color: isSelected ? Colors.white : AppColors.inkSoft,
      ),
      onSelected: (val) {
        if (val) setState(() => _roomType = type);
      },
    );
  }
}
