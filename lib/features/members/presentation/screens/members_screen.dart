import 'package:flutter/material.dart';
import '../../../../core/locale/app_translations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/bn_digits.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/confirm_delete_dialog.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../data/models/member_model.dart';
import '../cubit/member_cubit.dart';
import '../cubit/member_state.dart';
import 'member_form_screen.dart';
import '../../../mess/presentation/screens/mess_detail_screen.dart';

class MembersScreen extends StatelessWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MemberCubit()..loadMembers(),
      child: const _MembersView(),
    );
  }
}

class _MembersView extends StatefulWidget {
  const _MembersView();

  @override
  State<_MembersView> createState() => _MembersViewState();
}

class _MembersViewState extends State<_MembersView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _backToDashboard() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
      (_) => false,
    );
  }

  void _confirmDelete(BuildContext context, MemberModel member) async {
    final confirm = await ConfirmDeleteDialog.show(
      context,
      title: 'ui.confirm_remove_member_title'.tr2,
      itemName: member.name,
      message: 'ui.confirm_remove_member_message'.tr2.replaceAll(
        '{name}',
        member.name,
      ),
      confirmLabel: 'ui.confirm_remove_member_label'.tr2,
      icon: Icons.person_remove_rounded,
    );

    if (confirm == true && context.mounted) {
      final cubit = context.read<MemberCubit>();
      final ok = await cubit.deleteMember(member.id);
      if (ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${member.name} ${'ui.members_removed'.tr2}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _backToDashboard();
      },
      child: Scaffold(
        backgroundColor: AppColors.paper,
        appBar: AppBar(
          backgroundColor: AppColors.paperRaised,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          leading: AppBackButton(onPressed: _backToDashboard),
          title: BlocBuilder<MemberCubit, MemberState>(
            builder: (context, state) {
              final messName = state is MemberLoaded
                  ? state.response.messName
                  : '';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ui.members_title'.tr2,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    messName.isNotEmpty
                        ? '$messName • ${'ui.members_member_list'.tr2}'
                        : 'ui.members_list_defaults'.tr2,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.inkFaded,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );
            },
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => context.read<MemberCubit>().loadMembers(
                      forceRefresh: true,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.paperLine),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.refresh_rounded,
                          color: AppColors.ink,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: BlocConsumer<MemberCubit, MemberState>(
            listener: (context, state) {
              if (state is MemberLoaded && state.message != null) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.message!)));
              }
            },
            builder: (context, state) {
              if (state is MemberLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.brandDark),
                );
              }

              if (state is MemberError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 42,
                          color: Color(0xFFA02626),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.inkFaded),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => context
                              .read<MemberCubit>()
                              .loadMembers(forceRefresh: true),
                          child: Text('ui.try_again'.tr2),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state is MemberLoaded) {
                final data = state.response;
                final members = data.members;

                return RefreshIndicator(
                  color: AppColors.brandDark,
                  onRefresh: () => context.read<MemberCubit>().loadMembers(
                    forceRefresh: true,
                  ),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- MESS SELECTOR HEADER CARD ---
                        _buildHeaderCard(context, data),
                        const SizedBox(height: 20),

                        Text(
                          'ui.members_active_roster'.tr2,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            color: AppColors.inkFaded,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 10),

                        if (members.isEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: AppColors.paperRaised,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.paperLine),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.people_outline_rounded,
                                  size: 48,
                                  color: AppColors.inkFaded,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'ui.members_no_members'.tr2,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'ui.members_no_members_sub'.tr2,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.inkFaded,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: members.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              return _buildMemberCard(
                                context,
                                members[index],
                                data.canManage,
                                data.messId,
                              );
                            },
                          ),
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
        floatingActionButton: BlocBuilder<MemberCubit, MemberState>(
          builder: (context, state) {
            if (state is MemberLoaded && state.response.canManage) {
              return FloatingActionBubble(
                messId: state.response.messId,
                cubit: context.read<MemberCubit>(),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, MemberResponseModel data) {
    return Container(
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
          InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MessDetailScreen(messId: data.messId),
              ),
            ),
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.brandSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.groups_rounded,
                    color: AppColors.brandDark,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              data.messName,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: AppColors.inkFaded,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${bnDigits(data.members.length)} ${'ui.members_enrolled'.tr2} • ${'ui.members_join_code'.tr2}: ${data.messCode}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.inkFaded,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (data.messes.length > 1) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.paperLine),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'ui.members_switch_mess'.tr2,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.inkFaded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: data.messes.map((m) {
                        final active = m.id == data.messId;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(m.name),
                            selected: active,
                            selectedColor: AppColors.brandDark,
                            labelStyle: TextStyle(
                              fontSize: 11,
                              color: active ? Colors.white : AppColors.ink,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (_) {
                              if (!active) {
                                context.read<MemberCubit>().loadMembers(
                                  messId: m.id,
                                );
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMemberCard(
    BuildContext context,
    MemberModel member,
    bool canManage,
    int messId,
  ) {
    final isOwner = member.isOwner;
    final isManager = member.isManager;

    return Container(
      padding: const EdgeInsets.all(16),
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
              // Avatar photo or initials
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.brandSoft,
                ),
                child: ClipOval(
                  child: member.avatarUrl != null
                      ? Image.network(
                          member.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _initials(member.name),
                        )
                      : _initials(member.name),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            member.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: AppColors.ink,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isOwner
                                ? const Color(0xFFEDE7F6)
                                : isManager
                                ? AppColors.brandSoft
                                : AppColors.paper,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isOwner
                                  ? const Color(
                                      0xFF5E35B1,
                                    ).withValues(alpha: 0.3)
                                  : isManager
                                  ? AppColors.brandDark.withValues(alpha: 0.2)
                                  : AppColors.paperLine,
                            ),
                          ),
                          child: Text(
                            isOwner
                                ? 'ui.role_owner'.tr2
                                : isManager
                                ? 'ui.role_manager'.tr2
                                : 'ui.role_member'.tr2,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: isOwner
                                  ? const Color(0xFF5E35B1)
                                  : isManager
                                  ? AppColors.brandDark
                                  : AppColors.inkFaded,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (member.email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        member.email,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.inkFaded,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (canManage && !member.isOwner)
                PopupMenuButton<String>(
                  onSelected: (action) {
                    if (action == 'edit') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MemberFormScreen(
                            member: member,
                            messId: messId,
                            cubit: context.read<MemberCubit>(),
                          ),
                        ),
                      );
                    } else if (action == 'delete') {
                      _confirmDelete(context, member);
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text('ui.members_edit_member'.tr2),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: Color(0xFFA02626),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ui.members_remove_member'.tr2,
                            style: const TextStyle(color: Color(0xFFA02626)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.paperLine),
          const SizedBox(height: 10),

          // Defaults breakdown & Bazar day row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'ui.members_defaults'.tr2,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkFaded,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.brandSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      member.defaultDisplay.toBnNum(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: AppColors.brandDark,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                '${'ui.members_bazar_day'.tr2}: ${bnDigits(member.bazarDay)}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkFaded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _initials(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'M';
    return Container(
      color: AppColors.brandDark,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }
}

class FloatingActionBubble extends StatelessWidget {
  final int messId;
  final MemberCubit cubit;

  const FloatingActionBubble({
    super.key,
    required this.messId,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MemberFormScreen(messId: messId, cubit: cubit),
          ),
        );
      },
      backgroundColor: AppColors.brandDark,
      icon: const Icon(Icons.add_rounded, color: Colors.white),
      label: Text(
        'ui.members_add_member'.tr2,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
