import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/auth_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/member_model.dart';
import '../cubit/member_cubit.dart';

class MemberFormScreen extends StatefulWidget {
  final MemberModel? member;
  final int messId;
  final MemberCubit cubit;

  const MemberFormScreen({
    super.key,
    this.member,
    required this.messId,
    required this.cubit,
  });

  @override
  State<MemberFormScreen> createState() => _MemberFormScreenState();
}

class _MemberFormScreenState extends State<MemberFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  String? _selectedAvatarPath;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _breakfastController;
  late TextEditingController _lunchController;
  late TextEditingController _dinnerController;
  late TextEditingController _legacyMealController;

  late String _role;
  late String _bazarDay;
  bool _isSaving = false;
  bool _showLegacyMeal = false;

  bool get _isBldMode {
    final m = widget.member;
    if (m == null) return false;
    return m.defaultBreakfast != null ||
        m.defaultLunch != null ||
        m.defaultDinner != null;
  }

  bool get _isSelf {
    final m = widget.member;
    if (m == null) return false;
    final me = AuthStorage.cachedUser;
    if (me == null) return false;
    if (m.userId != null && me.id != 0 && m.userId == me.id) return true;
    if (m.email.isNotEmpty && me.email.toLowerCase() == m.email.toLowerCase()) {
      return true;
    }
    return false;
  }

  final List<Map<String, String>> _daysOptions = const [
    {'value': '1', 'label': 'Saturday (Day 1)'},
    {'value': '2', 'label': 'Sunday (Day 2)'},
    {'value': '3', 'label': 'Monday (Day 3)'},
    {'value': '4', 'label': 'Tuesday (Day 4)'},
    {'value': '5', 'label': 'Wednesday (Day 5)'},
    {'value': '6', 'label': 'Thursday (Day 6)'},
    {'value': '7', 'label': 'Friday (Day 7)'},
  ];

  @override
  void initState() {
    super.initState();
    final m = widget.member;
    _nameController = TextEditingController(text: m?.name ?? '');
    _emailController = TextEditingController(text: m?.email ?? '');
    _breakfastController = TextEditingController(
      text: m?.defaultBreakfast != null
          ? _fmtDefault(m!.defaultBreakfast!)
          : '',
    );
    _lunchController = TextEditingController(
      text: m?.defaultLunch != null ? _fmtDefault(m!.defaultLunch!) : '',
    );
    _dinnerController = TextEditingController(
      text: m?.defaultDinner != null ? _fmtDefault(m!.defaultDinner!) : '',
    );
    _legacyMealController = TextEditingController(
      text: (m != null && !_isBldMode && m.defaultMeal != null)
          ? _fmtDefault(m.defaultMeal!)
          : '',
    );
    _showLegacyMeal = m != null && !_isBldMode && m.defaultMeal != null;
    _role = m?.role.toLowerCase() == 'manager' ? 'manager' : 'member';
    _bazarDay = m?.bazarDay ?? '1';
  }

  String _fmtDefault(double v) {
    final s = v.toStringAsFixed(2);
    return s.replaceAll(RegExp(r'\.?0+$'), '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _breakfastController.dispose();
    _lunchController.dispose();
    _dinnerController.dispose();
    _legacyMealController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _selectedAvatarPath = picked.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick avatar image: $e')),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final isOwner = widget.member?.isOwner ?? false;
    final data = <String, dynamic>{
      'mess_id': widget.messId,
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'bazar_day': _bazarDay,
    };
    if (widget.member == null) {
      data['role'] = _role;
    } else if (!_isSelf && !isOwner) {
      data['role'] = _role;
    }

    // Web-parity: hasBldDefault — if any B/L/D field is explicitly sent (even "0" = OFF),
    // we enter B/L/D mode. Empty string means "no default" (null) so leaving a field blank clears it.
    // When entering B/L/D mode we must send all three keys so the backend doesn't keep stale values.
    final bRaw = _breakfastController.text.trim();
    final lRaw = _lunchController.text.trim();
    final dRaw = _dinnerController.text.trim();
    final hasAnyBldInput =
        bRaw.isNotEmpty || lRaw.isNotEmpty || dRaw.isNotEmpty || _isBldMode;
    if (hasAnyBldInput) {
      data['default_breakfast'] = bRaw.isEmpty ? '' : bRaw;
      data['default_lunch'] = lRaw.isEmpty ? '' : lRaw;
      data['default_dinner'] = dRaw.isEmpty ? '' : dRaw;
    } else if (_legacyMealController.text.trim().isNotEmpty) {
      data['default_meal'] = _legacyMealController.text.trim();
    } else if (widget.member != null) {
      // On edit, if user cleared all B/L/D and legacy, don't send anything — keeps existing.
      // To explicitly clear, backend expects empty string; we only send when user touched.
    }

    final success = await widget.cubit.saveMember(
      id: widget.member?.id,
      data: data,
      avatarPath: _selectedAvatarPath,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.member != null
                  ? 'Member updated successfully'
                  : 'Member added & invite sent',
            ),
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.member != null;
    final isOwner = widget.member?.isOwner == true;

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paperRaised,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: Text(
          isEdit ? 'Edit Mess Member' : 'Add New Member',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- AVATAR PICKER SECTION ---
                Center(
                  child: GestureDetector(
                    onTap: _pickAvatar,
                    child: Stack(
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.brandSoft,
                            border: Border.all(
                              color: AppColors.brandDark,
                              width: 2.5,
                            ),
                          ),
                          child: ClipOval(
                            child: _selectedAvatarPath != null
                                ? Image.file(
                                    File(_selectedAvatarPath!),
                                    fit: BoxFit.cover,
                                  )
                                : widget.member?.avatarUrl != null
                                ? Image.network(
                                    widget.member!.avatarUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            _avatarInitials(),
                                  )
                                : _avatarInitials(),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: const BoxDecoration(
                              color: AppColors.brandDark,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Tap to select profile photo',
                    style: TextStyle(fontSize: 12, color: AppColors.inkFaded),
                  ),
                ),
                const SizedBox(height: 24),

                // --- MEMBER NAME & EMAIL ---
                const Text(
                  'FULL NAME *',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.inkFaded,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Name is required' : null,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Sadman Sakib',
                    prefixIcon: Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.inkFaded,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'EMAIL ADDRESS *',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.inkFaded,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                  decoration: const InputDecoration(
                    hintText: 'member@example.com',
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: AppColors.inkFaded,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // --- MEMBER ROLE SELECTOR ---
                const Text(
                  'MESS MEMBER ROLE *',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.inkFaded,
                  ),
                ),
                const SizedBox(height: 8),
                if (isOwner)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.brandSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.workspace_premium_rounded,
                          color: AppColors.brandDark,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'MESS OWNER (Role locked)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.brandDark,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_isSelf)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.paperLine,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lock_rounded, color: AppColors.inkFaded),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your own role cannot be changed by yourself',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.inkFaded,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: _roleOptionTile(
                          title: 'Member',
                          subtitle: 'Standard View',
                          value: 'member',
                          icon: Icons.person_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _roleOptionTile(
                          title: 'Manager',
                          subtitle: 'Full Ledger Access',
                          value: 'manager',
                          icon: Icons.admin_panel_settings_rounded,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 20),

                // --- BAZAR DUTY DAY ---
                const Text(
                  'ASSIGNED BAZAR DAY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.inkFaded,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _bazarDay,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(
                      Icons.calendar_today_rounded,
                      color: AppColors.inkFaded,
                    ),
                  ),
                  items: _daysOptions
                      .map(
                        (opt) => DropdownMenuItem(
                          value: opt['value'],
                          child: Text(opt['label']!),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _bazarDay = val);
                  },
                ),
                const SizedBox(height: 24),

                // --- DEFAULT MEALS BREAKDOWN B/L/D — web parity (#memberEditModal) ---
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.paperRaised,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.paperLine),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.restaurant_rounded,
                            size: 18,
                            color: AppColors.brandDark,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'DEFAULT DAILY MEAL COUNT (B · L · D)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '0 = OFF for that slot (red). Empty = no default. If any B/L/D is set (even 0), B·L·D is used; else legacy total.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.inkFaded,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _mealInputCell(
                              'B\'FAST (0=OFF)',
                              _breakfastController,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _mealInputCell(
                              'LUNCH (0=OFF)',
                              _lunchController,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _mealInputCell(
                              'DINNER (0=OFF)',
                              _dinnerController,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () =>
                            setState(() => _showLegacyMeal = !_showLegacyMeal),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.paper,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.paperLine),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.history_rounded,
                                size: 14,
                                color: AppColors.inkFaded,
                              ),
                              const SizedBox(width: 6),
                              const Expanded(
                                child: Text(
                                  'Legacy total — Default meal',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.inkFaded,
                                  ),
                                ),
                              ),
                              Icon(
                                _showLegacyMeal
                                    ? Icons.expand_less_rounded
                                    : Icons.expand_more_rounded,
                                size: 18,
                                color: AppColors.inkFaded,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_showLegacyMeal) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Used only if all three B/L/D above are empty. 0 is ignored for total.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.inkFaded,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _legacyMealController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'e.g. 2.00',
                            prefixIcon: Icon(
                              Icons.restaurant_outlined,
                              size: 18,
                              color: AppColors.inkFaded,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // --- SUBMIT BUTTON WITH CENTERED SPINNER ---
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _submitForm,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandDark,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSaving
                        ? const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            isEdit
                                ? 'Save Member Changes'
                                : 'Add & Send Invite',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatarInitials() {
    final name = _nameController.text.trim();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'M';
    return Container(
      color: AppColors.brandDark,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _roleOptionTile({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
  }) {
    final selected = _role == value;
    return InkWell(
      onTap: () => setState(() => _role = value),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandSoft : AppColors.paperRaised,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.brandDark : AppColors.paperLine,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? AppColors.brandDark : AppColors.inkFaded,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: selected ? AppColors.brandDark : AppColors.ink,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.inkFaded,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mealInputCell(String label, TextEditingController controller) {
    final isOff =
        controller.text.trim() == '0' ||
        controller.text.trim() == '0.0' ||
        controller.text.trim() == '0.00';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: AppColors.inkFaded,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          onChanged: (_) => setState(() {}),
          style: TextStyle(
            fontWeight: isOff ? FontWeight.w900 : FontWeight.w600,
            color: isOff ? const Color(0xFFB91C1C) : AppColors.ink,
          ),
          decoration: InputDecoration(
            hintText: '—',
            filled: isOff,
            fillColor: isOff ? const Color(0xFFFEE2E2) : null,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: 8,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isOff ? const Color(0xFFFCA5A5) : AppColors.paperLine,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isOff ? const Color(0xFFDC2626) : AppColors.brandDark,
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
