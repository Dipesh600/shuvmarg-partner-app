import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shuvmarg_partner_app/core/theme/app_theme.dart';
import 'package:shuvmarg_partner_app/core/routes/app_routes.dart';
import 'package:shuvmarg_partner_app/core/services/auth_service.dart';
import 'package:shuvmarg_partner_app/features/application/providers/application_provider.dart';
import 'package:shuvmarg_partner_app/shared/widgets/app_widgets.dart';

const List<String> _kNepalDistricts = [
  'Kathmandu', 'Lalitpur', 'Bhaktapur', 'Kaski', 'Chitwan', 'Makwanpur',
  'Rupandehi', 'Banke', 'Bardiya', 'Kanchanpur', 'Morang', 'Jhapa',
  'Sunsari', 'Saptari', 'Siraha', 'Mahottari', 'Sarlahi', 'Rautahat',
  'Bara', 'Parsa', 'Nawalparasi', 'Palpa', 'Gulmi', 'Arghakhanchi',
  'Syangja', 'Tanahu', 'Lamjung', 'Gorkha', 'Dhading', 'Nuwakot',
  'Rasuwa', 'Sindhuli', 'Ramechhap', 'Dolakha', 'Solukhumbu', 'Okhaldhunga',
  'Khotang', 'Udayapur', 'Sankhuwasabha', 'Bhojpur', 'Taplejung',
  'Terhathum', 'Dhankuta', 'Ilam', 'Panchthar', 'Other',
];

class AppStep1Screen extends ConsumerStatefulWidget {
  const AppStep1Screen({super.key});

  @override
  ConsumerState<AppStep1Screen> createState() => _AppStep1ScreenState();
}

class _AppStep1ScreenState extends ConsumerState<AppStep1Screen> {
  final _municipalityCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _selectedDistrict;

  @override
  void initState() {
    super.initState();
    // Pre-fill from provider if user navigated back
    final draft = ref.read(applicationProvider);
    if (draft.district != null) {
      _selectedDistrict = draft.district;
    }
    if (draft.municipality != null) {
      _municipalityCtrl.text = draft.municipality!;
    }
  }

  @override
  void dispose() {
    _municipalityCtrl.dispose();
    super.dispose();
  }

  bool get _canProceed =>
      _selectedDistrict != null && _municipalityCtrl.text.trim().isNotEmpty;

  Future<void> _next() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(applicationProvider.notifier).saveStep1(
          district: _selectedDistrict!,
          municipality: _municipalityCtrl.text.trim(),
        );
    if (ok && mounted) context.push(AppRoutes.appStep2Business);
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(applicationProvider);
    final user = ref.watch(authProvider).user;
    final isSaving = draft.isSaving;

    // Show error snackbar when error appears
    ref.listen(applicationProvider, (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
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
                  const StepProgressBar(currentStep: 1, totalSteps: 4),
                  const SizedBox(height: AppSpacing.xl),

                  Text('Personal Details', style: AppTextStyles.heading2(AppColors.textPrimary)),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Tell us about yourself', style: AppTextStyles.bodyMed(AppColors.textSecond)),

                  const SizedBox(height: AppSpacing.xl),

                  // ── Account info banner ────────────────────────────────
                  if (user != null)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(AppRadius.card - 8),
                        border: Border.all(color: AppColors.primary.withOpacity(0.20)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.20),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person_outline_rounded, color: AppColors.secondary, size: 18),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user['name']?.toString() ?? '—',
                                  style: AppTextStyles.labelSm(AppColors.textPrimary),
                                ),
                                Text(
                                  user['phone']?.toString() ?? '—',
                                  style: AppTextStyles.bodySmall(AppColors.textSecond),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.accentLime.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('Verified', style: AppTextStyles.bodyTiny(AppColors.accentLime)),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: AppSpacing.xxl),

                  // ── District ──────────────────────────────────────────
                  Text('District *', style: AppTextStyles.labelSm(AppColors.textSecond)),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    value: _selectedDistrict,
                    hint: Text('Select district', style: AppTextStyles.bodyMed(AppColors.textSecond)),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecond),
                    dropdownColor: AppColors.bgSurface,
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
                    items: _kNepalDistricts.map((d) => DropdownMenuItem(
                      value: d,
                      child: Text(d),
                    )).toList(),
                    validator: (v) => v == null ? 'Please select your district' : null,
                    onChanged: (val) => setState(() => _selectedDistrict = val),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ── Municipality ──────────────────────────────────────
                  AppInputField(
                    label: 'Municipality *',
                    hint: 'e.g. Kathmandu Metropolitan City',
                    controller: _municipalityCtrl,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Municipality is required' : null,
                    onChanged: (_) => setState(() {}),
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
