import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shuvmarg_partner_app/core/theme/app_theme.dart';
import 'package:shuvmarg_partner_app/core/routes/app_routes.dart';
import 'package:shuvmarg_partner_app/shared/widgets/app_widgets.dart';

// Mock boarding/dropping points (would come from bus route data)
const List<String> _kBoardingPoints = [
  'New Bus Park, Gongabu',
  'Kalanki',
  'Balkhu',
  'Lagankhel (Lalitpur)',
  'Satdobato',
];

const List<String> _kDroppingPoints = [
  'Pokhara Bus Park',
  'Prithvi Chowk',
  'Mahendrapool',
  'Sabhagriha',
  'Baglung Bus Park',
];

class PassengerDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> bookingData;
  const PassengerDetailsScreen({super.key, required this.bookingData});

  @override
  State<PassengerDetailsScreen> createState() => _PassengerDetailsScreenState();
}

class _PassengerDetailsScreenState extends State<PassengerDetailsScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _boardingPoint;
  String? _droppingPoint;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  bool get _canContinue =>
      _nameCtrl.text.trim().isNotEmpty &&
      _phoneCtrl.text.trim().length == 10 &&
      _boardingPoint != null &&
      _droppingPoint != null;

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() => _isLoading = false);

      final updatedData = {
        ...widget.bookingData,
        'passengerName': _nameCtrl.text.trim(),
        'passengerPhone': '+977${_phoneCtrl.text.trim()}',
        'boardingPoint': _boardingPoint,
        'droppingPoint': _droppingPoint,
      };

      // TODO: Check if operator-linked → show payment mode screen
      // For now: default agent → go directly to payment QR
      // The backend / auth state will determine this in production
      context.push(AppRoutes.paymentMode, extra: updatedData);
    }
  }

  Widget _buildPointDropdown({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label *', style: AppTextStyles.labelSm(AppColors.textSecond)),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String>(
          value: value,
          hint: Text(hint, style: AppTextStyles.bodyMed(AppColors.textSecond)),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecond),
          dropdownColor: AppColors.bgSurface,
          isExpanded: true,
          style: AppTextStyles.bodyLarge(AppColors.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.bgInput,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md + 4,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
              borderSide: const BorderSide(color: AppColors.stroke),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
              borderSide: const BorderSide(color: AppColors.stroke),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
          items: items.map((p) => DropdownMenuItem(
            value: p,
            child: Text(p, overflow: TextOverflow.ellipsis),
          )).toList(),
          validator: (v) => v == null ? 'Please select a point' : null,
          onChanged: (val) {
            onChanged(val);
            setState(() {});
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final seatId = widget.bookingData['seatId'] ?? '?';
    final operator = widget.bookingData['operator'] ?? '';
    final departure = widget.bookingData['departure'] ?? '';

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgBase,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Passenger Details', style: AppTextStyles.labelLg(AppColors.textPrimary)),
            Text('Seat $seatId · $operator $departure', style: AppTextStyles.bodySmall(AppColors.textSecond)),
          ],
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Info banner
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.warning.withOpacity(0.25)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.person_outline_rounded, color: AppColors.warning, size: 16),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  "Enter the passenger's details — not yours.",
                                  style: AppTextStyles.bodySmall(AppColors.textSecond),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Passenger name
                        AppInputField(
                          label: 'Passenger name *',
                          hint: 'Full name',
                          controller: _nameCtrl,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Passenger phone
                        Text('Passenger phone *', style: AppTextStyles.labelSm(AppColors.textSecond)),
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.bgInput,
                            borderRadius: BorderRadius.circular(AppRadius.input),
                            border: Border.all(color: AppColors.stroke),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md + 4),
                                decoration: BoxDecoration(
                                  border: Border(right: BorderSide(color: AppColors.stroke)),
                                ),
                                child: Text('+977', style: AppTextStyles.bodyLarge(AppColors.textSecond)),
                              ),
                              Expanded(
                                child: TextFormField(
                                  controller: _phoneCtrl,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(10),
                                  ],
                                  style: AppTextStyles.bodyLarge(AppColors.textPrimary),
                                  decoration: InputDecoration(
                                    hintText: '98XXXXXXXX',
                                    hintStyle: AppTextStyles.bodyLarge(AppColors.textSecond.withOpacity(0.5)),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.lg,
                                      vertical: AppSpacing.md + 4,
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.length != 10) return 'Enter a valid 10-digit number';
                                    return null;
                                  },
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Ticket will be sent to this number via SMS',
                          style: AppTextStyles.bodyTiny(AppColors.textSecond),
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // Boarding point
                        _buildPointDropdown(
                          label: 'Boarding point',
                          hint: 'Where passenger boards',
                          value: _boardingPoint,
                          items: _kBoardingPoints,
                          onChanged: (v) => _boardingPoint = v,
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Dropping point
                        _buildPointDropdown(
                          label: 'Dropping point',
                          hint: 'Where passenger gets off',
                          value: _droppingPoint,
                          items: _kDroppingPoints,
                          onChanged: (v) => _droppingPoint = v,
                        ),

                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Fixed CTA ─────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxl,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgBase,
                  border: Border(top: BorderSide(color: AppColors.stroke)),
                  boxShadow: AppShadows.bottomNav,
                ),
                child: PrimaryButton(
                  label: 'Continue',
                  onPressed: _canContinue ? _continue : null,
                  isLoading: _isLoading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
