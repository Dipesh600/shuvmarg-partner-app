import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shuvmarg_partner_app/core/theme/app_theme.dart';
import 'package:shuvmarg_partner_app/core/routes/app_routes.dart';
import 'package:shuvmarg_partner_app/shared/widgets/app_widgets.dart';

// Mock data — replace with Riverpod provider + API
class _HomeData {
  final String agentName = 'Ramesh';
  final double commissionBalance = 1240;
  final double minimumWithdraw = 500;
  final int bookingsToday = 12;
  final double revenueToday = 9600;
  final int onlineToday = 8;
  final int cashToday = 4;
  final List<_RecentBooking> recents = [
    _RecentBooking(
      route: 'Ktm → Pkr',
      seat: 'Seat 12',
      passenger: 'Ram Bahadur',
      isCash: false,
      time: '2h ago',
      status: 'Done',
      statusColor: 0xFF22C55E,
    ),
    _RecentBooking(
      route: 'Ktm → Brt',
      seat: 'Seat 7',
      passenger: 'Sita Kumari',
      isCash: true,
      time: '3h ago',
      status: 'Active',
      statusColor: 0xFFEF9F27,
    ),
    _RecentBooking(
      route: 'Pkr → Ktm',
      seat: 'Seat 3',
      passenger: 'Bikash Rai',
      isCash: false,
      time: '5h ago',
      status: 'Done',
      statusColor: 0xFF22C55E,
    ),
  ];
}

class _RecentBooking {
  final String route, seat, passenger, time, status;
  final bool isCash;
  final int statusColor;
  const _RecentBooking({
    required this.route,
    required this.seat,
    required this.passenger,
    required this.isCash,
    required this.time,
    required this.status,
    required this.statusColor,
  });
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = _HomeData();
    final canWithdraw = data.commissionBalance >= data.minimumWithdraw;
    final remaining = data.minimumWithdraw - data.commissionBalance;
    final currFmt = NumberFormat('#,###');

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: AppColors.bgBase,
            floating: true,
            snap: true,
            elevation: 0,
            titleSpacing: AppSpacing.xl,
            title: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting(),
                        style: AppTextStyles.bodySmall(AppColors.textSecond),
                      ),
                      Text(
                        data.agentName,
                        style: AppTextStyles.heading3(AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.25),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.stroke),
                    ),
                    child: const Icon(Icons.person_outline_rounded,
                        color: AppColors.textPrimary, size: 22),
                  ),
                ),
              ],
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 100,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── Commission Balance Card ─────────────────────────────
                GlassCard(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Commission balance', style: AppTextStyles.labelSm(Colors.white60)),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'NPR ${currFmt.format(data.commissionBalance)}',
                        style: AppTextStyles.heroNum(AppColors.textPrimary),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      if (canWithdraw)
                        Text('Ready to withdraw', style: AppTextStyles.bodySmall(AppColors.accentLime))
                      else
                        Text(
                          'NPR ${currFmt.format(remaining.toInt())} more to withdraw',
                          style: AppTextStyles.bodySmall(AppColors.textSecond),
                        ),

                      const SizedBox(height: AppSpacing.xl),

                      if (canWithdraw)
                        _GhostChip(
                          label: 'Withdraw',
                          icon: Icons.arrow_upward_rounded,
                          onTap: () {},
                        )
                      else
                        _ProgressToWithdraw(
                          current: data.commissionBalance,
                          target: data.minimumWithdraw,
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // ── Today's Activity ────────────────────────────────────
                SectionHeader(title: "Today's activity"),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    _MiniStat(value: data.bookingsToday.toString(), label: 'bookings', icon: Icons.confirmation_number_outlined),
                    const SizedBox(width: AppSpacing.md),
                    _MiniStat(value: 'NPR ${currFmt.format(data.revenueToday.toInt())}', label: 'revenue', icon: Icons.payments_outlined),
                    const SizedBox(width: AppSpacing.md),
                    _MiniStat(
                      value: '${data.onlineToday}',
                      label: 'online',
                      sublabel: '${data.cashToday} cash',
                      icon: Icons.wifi_outlined,
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xxl),

                // ── Book a Ticket CTA ───────────────────────────────────
                GestureDetector(
                  onTap: () => context.go(AppRoutes.search),
                  child: Container(
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD3D925), Color(0xFFC5CB20)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      boxShadow: AppShadows.glow,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.confirmation_number_outlined,
                            color: AppColors.primaryDark, size: 24),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          'Book a Ticket',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        const Icon(Icons.arrow_forward_rounded,
                            color: AppColors.primaryDark, size: 20),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                // ── Recent Bookings ─────────────────────────────────────
                SectionHeader(
                  title: 'Recent bookings',
                  action: 'View all',
                  onAction: () => context.go(AppRoutes.myBookings),
                ),
                const SizedBox(height: AppSpacing.md),

                ...data.recents.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _BookingRow(booking: b),
                )),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MINI STAT CARD
// ─────────────────────────────────────────────────────────────────────────────
class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  final String? sublabel;
  final IconData icon;

  const _MiniStat({
    required this.value,
    required this.label,
    this.sublabel,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.bgInput,
          borderRadius: BorderRadius.circular(AppRadius.card - 8),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.secondary, size: 16),
            const SizedBox(height: AppSpacing.sm),
            Text(value, style: AppTextStyles.heading3(AppColors.textPrimary)),
            Text(label, style: AppTextStyles.bodyTiny(AppColors.textSecond)),
            if (sublabel != null)
              Text(sublabel!, style: AppTextStyles.bodyTiny(AppColors.accentLime)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOOKING ROW
// ─────────────────────────────────────────────────────────────────────────────
class _BookingRow extends StatelessWidget {
  final _RecentBooking booking;
  const _BookingRow({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.bgInput,
        borderRadius: BorderRadius.circular(AppRadius.card - 8),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(booking.route, style: AppTextStyles.labelMed(AppColors.textPrimary)),
                    const SizedBox(width: AppSpacing.sm),
                    Text(booking.seat, style: AppTextStyles.bodySmall(AppColors.textSecond)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(booking.passenger, style: AppTextStyles.bodyMed(AppColors.textSecond)),
                    const SizedBox(width: AppSpacing.sm),
                    PaymentBadge(isCash: booking.isCash),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(booking.time, style: AppTextStyles.bodyTiny(AppColors.textSecond)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      color: Color(booking.statusColor),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(booking.status, style: AppTextStyles.bodySmall(Color(booking.statusColor))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GHOST CHIP (inside commission card)
// ─────────────────────────────────────────────────────────────────────────────
class _GhostChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _GhostChip({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white30),
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 6),
            Text(label, style: AppTextStyles.labelSm(Colors.white)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROGRESS TO WITHDRAW (shown when below threshold)
// ─────────────────────────────────────────────────────────────────────────────
class _ProgressToWithdraw extends StatelessWidget {
  final double current;
  final double target;
  const _ProgressToWithdraw({required this.current, required this.target});

  @override
  Widget build(BuildContext context) {
    final progress = (current / target).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: Colors.white12,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentLime),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'NPR ${target.toInt()} minimum to withdraw',
          style: AppTextStyles.bodyTiny(Colors.white54),
        ),
      ],
    );
  }
}
