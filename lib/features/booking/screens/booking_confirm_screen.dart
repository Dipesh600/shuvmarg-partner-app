import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
// ignore: unused_import
import 'package:shuvmarg_partner_app/core/theme/app_theme.dart';
import 'package:shuvmarg_partner_app/core/routes/app_routes.dart';
import 'package:shuvmarg_partner_app/shared/widgets/app_widgets.dart';

class BookingConfirmScreen extends StatelessWidget {
  final Map<String, dynamic> bookingResult;
  const BookingConfirmScreen({super.key, required this.bookingResult});

  @override
  Widget build(BuildContext context) {
    final isCash = bookingResult['isCash'] as bool? ?? false;
    final commission = bookingResult['commission'] as int? ?? 0;
    final passengerName = bookingResult['passengerName'] ?? 'Ram Bahadur Thapa';
    final seatId = bookingResult['seatId'] ?? 'U7';
    final busType = bookingResult['busType'] ?? 'AC Deluxe';
    final operator = bookingResult['operator'] ?? 'Greenline Travels';
    final departure = bookingResult['departure'] ?? '07:00';
    final arrival = bookingResult['arrival'] ?? '13:00';
    final from = bookingResult['from'] ?? 'Kathmandu';
    final to = bookingResult['to'] ?? 'Pokhara';
    final boardingPoint = bookingResult['boardingPoint'] ?? 'New Bus Park, Gongabu';
    final price = bookingResult['price'] ?? 850;

    // Generate ticket reference
    final ticketRef = 'SHV-TK-${DateTime.now().millisecondsSinceEpoch % 100000}';
    final qrData = 'shuvmarg://ticket?ref=$ticketRef';

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: Column(
          children: [
            // ── Success Header ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, AppSpacing.xl,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.accentLime.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.accentLime.withOpacity(0.4)),
                    ),
                    child: const Icon(Icons.check_rounded, color: AppColors.accentLime, size: 24),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Booking Confirmed!', style: AppTextStyles.heading2(AppColors.accentLime)),
                      Text(
                        isCash ? 'Collect cash from passenger' : 'Payment received',
                        style: AppTextStyles.bodySmall(AppColors.textSecond),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Ticket Card ────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  children: [
                    // Ticket design
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F2926),
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: AppColors.stroke),
                        boxShadow: AppShadows.card,
                      ),
                      child: Column(
                        children: [
                          // Header stripe
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(AppRadius.card - 1),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('TICKET', style: AppTextStyles.bodyTiny(Colors.white54)),
                                    Text(operator, style: AppTextStyles.heading3(Colors.white)),
                                    Text(busType, style: AppTextStyles.bodySmall(Colors.white70)),
                                  ],
                                ),
                                PaymentBadge(isCash: isCash),
                              ],
                            ),
                          ),

                          // Tear line
                          Row(
                            children: [
                              _notch(left: true),
                              Expanded(
                                child: DashedLine(color: AppColors.stroke),
                              ),
                              _notch(left: false),
                            ],
                          ),

                          // Ticket body
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Column(
                              children: [
                                // Passenger
                                _TicketRow(label: 'Passenger', value: passengerName),
                                _TicketRow(label: 'Seat', value: '$seatId  ·  $busType'),

                                const SizedBox(height: AppSpacing.xl),

                                // Route + time
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(from, style: AppTextStyles.heading2(AppColors.textPrimary)),
                                          Text(departure, style: AppTextStyles.labelSm(AppColors.textSecond)),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.arrow_right_alt_rounded, color: AppColors.secondary, size: 32),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(to, style: AppTextStyles.heading2(AppColors.textPrimary)),
                                          Text(arrival, style: AppTextStyles.labelSm(AppColors.textSecond)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: AppSpacing.xl),
                                _TicketRow(label: 'Boarding', value: boardingPoint),

                                const SizedBox(height: AppSpacing.xxl),

                                // QR
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: QrImageView(
                                      data: qrData,
                                      version: QrVersions.auto,
                                      size: 100,
                                      eyeStyle: const QrEyeStyle(
                                        eyeShape: QrEyeShape.square,
                                        color: Color(0xFF003D38),
                                      ),
                                      dataModuleStyle: const QrDataModuleStyle(
                                        dataModuleShape: QrDataModuleShape.square,
                                        color: Color(0xFF003D38),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(ticketRef, style: AppTextStyles.labelSm(AppColors.textSecond)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Commission earned (online only)
                    if (!isCash && commission > 0)
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.accentLime.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.accentLime.withOpacity(0.25)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.wallet_rounded, color: AppColors.accentLime, size: 20),
                            const SizedBox(width: AppSpacing.md),
                            Text(
                              'Commission earned: ',
                              style: AppTextStyles.bodyMed(AppColors.textSecond),
                            ),
                            Text(
                              'NPR $commission',
                              style: AppTextStyles.labelMed(AppColors.accentLime),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: AppSpacing.xl),

                    // WhatsApp Share (PRIMARY)
                    GestureDetector(
                      onTap: () {
                        final text = '🎫 Your bus ticket is confirmed!\n\n'
                            'Passenger: $passengerName\n'
                            'Seat: $seatId\n'
                            '$operator · $departure\n'
                            '$from → $to\n'
                            'Boarding: $boardingPoint\n\n'
                            'Ticket ID: $ticketRef\n\n'
                            'Booked via Shuvmarg Partner App';
                        Share.share(text);
                      },
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366),
                          borderRadius: BorderRadius.circular(AppRadius.button),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: AppSpacing.md),
                            Text(
                              'Share on WhatsApp',
                              style: AppTextStyles.button(Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // SMS option
                    OutlineButton(
                      label: '📱  Send SMS to passenger',
                      onPressed: () {/* TODO: SMS API */},
                      borderColor: AppColors.primary,
                      textColor: AppColors.textPrimary,
                      height: 48,
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Book another
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.search),
                      child: Text(
                        'Book another ticket →',
                        style: AppTextStyles.labelMed(AppColors.accentLime),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notch({required bool left}) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: AppColors.bgBase,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.stroke),
      ),
    );
  }
}

class _TicketRow extends StatelessWidget {
  final String label;
  final String value;
  const _TicketRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: AppTextStyles.bodySmall(AppColors.textSecond)),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.labelSm(AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}

class DashedLine extends StatelessWidget {
  final Color color;
  const DashedLine({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedLinePainter(color: color),
      size: const Size(double.infinity, 1),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + 8, 0), paint);
      x += 16;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
