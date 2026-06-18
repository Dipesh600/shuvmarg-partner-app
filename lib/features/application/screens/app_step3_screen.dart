import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shuvmarg_partner_app/core/theme/app_theme.dart';
import 'package:shuvmarg_partner_app/core/routes/app_routes.dart';
import 'package:shuvmarg_partner_app/features/application/providers/application_provider.dart';
import 'package:shuvmarg_partner_app/shared/widgets/app_widgets.dart';

// ── Document configuration ────────────────────────────────────────────────────
class _DocConfig {
  final String type;
  final String label;
  final String hint;
  final IconData icon;
  final bool required;

  const _DocConfig({
    required this.type,
    required this.label,
    required this.hint,
    required this.icon,
    this.required = true,
  });
}

const _kDocs = [
  _DocConfig(
    type: 'citizenship_front',
    label: 'Citizenship Certificate — Front',
    hint: 'Clear photo showing your face and details',
    icon: Icons.badge_outlined,
  ),
  _DocConfig(
    type: 'citizenship_back',
    label: 'Citizenship Certificate — Back',
    hint: 'Back side of your citizenship card',
    icon: Icons.badge_outlined,
  ),
  _DocConfig(
    type: 'shop_photo',
    label: 'Shop / Counter Photo',
    hint: 'Show your shop front or counter area',
    icon: Icons.storefront_outlined,
  ),
  _DocConfig(
    type: 'pan_card',
    label: 'PAN Card',
    hint: 'Optional — upload if available',
    icon: Icons.receipt_long_outlined,
    required: false,
  ),
];

class AppStep3Screen extends ConsumerStatefulWidget {
  const AppStep3Screen({super.key});

  @override
  ConsumerState<AppStep3Screen> createState() => _AppStep3ScreenState();
}

class _AppStep3ScreenState extends ConsumerState<AppStep3Screen> {
  final _picker = ImagePicker();

  Future<void> _pickAndUpload(String documentType) async {
    final draft = ref.read(applicationProvider);
    if (draft.uploadStates[documentType] == DocUploadState.uploading) return;

    final source = await _showSourcePicker();
    if (source == null) return;

    final xFile = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (xFile == null) return;

    await ref.read(applicationProvider.notifier).uploadDocument(
          file: File(xFile.path),
          documentType: documentType,
        );
  }

  Future<ImageSource?> _showSourcePicker() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.stroke,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
              Text('Upload Document', style: AppTextStyles.heading3(AppColors.textPrimary)),
              const SizedBox(height: AppSpacing.xl),
              _SourceTile(
                icon: Icons.camera_alt_outlined,
                label: 'Take a photo',
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              const SizedBox(height: AppSpacing.md),
              _SourceTile(
                icon: Icons.photo_library_outlined,
                label: 'Choose from gallery',
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(applicationProvider);

    ref.listen(applicationProvider, (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!), backgroundColor: AppColors.error),
        );
        ref.read(applicationProvider.notifier).clearError();
      }
    });

    final canProceed = draft.requiredDocsUploaded;

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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const StepProgressBar(currentStep: 3, totalSteps: 4),
                    const SizedBox(height: AppSpacing.xl),
                    Text('Upload Documents', style: AppTextStyles.heading2(AppColors.textPrimary)),
                    const SizedBox(height: AppSpacing.xs),
                    Text('Clear, well-lit photos required', style: AppTextStyles.bodyMed(AppColors.textSecond)),

                    const SizedBox(height: AppSpacing.xl),

                    // Camera info banner
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withOpacity(0.20)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.cloud_upload_outlined, color: AppColors.secondary, size: 16),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Documents are securely uploaded and stored. We need camera access to capture your documents.',
                              style: AppTextStyles.bodySmall(AppColors.textSecond),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Document cards
                    ..._kDocs.map((doc) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                          child: _DocUploadCard(
                            config: doc,
                            uploadState: draft.uploadStates[doc.type] ?? DocUploadState.idle,
                            localFile: draft.localFiles[doc.type],
                            onTap: () => _pickAndUpload(doc.type),
                            onDelete: () => ref
                                .read(applicationProvider.notifier)
                                .removeDocument(doc.type),
                          ),
                        )),

                    const SizedBox(height: AppSpacing.lg),
                  ],
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
              child: PrimaryButton(
                label: 'Next',
                onPressed: canProceed ? () => context.push(AppRoutes.appStep4Settlement) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Document upload card ──────────────────────────────────────────────────────

class _DocUploadCard extends StatelessWidget {
  final _DocConfig config;
  final DocUploadState uploadState;
  final File? localFile;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DocUploadCard({
    required this.config,
    required this.uploadState,
    required this.localFile,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isUploaded = uploadState == DocUploadState.uploaded;
    final isUploading = uploadState == DocUploadState.uploading;
    final hasError = uploadState == DocUploadState.error;

    return GestureDetector(
      onTap: isUploaded ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isUploaded
              ? AppColors.successLight.withOpacity(0.08)
              : hasError
                  ? AppColors.errorLight.withOpacity(0.08)
                  : AppColors.bgInput,
          borderRadius: BorderRadius.circular(AppRadius.card - 4),
          border: Border.all(
            color: isUploaded
                ? AppColors.success.withOpacity(0.4)
                : hasError
                    ? AppColors.error.withOpacity(0.4)
                    : AppColors.stroke,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Icon / thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: isUploaded && localFile != null
                  ? Image.file(localFile!, width: 56, height: 56, fit: BoxFit.cover)
                  : Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(config.icon, color: AppColors.secondary, size: 26),
                    ),
            ),

            const SizedBox(width: AppSpacing.lg),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(config.label, style: AppTextStyles.labelSm(AppColors.textPrimary)),
                      ),
                      if (!config.required)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.stroke,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('Optional', style: AppTextStyles.bodyTiny(AppColors.textSecond)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (isUploading)
                    Row(children: [
                      SizedBox(
                        width: 12, height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentLime),
                      ),
                      const SizedBox(width: 8),
                      Text('Uploading to secure storage...', style: AppTextStyles.bodySmall(AppColors.accentLime)),
                    ])
                  else if (isUploaded)
                    Row(children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 14),
                      const SizedBox(width: 4),
                      Text('Uploaded', style: AppTextStyles.bodySmall(AppColors.success)),
                    ])
                  else if (hasError)
                    Row(children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 14),
                      const SizedBox(width: 4),
                      Text('Upload failed — tap to retry', style: AppTextStyles.bodySmall(AppColors.error)),
                    ])
                  else
                    Text(config.hint, style: AppTextStyles.bodySmall(AppColors.textSecond)),
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.sm),
            if (isUploaded)
              GestureDetector(
                onTap: onDelete,
                child: const Icon(Icons.close_rounded, color: AppColors.textSecond, size: 18),
              )
            else if (!isUploading)
              GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add_rounded, color: AppColors.accentLime, size: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.bgInput,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.accentLime, size: 22),
            const SizedBox(width: AppSpacing.lg),
            Text(label, style: AppTextStyles.bodyLarge(AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}
