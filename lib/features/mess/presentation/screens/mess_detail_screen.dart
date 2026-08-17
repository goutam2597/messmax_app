import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/mess_cubit.dart';
import '../cubit/mess_state.dart';
import '../../data/repositories/mess_repository.dart';
import 'mess_form_screen.dart';
import 'mess_sheet_screen.dart';

class MessDetailScreen extends StatelessWidget {
  final int messId;
  const MessDetailScreen({super.key, required this.messId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MessCubit()..loadMess(messId),
      child: _MessDetailView(messId: messId),
    );
  }
}

class _MessDetailView extends StatelessWidget {
  final int messId;
  const _MessDetailView({required this.messId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paperRaised,
        elevation: 0,
        title: BlocBuilder<MessCubit, MessState>(
          builder: (context, state) {
            final name = state is MessDetailLoaded
                ? state.detail.mess.name
                : 'Mess';
            return Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
                fontSize: 16,
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.ink),
            onPressed: () => context.read<MessCubit>().loadMess(messId),
          ),
        ],
      ),
      body: SafeArea(
        child: BlocConsumer<MessCubit, MessState>(
          listener: (context, state) {
            if (state is MessDetailLoaded && state.message != null) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message!)));
            }
          },
          builder: (context, state) {
            if (state is MessLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.brandDark),
              );
            }
            if (state is MessError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 42,
                        color: AppColors.danger,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.inkFaded),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () =>
                            context.read<MessCubit>().loadMess(messId),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.brandDark,
                        ),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (state is MessDetailLoaded) {
              final d = state.detail;
              final mess = d.mess;
              final canManage = d.canManage;
              final members = d.members;
              final months = d.months;
              return RefreshIndicator(
                color: AppColors.brandDark,
                onRefresh: () => context.read<MessCubit>().loadMess(messId),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // header card
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.paperRaised,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.paperLine),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.brandSoft,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.apartment_rounded,
                                    color: AppColors.brandDark,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        mess.name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                      if (mess.location.isNotEmpty)
                                        Text(
                                          mess.location,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.inkFaded,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: canManage
                                        ? AppColors.brandDark
                                        : AppColors.paperLine,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    mess.displayRole.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: canManage
                                          ? Colors.white
                                          : AppColors.inkSoft,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            const Divider(
                              height: 1,
                              color: AppColors.paperLine,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _metaChip(
                                  Icons.people_outline_rounded,
                                  '${mess.membersCount} members',
                                ),
                                const SizedBox(width: 8),
                                _metaChip(
                                  Icons.calendar_month_rounded,
                                  '${mess.monthsCount} months',
                                ),
                                const SizedBox(width: 8),
                                _metaChip(Icons.public_rounded, mess.timezone),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                if (canManage) ...[
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        final ok = await Navigator.push<bool>(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => MessFormScreen(
                                              mess: mess,
                                              cubit: context.read<MessCubit>(),
                                            ),
                                          ),
                                        );
                                        if (ok == true && context.mounted) {
                                          context.read<MessCubit>().loadMess(
                                            messId,
                                          );
                                        }
                                      },
                                      icon: const Icon(
                                        Icons.edit_rounded,
                                        size: 16,
                                      ),
                                      label: const Text('Edit Mess'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                if (mess.isOwner)
                                  Expanded(
                                    child: FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AppColors.danger,
                                      ),
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Delete mess?'),
                                            content: Text(
                                              'Remove "${mess.name}" permanently?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, false),
                                                child: const Text('Cancel'),
                                              ),
                                              FilledButton(
                                                style: FilledButton.styleFrom(
                                                  backgroundColor:
                                                      AppColors.danger,
                                                ),
                                                onPressed: () =>
                                                    Navigator.pop(ctx, true),
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true &&
                                            context.mounted) {
                                          final ok = await context
                                              .read<MessCubit>()
                                              .deleteMess(mess.id);
                                          if (ok && context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text('Mess deleted'),
                                              ),
                                            );
                                            Navigator.pop(context);
                                          }
                                        }
                                      },
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 16,
                                      ),
                                      label: const Text('Delete'),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // members
                      Row(
                        children: [
                          const Icon(
                            Icons.groups_rounded,
                            size: 16,
                            color: AppColors.brandDark,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'MEMBERS (${members.length})',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              color: AppColors.inkFaded,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.paperRaised,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.paperLine),
                        ),
                        child: Column(
                          children: [
                            for (var i = 0; i < members.length; i++) ...[
                              if (i > 0)
                                const Divider(
                                  height: 1,
                                  color: AppColors.paperLine,
                                ),
                              ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _hexColor(members[i].color),
                                  child: Text(
                                    members[i].name.isNotEmpty
                                        ? members[i].name[0].toUpperCase()
                                        : 'M',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(members[i].name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                                    ),
                                    const SizedBox(width: 6),
                                    _defaultDisplayChip(members[i]),
                                  ],
                                ),
                                subtitle: Text(
                                  members[i].email.isNotEmpty ? members[i].email : '— no email —',
                                  style: const TextStyle(fontSize: 11, color: AppColors.inkFaded),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: members[i].memberRole == 'manager' ? AppColors.brandSoft : AppColors.paperLine,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    members[i].memberRole.toUpperCase(),
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: members[i].memberRole == 'manager' ? AppColors.brandDark : AppColors.inkSoft),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // months
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: AppColors.brandDark,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'MONTHLY SHEETS',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              color: AppColors.inkFaded,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const Spacer(),
                          if (canManage)
                            TextButton.icon(
                              onPressed: () =>
                                  _showCreateMonth(context, messId),
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: const Text('New Month'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (months.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.paperRaised,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.paperLine),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.calendar_month_outlined,
                                size: 36,
                                color: AppColors.inkFaded,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'No month opened yet',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (canManage)
                                FilledButton(
                                  onPressed: () =>
                                      _showCreateMonth(context, messId),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.brandDark,
                                  ),
                                  child: const Text('Open First Month'),
                                ),
                              if (!canManage)
                                const Text(
                                  'A manager creates the 1…31 day sheet.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.inkFaded,
                                  ),
                                ),
                            ],
                          ),
                        )
                      else
                        Column(
                          children: [
                            for (final m in months)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: InkWell(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MessSheetScreen(
                                        messId: messId,
                                        monthId: m.id,
                                        monthLabel: m.label,
                                      ),
                                    ),
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColors.paperRaised,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: AppColors.paperLine,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppColors.brandSoft,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.calendar_view_month_rounded,
                                            size: 18,
                                            color: AppColors.brandDark,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                m.label,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 14,
                                                  color: AppColors.ink,
                                                ),
                                              ),
                                              Text(
                                                m.cycleLabel.isNotEmpty
                                                    ? m.cycleLabel
                                                    : '${m.daysInMonth} days',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.inkFaded,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.chevron_right_rounded,
                                          color: AppColors.inkFaded,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),

                      // invites (manager only)
                      if (canManage) ...[
                        const SizedBox(height: 18),
                        const Text(
                          'INVITES',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            color: AppColors.inkFaded,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _InviteSection(messId: messId),
                      ],
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _metaChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.paperLine),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppColors.inkFaded),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateMonth(BuildContext context, int messId) {
    final yearCtrl = TextEditingController(text: '${DateTime.now().year}');
    final monthCtrl = TextEditingController(text: '${DateTime.now().month}');
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      context: context,
      builder: (ctx) {
        bool saving = false;
        return StatefulBuilder(
          builder: (context, setS) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: AppColors.paperRaised,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.paperLine,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Open New Month',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: yearCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Year'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: monthCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Month 1-12',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: saving
                          ? null
                          : () async {
                              setS(() => saving = true);
                              try {
                                await MessRepository().createMonth(messId, {
                                  'year':
                                      int.tryParse(yearCtrl.text) ??
                                      DateTime.now().year,
                                  'month':
                                      int.tryParse(monthCtrl.text) ??
                                      DateTime.now().month,
                                });
                                if (context.mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Month opened'),
                                    ),
                                  );
                                  context.read<MessCubit>().loadMess(messId);
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        e.toString().replaceAll(
                                          'Exception: ',
                                          '',
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              } finally {
                                setS(() => saving = false);
                              }
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandDark,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Create Month'),
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

  Widget _defaultDisplayChip(dynamic m) {
    // Web parity: dashboard/mess.blade.php shows B·L·D or legacy total in settlement; use defaultDisplay from API
    // CartpaFerna 1·0·1 must render as 1 · 0 · 1 with 0 in red, Goutam as 1 · 1 · 1
    final raw = (m.defaultDisplay as String?) ?? '';
    if (raw.isEmpty || raw == '—') {
      return const SizedBox.shrink();
    }
    // Split B·L·D — keep raw formatting (already trimmed by backend)
    final isBld = raw.contains('·');
    if (!isBld) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: AppColors.paper, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.paperLine)),
        child: Text(raw, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.inkSoft)),
      );
    }
    final parts = raw.split('·').map((e) => e.trim()).toList();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < parts.length; i++) ...[
          if (i > 0) const Text(' · ', style: TextStyle(fontSize: 10, color: AppColors.inkFaded)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: parts[i] == '0' ? const Color(0xFFFEE2E2) : AppColors.paper,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: parts[i] == '0' ? const Color(0xFFFCA5A5) : AppColors.paperLine),
            ),
            child: Text(
              parts[i],
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: parts[i] == '0' ? const Color(0xFFB91C1C) : AppColors.ink),
            ),
          ),
        ],
      ],
    );
  }

  Color _hexColor(String hex) {
    try {
      final v = hex.replaceAll('#', '');
      return Color(int.parse('FF$v', radix: 16));
    } catch (_) {
      return AppColors.brandDark;
    }
  }
}

class _InviteSection extends StatefulWidget {
  final int messId;
  const _InviteSection({required this.messId});
  @override
  State<_InviteSection> createState() => _InviteSectionState();
}

class _InviteSectionState extends State<_InviteSection> {
  final _emailCtrl = TextEditingController();
  String _role = 'member';
  bool _sending = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.paperRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.paperLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Invite by email',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'member@example.com',
              prefixIcon: Icon(Icons.email_outlined, size: 18),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ChoiceChip(
                label: const Text('Member'),
                selected: _role == 'member',
                onSelected: (_) => setState(() => _role = 'member'),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Manager'),
                selected: _role == 'manager',
                onSelected: (_) => setState(() => _role = 'manager'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _sending
                    ? null
                    : () async {
                        final email = _emailCtrl.text.trim();
                        if (email.isEmpty || !email.contains('@')) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Enter a valid email'),
                            ),
                          );
                          return;
                        }
                        setState(() => _sending = true);
                        try {
                          await MessRepository().storeInvite(
                            widget.messId,
                            email,
                            _role,
                          );
                          _emailCtrl.clear();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Invite sent to $email')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString().replaceAll('Exception: ', ''),
                                ),
                              ),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _sending = false);
                        }
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandDark,
                ),
                child: _sending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Send Invite'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
