import 'package:flutter/material.dart';
import '../../../../core/locale/app_translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../data/models/mess_model.dart';
import '../cubit/mess_cubit.dart';
import '../../../dashboard/presentation/widgets/dash_ui.dart';

class MessFormScreen extends StatefulWidget {
  final MessModel? mess;
  final MessCubit cubit;
  final bool isBottomSheet;
  final bool isDialog;
  final bool isIndividual;

  const MessFormScreen({
    super.key,
    this.mess,
    required this.cubit,
    this.isBottomSheet = false,
    this.isDialog = false,
    this.isIndividual = false,
  });

  static Future<bool?> showAsDialog(
    BuildContext context, {
    MessModel? mess,
    required MessCubit cubit,
    bool isIndividual = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.paperRaised,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 24,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DashUI.rCard),
          side: const BorderSide(color: AppColors.paperLine),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 520,
            maxHeight: MediaQuery.of(ctx).size.height * 0.90,
          ),
          child: MessFormScreen(
            mess: mess,
            cubit: cubit,
            isDialog: true,
            isIndividual: isIndividual,
          ),
        ),
      ),
    );
  }

  static Future<bool?> showAsBottomSheet(
    BuildContext context, {
    MessModel? mess,
    required MessCubit cubit,
    bool isIndividual = false,
  }) {
    return showAsDialog(context, mess: mess, cubit: cubit, isIndividual: isIndividual);
  }

  @override
  State<MessFormScreen> createState() => _MessFormScreenState();
}

class _MessFormScreenState extends State<MessFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _location;
  late TextEditingController _billingDay;
  DateTime? _billingStartDate;
  DateTime? _billingEndDate;
  String _timezone = 'Asia/Dhaka';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.mess?.name ?? '');
    _location = TextEditingController(text: widget.mess?.location ?? '');
    _billingDay = TextEditingController(
      text: widget.mess != null ? '${widget.mess!.billingStartDay}' : '1',
    );
    _timezone = widget.mess?.timezone ?? 'Asia/Dhaka';

    if (widget.mess?.billingStartDate != null &&
        widget.mess!.billingStartDate!.isNotEmpty) {
      try {
        _billingStartDate = DateTime.parse(widget.mess!.billingStartDate!);
      } catch (_) {}
    }
    if (widget.mess?.billingEndDate != null &&
        widget.mess!.billingEndDate!.isNotEmpty) {
      try {
        _billingEndDate = DateTime.parse(widget.mess!.billingEndDate!);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _billingDay.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '';
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _billingStartDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
      helpText: 'SELECT BILLING START DATE',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.brandDark,
              onPrimary: Colors.white,
              onSurface: AppColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _billingStartDate = picked;
        _billingDay.text = '${picked.day}';
        if (_billingEndDate != null && _billingEndDate!.isBefore(picked)) {
          _billingEndDate = picked.add(const Duration(days: 29));
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final initial = _billingEndDate ??
        (_billingStartDate?.add(const Duration(days: 29)) ?? now);
    final first = _billingStartDate ?? DateTime(now.year - 2);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first) ? first : initial,
      firstDate: first,
      lastDate: DateTime(now.year + 5),
      helpText: 'SELECT BILLING END DATE',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.brandDark,
              onPrimary: Colors.white,
              onSurface: AppColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _billingEndDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final payload = <String, dynamic>{
      'name': _name.text.trim(),
      'location': _location.text.trim(),
      'timezone': _timezone,
      'billing_start_day': int.tryParse(_billingDay.text.trim()) ?? 1,
      if (_billingStartDate != null)
        'billing_start_date': _formatDate(_billingStartDate),
      if (_billingEndDate != null)
        'billing_end_date': _formatDate(_billingEndDate),
    };

    bool ok;
    if (widget.mess == null) {
      ok = await widget.cubit.createMess(payload);
    } else {
      ok = await widget.cubit.updateMess(widget.mess!.id, payload);
    }
    if (mounted) {
      setState(() => _saving = false);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.mess == null ? 'ui.mess_created'.tr2 : 'ui.mess_updated_success'.tr2,
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.mess != null;
    final isModal = widget.isDialog || widget.isBottomSheet;

    final formFields = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Section 1: Basic info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.paperRaised,
              borderRadius: BorderRadius.circular(DashUI.rCard),
              border: Border.all(color: AppColors.paperLine),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ui.mess_basic_info'.tr2,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.inkFaded,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'ui.mess_name_required'.tr2,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.inkFaded,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _name,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'ui.mess_name_required_error'.tr2 : null,
                  decoration: InputDecoration(
                    hintText: 'ui.mess_name_hint'.tr2,
                    prefixIcon: const Icon(
                      Icons.apartment_rounded,
                      color: AppColors.inkFaded,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'ui.mess_location_label'.tr2,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.inkFaded,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _location,
                  decoration: InputDecoration(
                    hintText: 'ui.mess_location_hint'.tr2,
                    prefixIcon: const Icon(
                      Icons.location_on_outlined,
                      color: AppColors.inkFaded,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Section 2: Billing & Schedule with Calendar Range Pickers
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.paperRaised,
              borderRadius: BorderRadius.circular(DashUI.rCard),
              border: Border.all(color: AppColors.paperLine),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'ui.mess_billing_cycle_schedule'.tr2,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppColors.inkFaded,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (_billingStartDate != null && _billingEndDate != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.brandSoft,
                          borderRadius: BorderRadius.circular(DashUI.rBtn),
                          border: Border.all(
                            color: AppColors.brandDark.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          '${(_billingEndDate!.difference(_billingStartDate!).inDays + 1).toString().toBnNum()} ${'ui.days_cycle'.tr2}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.brandDark,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                // Calendar Start & End Date pickers
                Row(
                  children: [
                    // Start Date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ui.mess_billing_start_date'.tr2,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.inkFaded,
                            ),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: _pickStartDate,
                            borderRadius: BorderRadius.circular(DashUI.rTile),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 11,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.paper,
                                borderRadius: BorderRadius.circular(DashUI.rTile),
                                border: Border.all(
                                  color: _billingStartDate != null
                                      ? AppColors.brandDark
                                      : AppColors.paperLine,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 16,
                                    color: _billingStartDate != null
                                        ? AppColors.brandDark
                                        : AppColors.inkFaded,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _billingStartDate != null
                                          ? _formatDate(_billingStartDate)
                                          : 'ui.mess_select_start'.tr2,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: _billingStartDate != null
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: _billingStartDate != null
                                            ? AppColors.ink
                                            : AppColors.inkFaded,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (_billingStartDate != null)
                                    GestureDetector(
                                      onTap: () => setState(() {
                                        _billingStartDate = null;
                                      }),
                                      child: const Icon(
                                        Icons.close_rounded,
                                        size: 15,
                                        color: AppColors.inkFaded,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // End Date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ui.mess_billing_end_date'.tr2,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.inkFaded,
                            ),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: _pickEndDate,
                            borderRadius: BorderRadius.circular(DashUI.rTile),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 11,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.paper,
                                borderRadius: BorderRadius.circular(DashUI.rTile),
                                border: Border.all(
                                  color: _billingEndDate != null
                                      ? AppColors.brandDark
                                      : AppColors.paperLine,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.event_available_rounded,
                                    size: 16,
                                    color: _billingEndDate != null
                                        ? AppColors.brandDark
                                        : AppColors.inkFaded,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _billingEndDate != null
                                          ? _formatDate(_billingEndDate)
                                          : 'ui.mess_select_end'.tr2,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: _billingEndDate != null
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: _billingEndDate != null
                                            ? AppColors.ink
                                            : AppColors.inkFaded,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (_billingEndDate != null)
                                    GestureDetector(
                                      onTap: () => setState(() {
                                        _billingEndDate = null;
                                      }),
                                      child: const Icon(
                                        Icons.close_rounded,
                                        size: 15,
                                        color: AppColors.inkFaded,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'ui.mess_custom_range_desc'.tr2,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.inkFaded,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),

                // Fallback Cycle Start Day
                Text(
                  'ui.mess_default_cycle_day'.tr2,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.inkFaded,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _billingDay,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: '1',
                    prefixIcon: Icon(
                      Icons.calendar_month_outlined,
                      color: AppColors.inkFaded,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Timezone
                Text(
                  'ui.mess_timezone_required'.tr2,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.inkFaded,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _timezone,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(
                      Icons.public_rounded,
                      color: AppColors.inkFaded,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Asia/Dhaka',
                      child: Text('Asia/Dhaka (GMT+6)'),
                    ),
                    DropdownMenuItem(
                      value: 'Asia/Kolkata',
                      child: Text('Asia/Kolkata (GMT+5:30)'),
                    ),
                    DropdownMenuItem(value: 'UTC', child: Text('UTC')),
                  ],
                  onChanged: (v) =>
                      setState(() => _timezone = v ?? 'Asia/Dhaka'),
                ),
                const SizedBox(height: 4),
                Text(
                  'ui.mess_timezone_desc'.tr2,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.inkFaded,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      isEdit
                          ? Icons.check_circle_outline_rounded
                          : Icons.add_rounded,
                      size: 18,
                    ),
              label: Text(
                _saving
                    ? (isEdit
                        ? 'ui.saving'.tr2
                        : (widget.isIndividual ? 'ui.setting_up'.tr2 : 'ui.creating'.tr2))
                    : (isEdit
                        ? 'ui.save_changes'.tr2
                        : (widget.isIndividual ? 'ui.setup_mess'.tr2 : 'ui.create_new_mess'.tr2)),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DashUI.rTile),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (isModal) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 14, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brandSoft,
                    borderRadius: BorderRadius.circular(DashUI.rTile),
                  ),
                  child: Icon(
                    isEdit ? Icons.edit_note_rounded : Icons.domain_rounded,
                    color: AppColors.brandDark,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEdit
                            ? 'ui.edit_mess_details'.tr2
                            : (widget.isIndividual
                                ? 'ui.setup_new_mess'.tr2
                                : 'ui.create_new_mess'.tr2),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        isEdit
                            ? 'ui.edit_mess_subtitle'.tr2
                            : (widget.isIndividual
                                ? 'ui.setup_mess_sub'.tr2
                                : 'ui.create_mess_sub'.tr2),
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.inkFaded,
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(DashUI.rCard),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.paperLine),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.paperLine),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: formFields,
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paperRaised,
        elevation: 0,
        leading: const AppBackButton(),
        title: Text(
          isEdit ? 'ui.edit_mess_details'.tr2 : 'ui.create_new_mess'.tr2,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: formFields,
        ),
      ),
    );
  }
}
