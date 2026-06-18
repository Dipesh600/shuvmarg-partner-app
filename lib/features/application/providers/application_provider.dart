import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shuvmarg_partner_app/core/services/api_service.dart';
import 'package:shuvmarg_partner_app/core/services/auth_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODEL — All 4 steps consolidated in one draft
// ─────────────────────────────────────────────────────────────────────────────

class ApplicationDraft {
  // ── Step 1: Personal ──────────────────────────────────────────────────────
  final String? district;
  final String? municipality;

  // ── Step 2: Business ──────────────────────────────────────────────────────
  final String? businessName;
  final String? shopAddress;
  final String? operationType;
  final String? claimedMonthlyVolume;
  final String? currentOperators;
  final String? referralSource;

  // ── Step 3: Documents (local files — before upload) ───────────────────────
  final Map<String, File?> localFiles;
  // Upload states per document type
  final Map<String, DocUploadState> uploadStates;

  // ── Step 4: Settlement ────────────────────────────────────────────────────
  final String? settlementMethod;
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankAccountName;
  final String? esewaNumber;
  final String? khaltiNumber;

  // ── Server response fields ─────────────────────────────────────────────────
  final String? serverAgentId;
  final String? applicationStatus;
  final String? rejectionReason;
  final String? moreInfoRequest;
  final bool isSaving;
  final String? errorMessage;

  const ApplicationDraft({
    this.district,
    this.municipality,
    this.businessName,
    this.shopAddress,
    this.operationType,
    this.claimedMonthlyVolume,
    this.currentOperators,
    this.referralSource,
    this.localFiles = const {},
    this.uploadStates = const {},
    this.settlementMethod,
    this.bankName,
    this.bankAccountNumber,
    this.bankAccountName,
    this.esewaNumber,
    this.khaltiNumber,
    this.serverAgentId,
    this.applicationStatus,
    this.rejectionReason,
    this.moreInfoRequest,
    this.isSaving = false,
    this.errorMessage,
  });

  ApplicationDraft copyWith({
    String? district,
    String? municipality,
    String? businessName,
    String? shopAddress,
    String? operationType,
    String? claimedMonthlyVolume,
    String? currentOperators,
    String? referralSource,
    Map<String, File?>? localFiles,
    Map<String, DocUploadState>? uploadStates,
    String? settlementMethod,
    String? bankName,
    String? bankAccountNumber,
    String? bankAccountName,
    String? esewaNumber,
    String? khaltiNumber,
    String? serverAgentId,
    String? applicationStatus,
    String? rejectionReason,
    String? moreInfoRequest,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ApplicationDraft(
      district: district ?? this.district,
      municipality: municipality ?? this.municipality,
      businessName: businessName ?? this.businessName,
      shopAddress: shopAddress ?? this.shopAddress,
      operationType: operationType ?? this.operationType,
      claimedMonthlyVolume: claimedMonthlyVolume ?? this.claimedMonthlyVolume,
      currentOperators: currentOperators ?? this.currentOperators,
      referralSource: referralSource ?? this.referralSource,
      localFiles: localFiles ?? this.localFiles,
      uploadStates: uploadStates ?? this.uploadStates,
      settlementMethod: settlementMethod ?? this.settlementMethod,
      bankName: bankName ?? this.bankName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankAccountName: bankAccountName ?? this.bankAccountName,
      esewaNumber: esewaNumber ?? this.esewaNumber,
      khaltiNumber: khaltiNumber ?? this.khaltiNumber,
      serverAgentId: serverAgentId ?? this.serverAgentId,
      applicationStatus: applicationStatus ?? this.applicationStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      moreInfoRequest: moreInfoRequest ?? this.moreInfoRequest,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  bool get requiredDocsUploaded {
    const required = ['citizenship_front', 'citizenship_back', 'shop_photo'];
    return required.every(
      (type) => uploadStates[type] == DocUploadState.uploaded,
    );
  }
}

enum DocUploadState { idle, uploading, uploaded, error }

// ─────────────────────────────────────────────────────────────────────────────
// NOTIFIER
// ─────────────────────────────────────────────────────────────────────────────

class ApplicationNotifier extends StateNotifier<ApplicationDraft> {
  final Ref _ref;

  ApplicationNotifier(this._ref) : super(const ApplicationDraft());

  String? get _token => _ref.read(accessTokenProvider);

  // ── Step 1: Save personal details ────────────────────────────────────────
  Future<bool> saveStep1({
    required String district,
    required String municipality,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final token = _token;
      if (token == null) throw Exception('Not authenticated');

      final res = await AgentApi.saveDraft({
        'district': district,
        'municipality': municipality,
      }, token);

      if (res['success'] == true) {
        state = state.copyWith(
          district: district,
          municipality: municipality,
          serverAgentId: res['data']?['agentId'],
          applicationStatus: res['data']?['applicationStatus'],
          isSaving: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isSaving: false,
          errorMessage: res['message'] ?? 'Failed to save. Please try again.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return false;
    }
  }

  // ── Step 2: Save business details ─────────────────────────────────────────
  Future<bool> saveStep2({
    required String businessName,
    required String shopAddress,
    required String operationType,
    required String claimedMonthlyVolume,
    String? currentOperators,
    required String referralSource,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final token = _token;
      if (token == null) throw Exception('Not authenticated');

      final res = await AgentApi.saveDraft({
        'businessName': businessName,
        'shopAddress': shopAddress,
        'operationType': operationType,
        'claimedMonthlyVolume': claimedMonthlyVolume,
        if (currentOperators != null && currentOperators.isNotEmpty)
          'currentOperators': currentOperators,
        'referralSource': referralSource,
      }, token);

      if (res['success'] == true) {
        state = state.copyWith(
          businessName: businessName,
          shopAddress: shopAddress,
          operationType: operationType,
          claimedMonthlyVolume: claimedMonthlyVolume,
          currentOperators: currentOperators,
          referralSource: referralSource,
          isSaving: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isSaving: false,
          errorMessage: res['message'] ?? 'Failed to save. Please try again.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return false;
    }
  }

  // ── Step 3: Upload a single document ──────────────────────────────────────
  Future<bool> uploadDocument({
    required File file,
    required String documentType,
  }) async {
    final token = _token;
    if (token == null) return false;

    // Mark uploading
    final newStates = Map<String, DocUploadState>.from(state.uploadStates);
    final newFiles = Map<String, File?>.from(state.localFiles);
    newStates[documentType] = DocUploadState.uploading;
    newFiles[documentType] = file;
    state = state.copyWith(uploadStates: newStates, localFiles: newFiles);

    try {
      final res = await AgentApi.uploadDocument(
        file: file,
        documentType: documentType,
        token: token,
      );

      final updated = Map<String, DocUploadState>.from(state.uploadStates);
      if (res['success'] == true) {
        updated[documentType] = DocUploadState.uploaded;
        state = state.copyWith(uploadStates: updated);
        return true;
      } else {
        updated[documentType] = DocUploadState.error;
        state = state.copyWith(
          uploadStates: updated,
          errorMessage: res['message'] ?? 'Upload failed.',
        );
        return false;
      }
    } catch (e) {
      final updated = Map<String, DocUploadState>.from(state.uploadStates);
      updated[documentType] = DocUploadState.error;
      state = state.copyWith(uploadStates: updated, errorMessage: e.toString());
      return false;
    }
  }

  /// Remove a previously uploaded doc (local only — user can re-upload)
  void removeDocument(String documentType) {
    final newStates = Map<String, DocUploadState>.from(state.uploadStates);
    final newFiles = Map<String, File?>.from(state.localFiles);
    newStates[documentType] = DocUploadState.idle;
    newFiles[documentType] = null;
    state = state.copyWith(uploadStates: newStates, localFiles: newFiles);
  }

  // ── Step 4: Save settlement + submit application ───────────────────────────
  Future<bool> saveSettlementAndSubmit({
    required String settlementMethod,
    String? bankName,
    String? bankAccountNumber,
    String? bankAccountName,
    String? esewaNumber,
    String? khaltiNumber,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final token = _token;
      if (token == null) throw Exception('Not authenticated');

      // First save settlement data
      final saveRes = await AgentApi.saveDraft({
        'settlementMethod': settlementMethod,
        if (bankName != null) 'bankName': bankName,
        if (bankAccountNumber != null) 'bankAccountNumber': bankAccountNumber,
        if (bankAccountName != null) 'bankAccountName': bankAccountName,
        if (esewaNumber != null) 'esewaNumber': esewaNumber,
        if (khaltiNumber != null) 'khaltiNumber': khaltiNumber,
      }, token);

      if (saveRes['success'] != true) {
        state = state.copyWith(
          isSaving: false,
          errorMessage: saveRes['message'] ?? 'Failed to save settlement.',
        );
        return false;
      }

      // Then submit for review
      final submitRes = await AgentApi.submitApplication(token);

      if (submitRes['success'] == true) {
        state = state.copyWith(
          settlementMethod: settlementMethod,
          bankName: bankName,
          bankAccountNumber: bankAccountNumber,
          bankAccountName: bankAccountName,
          esewaNumber: esewaNumber,
          khaltiNumber: khaltiNumber,
          applicationStatus: 'PENDING',
          serverAgentId: submitRes['data']?['agentId'] ?? state.serverAgentId,
          isSaving: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isSaving: false,
          errorMessage: submitRes['message'] ?? 'Submission failed.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return false;
    }
  }

  // ── Fetch status from server (called by status screen) ───────────────────
  Future<void> loadStatus() async {
    final token = _token;
    if (token == null) return;
    try {
      final res = await AgentApi.getStatus(token);
      if (res['success'] == true && res['data'] != null) {
        final data = res['data'] as Map<String, dynamic>;
        state = state.copyWith(
          serverAgentId: data['agentId'],
          applicationStatus: data['applicationStatus'],
          rejectionReason: data['rejectionReason'],
          moreInfoRequest: data['moreInfoRequest'],
        );
      }
    } catch (_) {
      // Silently fail — status screen shows last known state
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

// ─────────────────────────────────────────────────────────────────────────────
// PROVIDER
// ─────────────────────────────────────────────────────────────────────────────

final applicationProvider =
    StateNotifierProvider<ApplicationNotifier, ApplicationDraft>(
  (ref) => ApplicationNotifier(ref),
);
