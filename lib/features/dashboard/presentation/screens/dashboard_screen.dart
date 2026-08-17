import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/mess_drawer.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _activeSection = 'dashboard';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.paper,
      drawer: MessDrawer(
        activeSection: _activeSection,
        onSectionSelected: (section) {
          setState(() => _activeSection = section);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Navigated to ${section.replaceAll('_', ' ').toUpperCase()}')),
          );
        },
      ),
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: AppColors.ink, size: 24),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Green View Hostel',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
            Text(
              'Manager Dashboard • Aug 2026',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.inkFaded,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined, color: AppColors.ink, size: 22),
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications — 2 pending meal off requests')),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMessBannerCard(),
              const SizedBox(height: 18),
              _buildSectionTitle('MONTHLY LEDGER STATS'),
              const SizedBox(height: 10),
              _buildLedgerGrid(),
              const SizedBox(height: 18),
              _buildPendingApprovalCard(context),
              const SizedBox(height: 20),
              _buildSectionTitle('QUICK ACTIONS'),
              const SizedBox(height: 10),
              _buildQuickActionsRow(context),
              const SizedBox(height: 22),
              _buildSectionTitle('TODAY\'S MEAL SHEET (DAY 17)'),
              const SizedBox(height: 10),
              _buildDailyMealSheetCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w900,
        color: AppColors.inkFaded,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildMessBannerCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brandDark, AppColors.brandDeep],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandDark.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
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
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: const Icon(Icons.apartment_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Green View Hostel Mess',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Manager: Goutam Sharma • Code: #MX-8921',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                _BannerMiniStat(label: 'MEMBERS', value: '12 Active'),
                _BannerDivider(),
                _BannerMiniStat(label: 'OPEN SEATS', value: '3 Seats'),
                _BannerDivider(),
                _BannerMiniStat(label: 'STATUS', value: 'Active Month', isHighlight: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerGrid() {
    return GridView.count(
      padding: EdgeInsets.zero,
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: [
        _statTile(
          icon: Icons.restaurant_rounded,
          iconColor: AppColors.brandDark,
          bgColor: AppColors.brandSoft,
          title: 'Total Meals',
          value: '269.5',
          subtitle: 'Today: 29.5 meals',
        ),
        _statTile(
          icon: Icons.shopping_bag_rounded,
          iconColor: const Color(0xFF0F9F59),
          bgColor: const Color(0xFFE6F4EA),
          title: 'Total Bazar',
          value: '14,098 ৳',
          subtitle: '18 Market trips',
        ),
        _statTile(
          icon: Icons.analytics_rounded,
          iconColor: AppColors.accentDark,
          bgColor: AppColors.accentSoft,
          title: 'Current Rate',
          value: '52.41 ৳',
          subtitle: 'Calculated per meal',
        ),
        _statTile(
          icon: Icons.account_balance_wallet_rounded,
          iconColor: const Color(0xFF1A73E8),
          bgColor: const Color(0xFFE8F0FE),
          title: 'Cash Deposit',
          value: '28,500 ৳',
          subtitle: 'Rest: +4,280 ৳',
        ),
      ],
    );
  }

  Widget _statTile({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.paperRaised,
        borderRadius: BorderRadius.circular(16),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkFaded,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.inkFaded,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingApprovalCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.pending_actions_rounded,
              color: AppColors.accentDark,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '2 Pending Meal-Off Requests',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Goutam (Day 18) & Cartpa (Day 19) awaiting manager review',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.inkFaded,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening Meal-Off Requests review')),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accentDark,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Review', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsRow(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _actionPill(
            icon: Icons.add_shopping_cart_rounded,
            label: 'Record Bazar',
            color: AppColors.brandDark,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add Bazar Entry')),
              );
            },
          ),
          const SizedBox(width: 10),
          _actionPill(
            icon: Icons.edit_calendar_rounded,
            label: 'Meal Off',
            color: AppColors.accentDark,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Submit Meal Off Request')),
              );
            },
          ),
          const SizedBox(width: 10),
          _actionPill(
            icon: Icons.add_business_rounded,
            label: 'Post Seat Ad',
            color: const Color(0xFF0F9F59),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Post Seat Listing')),
              );
            },
          ),
          const SizedBox(width: 10),
          _actionPill(
            icon: Icons.person_add_alt_1_rounded,
            label: 'Add Member',
            color: const Color(0xFF1A73E8),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invite Member to Mess')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _actionPill({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyMealSheetCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paperRaised,
        borderRadius: BorderRadius.circular(18),
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
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.paperLine)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'MEMBER NAME',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: AppColors.inkFaded),
                ),
                Text(
                  'B  /  L  /  D',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: AppColors.inkFaded, letterSpacing: 1),
                ),
                Text(
                  'TOTAL',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: AppColors.inkFaded),
                ),
              ],
            ),
          ),
          _memberMealRow(name: 'Goutam Sharma', room: 'Room 101', b: 1, l: 1, d: 1, total: 3.0),
          const Divider(height: 1, color: AppColors.paperLine),
          _memberMealRow(name: 'Cartpa User', room: 'Room 102', b: 1, l: 0, d: 1, total: 2.0, isLunchOff: true),
          const Divider(height: 1, color: AppColors.paperLine),
          _memberMealRow(name: 'Tanvir Ahmed', room: 'Room 103', b: 0, l: 0, d: 0, total: 0.0, isAllOff: true),
          const Divider(height: 1, color: AppColors.paperLine),
          _memberMealRow(name: 'Rafiqul Islam', room: 'Room 104', b: 1, l: 1, d: 1, total: 3.0),
        ],
      ),
    );
  }

  Widget _memberMealRow({
    required String name,
    required String room,
    required int b,
    required int l,
    required int d,
    required double total,
    bool isLunchOff = false,
    bool isAllOff = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
                Text(
                  room,
                  style: const TextStyle(fontSize: 11, color: AppColors.inkFaded),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _mealPill('B', b == 1),
              const SizedBox(width: 4),
              _mealPill('L', l == 1, isOff: isLunchOff),
              const SizedBox(width: 4),
              _mealPill('D', d == 1),
            ],
          ),
          const SizedBox(width: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isAllOff
                  ? AppColors.paper
                  : (total >= 3 ? const Color(0xFFE6F4EA) : AppColors.brandSoft),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              isAllOff ? 'OFF' : '${total.toInt()} Meals',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                color: isAllOff
                    ? AppColors.inkFaded
                    : (total >= 3 ? const Color(0xFF137333) : AppColors.brandDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mealPill(String label, bool isOn, {bool isOff = false}) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isOn
            ? const Color(0xFF137333)
            : (isOff ? AppColors.accent.withValues(alpha: 0.15) : AppColors.paper),
        border: Border.all(
          color: isOn
              ? const Color(0xFF137333)
              : (isOff ? AppColors.accent : AppColors.paperLine),
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: isOn ? Colors.white : (isOff ? AppColors.accentDark : AppColors.inkFaded),
          ),
        ),
      ),
    );
  }
}

class _BannerMiniStat extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;

  const _BannerMiniStat({
    required this.label,
    required this.value,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w800,
            color: Colors.white.withValues(alpha: 0.6),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: isHighlight ? const Color(0xFFFFD700) : Colors.white,
          ),
        ),
      ],
    );
  }
}

class _BannerDivider extends StatelessWidget {
  const _BannerDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      color: Colors.white.withValues(alpha: 0.15),
    );
  }
}
