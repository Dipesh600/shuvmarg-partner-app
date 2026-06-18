import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shuvmarg_partner_app/core/theme/app_theme.dart';
import 'package:shuvmarg_partner_app/core/routes/app_routes.dart';
import 'package:shuvmarg_partner_app/features/application/providers/application_provider.dart';
import 'package:shuvmarg_partner_app/shared/widgets/app_widgets.dart';

enum _SettlementMethod { bank, esewa, khalti }

const List<String> _kNepalBanks = [
  'Agricultural Development Bank', 'Bank of Kathmandu', 'Citizens Bank International',
  'Civil Bank', 'Everest Bank', 'Global IME Bank', 'Himalayan Bank', 'Kumari Bank',
  'Laxmi Sunrise Bank', 'Machhapuchchhre Bank', 'Mega Bank Nepal', 'NIC Asia Bank',
  'Nepal Bank Limited', 'Nepal Credit and Commerce Bank', 'Nepal Investment Mega Bank',
  'Nepal SBI Bank', 'NMB Bank', 'Prabhu Bank', 'Prime Commercial Bank',
  'Rastriya Banijya Bank', 'Sanima Bank', 'Siddhartha Bank',
  'Standard Chartered Bank Nepal', 'Sunrise Bank', 'Other',
];

class AppStep4Screen extends ConsumerStatefulWidget {
  const AppStep4Screen({super.key});

  @override
  ConsumerState<AppStep4Screen> createState() => _AppStep4ScreenState();
}

class _AppStep4ScreenState extends ConsumerState<AppStep4Screen> {
  _SettlementMethod? _selected;
  String? _selectedBank;
  final _accountHolderCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();
  final _walletNumberCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Pre-fill from draft if navigating back
    final draft = ref.read(applicationProvider);
    if (draft.settlementMethod == 'bank') {
      _selected = _SettlementMethod.bank;
      _selectedBank = draft.bankName;
      _accountHolderCtrl.text = draft.bankAccountName ?? '';
      _accountNumberCtrl.text = draft.bankAccountNumber ?? '';
    } else if (draft.settlementMethod == 'esewa') {
      _selected = _SettlementMethod.esewa;
      _walletNumberCtrl.text = draft.esewaNumber ?? '';
    } else if (draft.settlementMethod == 'khalti') {
      _selected = _SettlementMethod.khalti;
      _walletNumberCtrl.text = draft.khaltiNumber ?? '';
    }
  }

  @override
  void dispose() {
    _accountHolderCtrl.dispose();
    _accountNumberCtrl.dispose();
    _walletNumberCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    if (_selected == null) return false;
    if (_selected == _SettlementMethod.bank) {
      return _selectedBank != null &&
          _accountHolderCtrl.text.trim().isNotEmpty &&
          _accountNumberCtrl.text.trim().isNotEmpty;
    }
    return _walletNumberCtrl.text.trim().length >= 10;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await ref.read(applicationProvider.notifier).saveSettlementAndSubmit(
          settlementMethod: _selected!.name,
          bankName: _selected == _SettlementMethod.bank ? _selectedBank : null,
          bankAccountNumber: _selected == _SettlementMethod.bank
              ? _accountNumberCtrl.text.trim()
              : null,
          bankAccountName: _selected == _SettlementMethod.bank
              ? _accountHolderCtrl.text.trim()
              : null,
          esewaNumber: _selected == _SettlementMethod.esewa
              ? _walletNumberCtrl.text.trim()
              : null,
          khaltiNumber: _selected == _SettlementMethod.khalti
              ? _walletNumberCtrl.text.trim()
              : null,
        );

    if (ok && mounted) context.go(AppRoutes.appStatus);
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(applicationProvider).isSaving;

    ref.listen(applicationProvider, (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!), backgroundColor: AppColors.error),
        );
        ref.read(applicationProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgBase,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
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
                        const StepProgressBar(currentStep: 4, totalSteps: 4),
                        const SizedBox(height: AppSpacing.xl),
                        Text('Settlement Details', style: AppTextStyles.heading2(AppColors.textPrimary)),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Where should we send your commission earnings?',
                          style: AppTextStyles.bodyMed(AppColors.textSecond),
                        ),

                        const SizedBox(height: AppSpacing.xxxl),

                        Text('Payment method *', style: AppTextStyles.labelSm(AppColors.textSecond)),
                        const SizedBox(height: AppSpacing.md),

                        Row(
                          children: [
                            _MethodChip(
                              label: 'Bank',
                              icon: Icons.account_balance_rounded,
                              selected: _selected == _SettlementMethod.bank,
                              onTap: () => setState(() {
                                _selected = _SettlementMethod.bank;
                                _walletNumberCtrl.clear();
                              }),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            _MethodChip(
                              label: 'eSewa',
                              icon: Icons.phone_android_rounded,
                              selected: _selected == _SettlementMethod.esewa,
                              color: const Color(0xFF60B246),
                              onTap: () => setState(() {
                                _selected = _SettlementMethod.esewa;
                                _selectedBank = null;
                                _accountHolderCtrl.clear();
                                _accountNumberCtrl.clear();
                              }),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            _MethodChip(
                              label: 'Khalti',
                              icon: Icons.phone_android_rounded,
                              selected: _selected == _SettlementMethod.khalti,
                              color: const Color(0xFF5C2D91),
                              onTap: () => setState(() {
                                _selected = _SettlementMethod.khalti;
                                _selectedBank = null;
                                _accountHolderCtrl.clear();
                                _accountNumberCtrl.clear();
                              }),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        if (_selected == _SettlementMethod.bank) ...[ 
                          _bankField(),
                          const SizedBox(height: AppSpacing.xl),
                          AppInputField(
                            label: 'Account holder name *',
                            hint: 'As per bank records',
                            controller: _accountHolderCtrl,
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          AppInputField(
                            label: 'Account number *',
                            hint: 'Your bank account number',
                            controller: _accountNumberCtrl,
                            keyboardType: TextInputType.number,
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            onChanged: (_) => setState(() {}),
                          ),
                        ],

                        if (_selected == _SettlementMethod.esewa ||
                            _selected == _SettlementMethod.khalti) ...[ 
                          _WalletInfo(method: _selected!),
                          const SizedBox(height: AppSpacing.xl),
                          AppInputField(
                            label: 'Registered phone number *',
                            hint: '98XXXXXXXX',
                            controller: _walletNumberCtrl,
                            keyboardType: TextInputType.phone,
                            prefix: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('🇳🇵', style: TextStyle(fontSize: 18)),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().length < 10) return 'Enter a valid number';
                              return null;
                            },
                            onChanged: (_) => setState(() {}),
                          ),
                        ],

                        const SizedBox(height: AppSpacing.xxxl),
                      ],
                    ),
                  ),
                ),
              ),

              // Fixed bottom CTA
              Container(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxl,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgBase,
                  border: Border(top: BorderSide(color: AppColors.stroke)),
                  boxShadow: AppShadows.bottomNav,
                ),
                child: Column(
                  children: [
                    PrimaryButton(
                      label: 'Submit Application',
                      onPressed: (_canSubmit && !isSaving) ? _submit : null,
                      isLoading: isSaving,
                      color: AppColors.accentLime,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'You can update payment details after approval',
                      style: AppTextStyles.bodySmall(AppColors.textSecond),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bankField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bank name *', style: AppTextStyles.labelSm(AppColors.textSecond)),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String>(
          value: _selectedBank,
          hint: Text('Select bank', style: AppTextStyles.bodyMed(AppColors.textSecond)),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecond),
          dropdownColor: AppColors.bgSurface,
          isExpanded: true,
          style: AppTextStyles.bodyLarge(AppColors.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.bgInput,
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md + 4,
            ),
          ),
          items: _kNepalBanks
              .map((b) => DropdownMenuItem(value: b, child: Text(b, overflow: TextOverflow.ellipsis)))
              .toList(),
          validator: (v) => v == null ? 'Please select your bank' : null,
          onChanged: (val) => setState(() => _selectedBank = val),
        ),
      ],
    );
  }
}

// ── Method chip ───────────────────────────────────────────────────────────────

class _MethodChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  const _MethodChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.accentLime;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: selected ? c.withOpacity(0.12) : AppColors.bgInput,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(
              color: selected ? c.withOpacity(0.6) : AppColors.stroke,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? c : AppColors.textSecond, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: selected
                    ? AppTextStyles.labelSm(c)
                    : AppTextStyles.labelSm(AppColors.textSecond),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Wallet info banner ────────────────────────────────────────────────────────

class _WalletInfo extends StatelessWidget {
  final _SettlementMethod method;
  const _WalletInfo({required this.method});

  @override
  Widget build(BuildContext context) {
    final isEsewa = method == _SettlementMethod.esewa;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: (isEsewa ? const Color(0xFF60B246) : const Color(0xFF5C2D91)).withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isEsewa ? const Color(0xFF60B246) : const Color(0xFF5C2D91)).withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: isEsewa ? const Color(0xFF60B246) : const Color(0xFF5C2D91),
            size: 16,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Commission will be sent to your ${isEsewa ? "eSewa" : "Khalti"} wallet registered to this number.',
              style: AppTextStyles.bodySmall(AppColors.textSecond),
            ),
          ),
        ],
      ),
    );
  }
}
