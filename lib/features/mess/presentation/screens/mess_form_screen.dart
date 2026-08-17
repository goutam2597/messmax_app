import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/mess_cubit.dart';
import '../../data/models/mess_model.dart';

class MessFormScreen extends StatefulWidget {
  final MessModel? mess;
  final MessCubit cubit;
  const MessFormScreen({super.key, this.mess, required this.cubit});

  @override
  State<MessFormScreen> createState() => _MessFormScreenState();
}

class _MessFormScreenState extends State<MessFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _location;
  late TextEditingController _billingDay;
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
  }

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _billingDay.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final payload = <String, dynamic>{
      'name': _name.text.trim(),
      'location': _location.text.trim(),
      'timezone': _timezone,
      'billing_start_day': int.tryParse(_billingDay.text.trim()) ?? 1,
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
              widget.mess == null ? 'Mess created' : 'Mess updated',
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
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paperRaised,
        elevation: 0,
        title: Text(
          isEdit ? 'Edit Mess' : 'Create Mess',
          style: const TextStyle(
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
                      const Text(
                        'BASIC INFORMATION',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppColors.inkFaded,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'MESS NAME *',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.inkFaded,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _name,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Name required'
                            : null,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Green View Hostel',
                          prefixIcon: Icon(
                            Icons.apartment_rounded,
                            color: AppColors.inkFaded,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'LOCATION / CITY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.inkFaded,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _location,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Mirpur 10, Dhaka',
                          prefixIcon: Icon(
                            Icons.location_on_outlined,
                            color: AppColors.inkFaded,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
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
                      const Text(
                        'BILLING & TIMEZONE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppColors.inkFaded,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'TIMEZONE *',
                        style: TextStyle(
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
                      const SizedBox(height: 14),
                      const Text(
                        'BILLING CYCLE START DAY (1..28)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.inkFaded,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _billingDay,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '1'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandDark,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _saving
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
                            isEdit ? 'Save Changes' : 'Create Mess',
                            style: const TextStyle(fontWeight: FontWeight.w800),
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
}
