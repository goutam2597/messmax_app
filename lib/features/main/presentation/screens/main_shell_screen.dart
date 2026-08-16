import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../ads/presentation/cubit/ads_cubit.dart';
import '../../../ads/presentation/screens/ads_screen.dart';
import '../../../blog/presentation/screens/blog_screen.dart';
import '../../../home/presentation/cubit/home_cubit.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => HomeCubit()),
        BlocProvider(create: (_) => AdsCubit()),
      ],
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: AppColors.paperLine, width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x0C000000),
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              backgroundColor: Colors.white,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppColors.brandDark,
              unselectedItemColor: AppColors.inkFaded,
              selectedLabelStyle: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.travel_explore_outlined),
                  activeIcon: Icon(Icons.travel_explore_rounded),
                  label: 'Find Seats',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.article_outlined),
                  activeIcon: Icon(Icons.article_rounded),
                  label: 'Blog',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline_rounded),
                  activeIcon: Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
