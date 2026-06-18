import 'package:flutter/material.dart';
import 'package:shuvmarg_partner_app/core/theme/app_theme.dart';
import 'package:shuvmarg_partner_app/shared/widgets/app_widgets.dart';

// ── Mock data ─────────────────────────────────────────────────────────────────
class _Booking {
  final String id, route, passenger, seat, date, time, status;
  final bool isCash;
  final int price;
  const _Booking({
    required this.id,
    required this.route,
    required this.passenger,
    required this.seat,
    required this.date,
    required this.time,
    required this.status,
    required this.isCash,
    required this.price,
  });
}

const _kBookings = [
  _Booking(id: 'b1', route: 'Ktm → Pokhara', passenger: 'Ram Bahadur', seat: 'Seat 7', date: '15 Jun', time: '07:00', status: 'Confirmed', isCash: false, price: 850),
  _Booking(id: 'b2', route: 'Ktm → Birgunj', passenger: 'Sita Kumari', seat: 'Seat 12', date: '15 Jun', time: '10:00', status: 'Confirmed', isCash: true, price: 1200),
  _Booking(id: 'b3', route: 'Ktm → Pokhara', passenger: 'Bikash Rai', seat: 'Seat 3', date: '14 Jun', time: '07:00', status: 'Completed', isCash: false, price: 850),
  _Booking(id: 'b4', route: 'Pkr → Ktm', passenger: 'Hari Prasad', seat: 'Seat 18', date: '14 Jun', time: '08:00', status: 'Cancelled', isCash: true, price: 900),
  _Booking(id: 'b5', route: 'Ktm → Dhangadhi', passenger: 'Maya Thapa', seat: 'Seat 5', date: '13 Jun', time: '17:00', status: 'Completed', isCash: false, price: 1500),
  _Booking(id: 'b6', route: 'Ktm → Biratnagar', passenger: 'Rajan Shrestha', seat: 'Seat 22', date: '12 Jun', time: '19:00', status: 'Completed', isCash: false, price: 1100),
];

enum _TimeFilter { today, week, all }
enum _StatusFilter { all, confirmed, completed, cancelled }

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  _TimeFilter _timeFilter = _TimeFilter.today;
  _StatusFilter _statusFilter = _StatusFilter.all;

  List<_Booking> get _filtered {
    var list = _kBookings.toList();
    if (_statusFilter != _StatusFilter.all) {
      final status = _statusFilter.name[0].toUpperCase() + _statusFilter.name.substring(1);
      list = list.where((b) => b.status == status).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgBase,
        automaticallyImplyLeading: false,
        title: Text('My Bookings', style: AppTextStyles.heading3(AppColors.textPrimary)),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Time filter tabs ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 0,
              ),
              child: Row(
                children: _TimeFilter.values.map((f) => Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _timeFilter = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: _timeFilter == f
                            ? AppColors.accentLime.withOpacity(0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.button),
                        border: Border.all(
                          color: _timeFilter == f
                              ? AppColors.accentLime.withOpacity(0.4)
                              : AppColors.stroke,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          f.name[0].toUpperCase() + f.name.substring(1),
                          style: _timeFilter == f
                              ? AppTextStyles.labelSm(AppColors.accentLime)
                              : AppTextStyles.labelSm(AppColors.textSecond),
                        ),
                      ),
                    ),
                  ),
                )).toList(),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // ── Status filter chips ─────────────────────────────────
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                children: _StatusFilter.values.map((f) {
                  final isActive = _statusFilter == f;
                  Color? chipColor;
                  if (f == _StatusFilter.confirmed) chipColor = AppColors.accentLime;
                  if (f == _StatusFilter.completed) chipColor = AppColors.success;
                  if (f == _StatusFilter.cancelled) chipColor = AppColors.error;

                  return GestureDetector(
                    onTap: () => setState(() => _statusFilter = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: AppSpacing.sm),
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs + 2),
                      decoration: BoxDecoration(
                        color: isActive
                            ? (chipColor ?? AppColors.primary).withOpacity(0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(
                          color: isActive
                              ? (chipColor ?? AppColors.primary).withOpacity(0.5)
                              : AppColors.stroke,
                        ),
                      ),
                      child: Text(
                        f == _StatusFilter.all
                            ? 'All'
                            : f.name[0].toUpperCase() + f.name.substring(1),
                        style: isActive
                            ? AppTextStyles.labelSm(chipColor ?? AppColors.secondary)
                            : AppTextStyles.labelSm(AppColors.textSecond),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // ── Bookings list ───────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? _emptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl, 0, AppSpacing.xl, 100,
                      ),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, i) => _BookingCard(booking: filtered[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long_outlined, color: AppColors.textSecond, size: 64),
          const SizedBox(height: AppSpacing.xl),
          Text('No bookings found', style: AppTextStyles.heading3(AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.sm),
          Text('Bookings you make will appear here', style: AppTextStyles.bodyMed(AppColors.textSecond)),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final _Booking booking;
  const _BookingCard({required this.booking});

  Color get _statusColor {
    switch (booking.status) {
      case 'Confirmed': return AppColors.accentLime;
      case 'Completed': return AppColors.success;
      case 'Cancelled': return AppColors.error;
      default: return AppColors.textSecond;
    }
  }

  IconData get _statusIcon {
    switch (booking.status) {
      case 'Confirmed': return Icons.check_circle_outline_rounded;
      case 'Completed': return Icons.check_circle_rounded;
      case 'Cancelled': return Icons.cancel_outlined;
      default: return Icons.circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.bgInput,
        borderRadius: BorderRadius.circular(AppRadius.card - 4),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(booking.route, style: AppTextStyles.heading3(AppColors.textPrimary)),
              ),
              PaymentBadge(isCash: booking.isCash),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(booking.passenger, style: AppTextStyles.bodyMed(AppColors.textSecond)),
              const SizedBox(width: AppSpacing.sm),
              Text('·', style: AppTextStyles.bodySmall(AppColors.textSecond)),
              const SizedBox(width: AppSpacing.sm),
              Text(booking.seat, style: AppTextStyles.bodySmall(AppColors.textSecond)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textSecond),
              const SizedBox(width: 4),
              Text('${booking.date}  ·  ${booking.time}', style: AppTextStyles.bodySmall(AppColors.textSecond)),
            ],
          ),

          const SizedBox(height: AppSpacing.md),
          Divider(color: AppColors.stroke, height: 1),
          const SizedBox(height: AppSpacing.md),

          Row(
            children: [
              Icon(_statusIcon, color: _statusColor, size: 16),
              const SizedBox(width: 4),
              Text(booking.status, style: AppTextStyles.labelSm(_statusColor)),
              const Spacer(),
              Text(
                'NPR ${booking.price}',
                style: AppTextStyles.heading3(AppColors.textPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
