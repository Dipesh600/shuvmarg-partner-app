import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shuvmarg_partner_app/core/theme/app_theme.dart';
import 'package:shuvmarg_partner_app/core/routes/app_routes.dart';
import 'package:shuvmarg_partner_app/shared/widgets/app_widgets.dart';

class PaymentQrScreen extends StatefulWidget {
  final Map<String, dynamic> bookingData;
  const PaymentQrScreen({super.key, required this.bookingData});

  @override
  State<PaymentQrScreen> createState() => _PaymentQrScreenState();
}

class _PaymentQrScreenState extends State<PaymentQrScreen>
    with SingleTickerProviderStateMixin {
  static const int _qrValidSeconds = 300; // 5 min
  int _remainingSeconds = _qrValidSeconds;
  Timer? _timer;
  late AnimationController _dotCtrl;
  bool _expired = false;

  // Mock QR data — real: payment gateway deep link
  late final String _qrData;

  @override
  void initState() {
    super.initState();
    _qrData =
        'shuvmarg://pay?amount=${widget.bookingData['price']}&seat=${widget.bookingData['seatId']}&ts=${DateTime.now().millisecondsSinceEpoch}';

    _dotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    _startTimer();

    // Simulate payment received after 8 seconds (demo)
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted && !_expired) {
        _onPaymentReceived();
      }
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remainingSeconds <= 1) {
        t.cancel();
        setState(() => _expired = true);
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _onPaymentReceived() {
    _timer?.cancel();
    context.pushReplacement(AppRoutes.bookingConfirm, extra: {
      ...widget.bookingData,
      'isCash': false,
      'commission': ((widget.bookingData['price'] ?? 850) * 0.08).round(),
    });
  }

  void _regenerateQr() {
    setState(() {
      _expired = false;
      _remainingSeconds = _qrValidSeconds;
    });
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _dotCtrl.dispose();
    super.dispose();
  }

  String get _timerText {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final price = widget.bookingData['price'] ?? 850;
    final seatId = widget.bookingData['seatId'] ?? '?';
    final from = widget.bookingData['from'] ?? '';
    final to = widget.bookingData['to'] ?? '';

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgBase,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text('Payment', style: AppTextStyles.labelLg(AppColors.textPrimary)),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xl),

              Text('Passenger scans to pay', style: AppTextStyles.heading3(AppColors.textPrimary)),
              const SizedBox(height: AppSpacing.xl),

              // ── QR Code ───────────────────────────────────────────
              AnimatedOpacity(
                opacity: _expired ? 0.3 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    boxShadow: AppShadows.card,
                  ),
                  child: QrImageView(
                    data: _qrData,
                    version: QrVersions.auto,
                    size: 200,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF003D38),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF003D38),
                    ),
                    embeddedImageStyle: null,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Amount
              Text(
                'NPR $price',
                style: AppTextStyles.heroNumSm(AppColors.textPrimary),
              ),
              Text(
                'Seat $seatId  ·  $from → $to',
                style: AppTextStyles.bodySmall(AppColors.textSecond),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Waiting / expired state
              if (!_expired)
                _WaitingIndicator(ctrl: _dotCtrl)
              else
                Column(
                  children: [
                    Text('QR code expired', style: AppTextStyles.labelMed(AppColors.error)),
                    const SizedBox(height: AppSpacing.lg),
                    OutlineButton(
                      label: 'Generate New QR',
                      onPressed: _regenerateQr,
                      borderColor: AppColors.accentLime,
                      textColor: AppColors.accentLime,
                      height: 44,
                    ),
                  ],
                ),

              const SizedBox(height: AppSpacing.xl),

              // Payment method logos
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _PayLogo(label: 'Khalti', color: const Color(0xFF5C2D91)),
                  const SizedBox(width: AppSpacing.lg),
                  _PayLogo(label: 'eSewa', color: const Color(0xFF60B246)),
                ],
              ),

              const Spacer(),

              // Timer
              if (!_expired)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer_outlined, color: AppColors.textSecond, size: 16),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'QR expires in  ',
                      style: AppTextStyles.bodySmall(AppColors.textSecond),
                    ),
                    Text(
                      _timerText,
                      style: AppTextStyles.labelMed(
                        _remainingSeconds < 60 ? AppColors.error : AppColors.accentLime,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: AppSpacing.xl),

              // Cancel
              GestureDetector(
                onTap: () => context.pop(),
                child: Text(
                  'Cancel payment',
                  style: AppTextStyles.bodyMed(AppColors.textSecond),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaitingIndicator extends StatelessWidget {
  final AnimationController ctrl;
  const _WaitingIndicator({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.access_time_rounded, color: AppColors.secondary, size: 16),
        const SizedBox(width: AppSpacing.sm),
        AnimatedBuilder(
          animation: ctrl,
          builder: (context, child) {
            final dots = '.' * ((ctrl.value * 3).toInt() + 1);
            return Text(
              'Waiting for payment$dots',
              style: AppTextStyles.bodyMed(AppColors.textSecond),
            );
          },
        ),
      ],
    );
  }
}

class _PayLogo extends StatelessWidget {
  final String label;
  final Color color;
  const _PayLogo({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: color.withOpacity(0.30)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMed(color),
      ),
    );
  }
}
