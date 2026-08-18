import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../cubit/mess_cubit.dart';
import '../cubit/mess_state.dart';
import '../../data/models/mess_model.dart';
import 'mess_form_screen.dart';
import 'mess_detail_screen.dart';

class MessesScreen extends StatelessWidget {
  const MessesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MessCubit()..loadMesses(),
      child: const _MessesView(),
    );
  }
}

class _MessesView extends StatefulWidget {
  const _MessesView();
  @override
  State<_MessesView> createState() => _MessesViewState();
}

class _MessesViewState extends State<_MessesView> {
  void _backToDashboard() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
      (_) => false,
    );
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
          leading: AppBackButton(
            onPressed: _backToDashboard,
          ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mess Overview',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
            Text(
              'Your messes & active ledgers',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.inkFaded,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.read<MessCubit>().loadMesses(),
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
                      child: Icon(Icons.refresh_rounded, color: AppColors.ink, size: 18),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: BlocConsumer<MessCubit, MessState>(
          listener: (context, state) {
            if (state is MessListLoaded && state.message != null) {
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
                        onPressed: () => context.read<MessCubit>().loadMesses(),
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
            if (state is MessListLoaded) {
              final messes = state.messes;
              if (messes.isEmpty) {
                return RefreshIndicator(
                  color: AppColors.brandDark,
                  onRefresh: () => context.read<MessCubit>().loadMesses(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 40, 20, 32),
                    child: Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.brandSoft,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Icon(
                              Icons.apartment_rounded,
                              color: AppColors.brandDark,
                              size: 48,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'No Mess Joined Yet',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Create your first mess to start tracking meals and bazar.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.inkFaded,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: () async {
                              final ok = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MessFormScreen(
                                    cubit: context.read<MessCubit>(),
                                  ),
                                ),
                              );
                              if (ok == true && context.mounted) {
                                context.read<MessCubit>().loadMesses();
                              }
                            },
                            icon: const Icon(Icons.add_rounded, size: 20),
                            label: const Text('Create New Mess'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.brandDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return RefreshIndicator(
                color: AppColors.brandDark,
                onRefresh: () => context.read<MessCubit>().loadMesses(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // hero summary strip
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.brandDark, AppColors.brandDeep],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.dashboard_rounded,
                              color: Colors.white70,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${messes.length} ${messes.length == 1 ? 'Mess' : 'Messes'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${messes.where((m) => m.canManage).length} manageable',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'YOUR MESSES',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          color: AppColors.inkFaded,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: messes.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, i) => _MessCard(
                          mess: messes[i],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    MessDetailScreen(messId: messes[i].id),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
      floatingActionButton: BlocBuilder<MessCubit, MessState>(
        builder: (context, state) {
          if (state is MessListLoaded) {
            // gate: individuals can only create if 0 messes (mirrors web canCreateMess)
            final canCreate = state.canCreate || state.messes.isEmpty;
            // also show if hostel owner always can; for now allow if list empty or canCreate
            if (!canCreate && state.isIndividual) {
              return const SizedBox.shrink();
            }
            return FloatingActionButton.extended(
              backgroundColor: AppColors.brandDark,
              onPressed: () async {
                final ok = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        MessFormScreen(cubit: context.read<MessCubit>()),
                  ),
                );
                if (ok == true && context.mounted) {
                  context.read<MessCubit>().loadMesses();
                }
              },
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'New Mess',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
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
}

class _MessCard extends StatelessWidget {
  final MessModel mess;
  final VoidCallback onTap;
  const _MessCard({required this.mess, required this.onTap});

  @override
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.paperRaised,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: mess.canManage
                ? AppColors.brandDark.withValues(alpha: 0.35)
                : AppColors.paperLine,
            width: mess.canManage ? 1.5 : 1,
          ),
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brandSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.apartment_rounded,
                    color: AppColors.brandDark,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    mess.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: mess.canManage
                        ? AppColors.brandDark
                        : AppColors.paperLine,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    mess.displayRole.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      color: mess.canManage ? Colors.white : AppColors.inkSoft,
                    ),
                  ),
                ),
              ],
            ),
            if (mess.location.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: AppColors.inkFaded,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    mess.location,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.inkFaded,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                _chip(
                  Icons.people_outline_rounded,
                  '${mess.membersCount} members',
                ),
                const SizedBox(width: 8),
                _chip(
                  Icons.calendar_month_rounded,
                  '${mess.monthsCount} months',
                ),
                const Spacer(),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.inkFaded,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
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
}
