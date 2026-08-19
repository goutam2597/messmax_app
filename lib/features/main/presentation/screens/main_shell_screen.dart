import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/locale/app_translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../ads/presentation/cubit/ads_cubit.dart';
import '../../../ads/presentation/screens/ads_screen.dart';
import '../../../blog/presentation/cubit/blog_cubit.dart';
import '../../../blog/presentation/screens/blog_screen.dart';
import '../../../home/presentation/cubit/home_cubit.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../dashboard/presentation/cubit/dashboard_cubit.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

import 'package:flutter/services.dart';
import '../../../../core/widgets/app_exit_dialog.dart';

class MainShellScope extends InheritedWidget {
  final void Function(int index) selectTab;

  const MainShellScope({
    super.key,
    required this.selectTab,
    required super.child,
  });

  static MainShellScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MainShellScope>();
  }

  @override
  bool updateShouldNotify(MainShellScope oldWidget) => false;
}

class MainShellScreen extends StatefulWidget {
  final int initialTab;

  const MainShellScreen({super.key, this.initialTab = 0});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  late int _currentIndex;

  final List<Widget> _screens = const [
    HomeScreen(),
    AdsScreen(),
    BlogScreen(),
    ProfileScreen(),
  ];

  static List<_NavItem> _navItems(BuildContext context) => [
    _NavItem(asset: 'assets/icons/nav_home.svg', label: 'ui.nav_home'.tr2),
    _NavItem(
      asset: 'assets/icons/nav_seats.svg',
      label: 'ui.nav_find_seats'.tr2,
      badge: 'LIVE',
    ),
    _NavItem(asset: 'assets/icons/nav_blog.svg', label: 'ui.nav_blog'.tr2),
    _NavItem(
      asset: 'assets/icons/nav_profile.svg',
      label: 'ui.nav_profile'.tr2,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  void _onTabSelected(int index) {
    if (index == 3) {
      final auth = context.read<AuthCubit>().state;
      if (auth is! AuthAuthenticated) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
        return;
      }
    }
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => HomeCubit()),
        BlocProvider(create: (_) => AdsCubit()),
        BlocProvider(create: (_) => BlogCubit()),
        BlocProvider(create: (_) => DashboardCubit()..loadDashboard()),
      ],
      child: MainShellScope(
        selectTab: (index) {
          if (mounted) {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            // 1. If we are on a tab other than Home (0), return to Home first
            if (_currentIndex != 0) {
              setState(() => _currentIndex = 0);
              return;
            }
            // 2. If at root of the shell (tab 0): confirm before exit
            final shouldExit = await AppExitDialog.show(context);
            if (shouldExit == true) {
              SystemNavigator.pop();
            }
          },
          child: ValueListenableBuilder<int>(
            valueListenable: AppTranslations.notifier,
            builder: (context, _, _) => Scaffold(
              extendBody: true,
              body: IndexedStack(index: _currentIndex, children: _screens),
              bottomNavigationBar: _FloatingNavBar(
                currentIndex: _currentIndex,
                items: _navItems(context),
                onTap: _onTabSelected,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Floating rounded nav bar, same pattern as the market app.
class _FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _FloatingNavBar({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    // On devices with 3-button system navigation bar (Android inset >= 36px),
    // add bottom safe area inset to margin so it clears Back/Home/Recents buttons.
    // On gesture navigation devices (thin gesture pill / iOS / Android gesture nav),
    // keep the exact existing floating margin (16px).
    final bool isThreeButtonNav = isAndroid && bottomInset >= 36;
    final double bottomMargin = isThreeButtonNav ? (8.0 + bottomInset) : 16.0;

    return Container(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Container(
          margin: EdgeInsets.fromLTRB(12, 0, 12, bottomMargin),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.paperRaised,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: List.generate(items.length, (i) {
              return Expanded(
                child: _NavTile(
                  item: items[i],
                  isActive: i == currentIndex,
                  onTap: () => onTap(i),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.brand : AppColors.inkFaded;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.brand.withValues(alpha: 0.10)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: SvgPicture.asset(
                    item.asset,
                    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                  ),
                ),
              ),
              if (item.badge != null && !isActive)
                Positioned(
                  top: -2,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      item.badge!,
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.3,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
              color: color,
              letterSpacing: isActive ? 0.1 : 0,
            ),
            child: Text(item.label),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final String asset;
  final String label;
  final String? badge;

  const _NavItem({required this.asset, required this.label, this.badge});
}
