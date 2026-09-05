import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/design/design.dart';
import '../../domain/driver_profile.dart';
import '../../shared/state/view_state.dart';
import '../../shared/ui/ui.dart';
import 'driver_profile_controller.dart';

class DriverProfileSection extends ConsumerWidget {
  const DriverProfileSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(driverProfileControllerProvider);
    void reload() => ref.read(driverProfileControllerProvider.notifier).load();

    return switch (state) {
      ViewInitial() || ViewLoadingFirst() => const _DriverProfileSkeleton(),
      ViewData(:final data) ||
      ViewLoadingRefresh(:final data) => _DriverProfileCards(
        profile: data,
        refreshing: state is ViewLoadingRefresh,
        onRefresh: reload,
      ),
      ViewSubmitting(:final data) =>
        data == null
            ? const _DriverProfileSkeleton()
            : _DriverProfileCards(
                profile: data,
                refreshing: true,
                onRefresh: reload,
              ),
      ViewSubmitFieldErrors(:final failure) ||
      ViewErrorRetryable(
        :final failure,
      ) => _ProfileProblem(message: failure.message, onRetry: reload),
      ViewOffline(:final failure) => _ProfileProblem(
        icon: Icons.wifi_off_rounded,
        message: failure.message,
        onRetry: reload,
      ),
      ViewErrorForbidden(:final failure) => _ProfileProblem(
        icon: Icons.lock_outline_rounded,
        message: failure.message,
      ),
      ViewEmpty(:final message) => _ProfileProblem(
        message: message ?? 'Your Driver profile could not be found.',
        onRetry: reload,
      ),
      ViewErrorAuth() => const SizedBox.shrink(),
    };
  }
}

class _DriverProfileCards extends StatelessWidget {
  const _DriverProfileCards({
    required this.profile,
    required this.refreshing,
    required this.onRefresh,
  });

  final DriverProfile profile;
  final bool refreshing;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primarySurface,
                    foregroundColor: AppColors.primary,
                    child: Text(profile.fullName[0].toUpperCase()),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile.fullName, style: AppText.titleMd),
                        const SizedBox(height: 2),
                        Text(
                          profile.brand?.name ?? 'Driver',
                          style: AppText.bodySm,
                        ),
                      ],
                    ),
                  ),
                  AppBadge(
                    label: _statusLabel(profile.operationalStatus),
                    tone: profile.operationalStatus == 'AVAILABLE'
                        ? AppBadgeTone.success
                        : AppBadgeTone.neutral,
                  ),
                ],
              ),
              const AppDivider(),
              _Detail(label: 'Phone', value: profile.phone),
              _Detail(label: 'Gender', value: _optionalLabel(profile.gender)),
              _Detail(
                label: 'Experience',
                value:
                    '${profile.experienceYears} '
                    '${profile.experienceYears == 1 ? 'year' : 'years'}',
              ),
              _Detail(
                label: 'Account access',
                value: _statusLabel(profile.accessStatus),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _DocumentCard(
          title: 'Driving licence',
          rows: [
            _Detail(label: 'Number', value: profile.license.number),
            _Detail(label: 'Type', value: profile.license.type),
            _Detail(
              label: 'Valid until',
              value: _formatDate(profile.license.expiry),
            ),
          ],
          uploaded: profile.license.documentUploaded,
        ),
        const SizedBox(height: AppSpacing.md),
        _DocumentCard(
          title: 'Medical certificate',
          rows: [
            _Detail(
              label: 'Valid until',
              value: profile.medicalCertificate.expiry == null
                  ? 'Not provided'
                  : _formatDate(profile.medicalCertificate.expiry!),
            ),
          ],
          uploaded: profile.medicalCertificate.documentUploaded,
        ),
        const SizedBox(height: AppSpacing.xs),
        AppButton.ghost(
          label: 'Refresh profile',
          icon: Icons.refresh_rounded,
          isLoading: refreshing,
          onPressed: onRefresh,
        ),
      ],
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.title,
    required this.rows,
    required this.uploaded,
  });

  final String title;
  final List<Widget> rows;
  final bool uploaded;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: AppText.titleMd)),
            AppBadge(
              label: uploaded ? 'Document on file' : 'Not uploaded',
              tone: uploaded ? AppBadgeTone.success : AppBadgeTone.pending,
            ),
          ],
        ),
        const AppDivider(),
        ...rows,
      ],
    ),
  );
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 116, child: Text(label, style: AppText.bodySm)),
        Expanded(child: Text(value, style: AppText.label)),
      ],
    ),
  );
}

class _ProfileProblem extends StatelessWidget {
  const _ProfileProblem({required this.message, this.icon, this.onRetry});

  final String message;
  final IconData? icon;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon ?? Icons.error_outline_rounded, color: AppColors.danger),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(message, style: AppText.bodySm)),
          ],
        ),
        if (onRetry != null) ...[
          const SizedBox(height: AppSpacing.md),
          AppButton.secondary(label: 'Try again', onPressed: onRetry),
        ],
      ],
    ),
  );
}

class _DriverProfileSkeleton extends StatelessWidget {
  const _DriverProfileSkeleton();

  @override
  Widget build(BuildContext context) => const AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSkeleton(width: 180, height: 20),
        SizedBox(height: AppSpacing.md),
        AppSkeleton(height: 14),
        SizedBox(height: AppSpacing.sm),
        AppSkeleton(width: 220, height: 14),
      ],
    ),
  );
}

String _formatDate(DateTime value) => DateFormat('d MMM yyyy').format(value);

String _optionalLabel(String? value) => value == null
    ? 'Not provided'
    : value[0].toUpperCase() + value.substring(1).toLowerCase();

String _statusLabel(String value) => value
    .split('_')
    .where((part) => part.isNotEmpty)
    .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
    .join(' ');
