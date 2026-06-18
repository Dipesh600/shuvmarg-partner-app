import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shuvmarg_partner_app/core/theme/app_theme.dart';
import 'package:shuvmarg_partner_app/core/routes/app_routes.dart';
import 'package:shuvmarg_partner_app/features/application/providers/application_provider.dart';
import 'package:shuvmarg_partner_app/shared/widgets/app_widgets.dart';

const List<String> _kBusinessTypes = [
  'Ticket counter',
  'Travel agent / agency',
  'Mobile shop',
  'Individual / freelance',
  'Hotel / lodge',
  'Other',
];

const List<String> _kMonthlySalesRanges = [
  'Less than 20',
  '20 – 50',
  '50 – 100',
  '100 – 200',
  'More than 200',
];

const List<String> _kReferralSources = [
  'Friend or colleague',
  'Bus operator',
  'Social media',
  'Newspaper / radio',
  'Walk-in / flyer',
  'Other',
];

class AppStep2Screen extends ConsumerStatefulWidget {
  const AppStep2Screen({super.key});

  @override
  ConsumerState<AppStep2Screen> createState() => _AppStep2ScreenState();
}

class _AppStep2ScreenState extends ConsumerState<AppStep2Screen> {
  final _businessNameCtrl = TextEditingController();
  final _shopAddressCtrl = TextEditingController();
  final _currentOperatorsCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _selectedType;
  String? _selectedVolume;
  String? _selectedReferral;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(applicationProvider);
    if (draft.businessName != null) _businessNameCtrl.text = draft.businessName!;
    if (draft.shopAddress != null) _shopAddressCtrl.text = draft.shopAddress!;
    if (draft.currentOperators != null) _currentOperatorsCtrl.text = draft.currentOperators!;
    _selectedType = draft.operationType;
    _selectedVolume = draft.claimedMonthlyVolume;
    _selectedReferral = draft.referralSource;
  }

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _shopAddressCtrl.dispose();
    _currentOperatorsCtrl.dispose();
    super.dispose();
  }

  bool get _canProceed =>
      _businessNameCtrl.text.trim().isNotEmpty &&
      _shopAddressCtrl.text.trim().isNotEmpty &&
      _selectedType != null &&
      _selectedVolume != null &&
      _selectedReferral != null;

  Future<void> _next() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(applicationProvider.notifier).saveStep2(
          businessName: _businessNameCtrl.text.trim(),
          shopAddress: _shopAddressCtrl.text.trim(),
          operationType: _selectedType!,
          claimedMonthlyVolume: _selectedVolume!,
          currentOperators: _currentOperatorsCtrl.text.trim(),
          referralSource: _selectedReferral!,
        );
    if (ok && mounted) context.push(AppRoutes.appStep3Documents);
  }

  Widget _buildDropdown({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    bool isRequired = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label${isRequired ? ' *' : ''}', style: AppTextStyles.labelSm(AppColors.textSecond)),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String>(
          value: value,
          hint: Text(hint, style: AppTextStyles.bodyMed(AppColors.textSecond)),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecond),
          dropdownColor: AppColors.bgSurface,
          style: AppTextStyles.bodyLarge(AppColors.textPrimary),
          isExpanded: true,
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
          items: items
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          validator: isRequired ? (v) => v == null ? 'This field is required' : null : null,
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const StepProgressBar(currentStep: 2, totalSteps: 4),
                  const SizedBox(height: AppSpacing.xl),
                  Text('Business Details', style: AppTextStyles.heading2(AppColors.textPrimary)),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Tell us about your operation', style: AppTextStyles.bodyMed(AppColors.textSecond)),

                  const SizedBox(height: AppSpacing.xxxl),

                  AppInputField(
                    label: 'Shop / Business name *',
                    hint: 'e.g. Ram Ticket Counter',
                    controller: _businessNameCtrl,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Business name is required' : null,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  AppInputField(
                    label: 'Physical address *',
                    hint: 'e.g. New Bus Park, Gongabu, Kathmandu',
                    controller: _shopAddressCtrl,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Address is required' : null,
                    maxLines: 2,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  _buildDropdown(
                    label: 'Type of business',
                    hint: 'Select type',
                    value: _selectedType,
                    items: _kBusinessTypes,
                    onChanged: (v) => _selectedType = v,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  _buildDropdown(
                    label: 'Monthly tickets sold (approximate)',
                    hint: 'Select range',
                    value: _selectedVolume,
                    items: _kMonthlySalesRanges,
                    onChanged: (v) => _selectedVolume = v,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  AppInputField(
                    label: 'Bus operators you work with currently',
                    hint: 'e.g. Greenline, Yeti Travel...',
                    controller: _currentOperatorsCtrl,
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Optional', style: AppTextStyles.bodySmall(AppColors.textSecond.withOpacity(0.6))),

                  const SizedBox(height: AppSpacing.xl),

                  _buildDropdown(
                    label: 'How did you hear about Shuvmarg?',
                    hint: 'Select source',
                    value: _selectedReferral,
                    items: _kReferralSources,
                    onChanged: (v) => _selectedReferral = v,
                  ),

                  const SizedBox(height: AppSpacing.xxxl + AppSpacing.xl),

                  PrimaryButton(
                    label: 'Next',
                    onPressed: (_canProceed && !isSaving) ? _next : null,
                    isLoading: isSaving,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
