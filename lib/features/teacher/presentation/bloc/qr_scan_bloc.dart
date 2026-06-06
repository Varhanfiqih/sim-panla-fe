import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/qr_scan.dart';
import '../../data/repositories/qr_scan_repository.dart';

part 'qr_scan_event.dart';
part 'qr_scan_state.dart';

class QrScanBloc extends Bloc<QrScanEvent, QrScanState> {
  final QrScanRepository _repository;

  QrScanBloc({QrScanRepository? repository})
    : _repository = repository ?? QrScanRepository(),
      super(const QrScanInitial()) {
    on<LoadCategories>(_onLoadCategories);
    on<SelectActivity>(_onSelectActivity);
    on<SelectCategory>(_onSelectCategory);
    on<ProcessScan>(_onProcessScan);
    on<SubmitScan>(_onSubmitScan);
    on<ClearScanResult>(_onClearScanResult);
    on<ToggleFlashlight>(_onToggleFlashlight);
    on<ResetScanner>(_onResetScanner);
  }

  Future<void> _onLoadCategories(
    LoadCategories event,
    Emitter<QrScanState> emit,
  ) async {
    emit(const QrScanCategoriesLoading());
    try {
      final activities = await _repository.getCategories();
      final recentScans = await _repository.getRecentScans(limit: 20);

      final defaultActivity = activities.isNotEmpty ? activities.first : null;
      final defaultCategory = defaultActivity?.scanTypes.isNotEmpty == true
          ? defaultActivity!.scanTypes.first
          : null;

      emit(
        QrScanReady(
          activities: activities,
          selectedActivity: defaultActivity,
          selectedCategory: defaultCategory,
          recentScans: recentScans,
        ),
      );
    } catch (e) {
      emit(QrScanCategoriesError(e.toString()));
    }
  }

  void _onSelectActivity(SelectActivity event, Emitter<QrScanState> emit) {
    if (state is QrScanReady) {
      final currentState = state as QrScanReady;
      // When activity changes, auto-select its first scan type
      final defaultCategory = event.activity.scanTypes.isNotEmpty
          ? event.activity.scanTypes.first
          : null;

      emit(
        currentState.copyWith(
          selectedActivity: event.activity,
          selectedCategory: defaultCategory,
        ),
      );
    }
  }

  void _onSelectCategory(SelectCategory event, Emitter<QrScanState> emit) {
    if (state is QrScanReady) {
      final currentState = state as QrScanReady;
      emit(currentState.copyWith(selectedCategory: event.category));
    }
  }

  Future<void> _onProcessScan(
    ProcessScan event,
    Emitter<QrScanState> emit,
  ) async {
    if (state is! QrScanReady) return;

    final currentState = state as QrScanReady;

    // Validate QR data (should be NISN)
    final qrData = event.qrData.trim();
    if (qrData.isEmpty) {
      emit(
        QrScanError(
          message: 'QR Code tidak valid',
          activities: currentState.activities,
          selectedActivity: currentState.selectedActivity,
          selectedCategory: currentState.selectedCategory,
          recentScans: currentState.recentScans,
        ),
      );
      return;
    }

    emit(
      QrScanProcessing(
        qrData: qrData,
        activities: currentState.activities,
        selectedActivity: currentState.selectedActivity,
        selectedCategory: currentState.selectedCategory,
        recentScans: currentState.recentScans,
      ),
    );

    // Auto-submit with selected category
    if (currentState.selectedCategory != null) {
      add(SubmitScan(nisn: qrData));
    } else {
      emit(
        QrScanError(
          message: 'Pilih kategori absensi terlebih dahulu',
          activities: currentState.activities,
          selectedActivity: currentState.selectedActivity,
          selectedCategory: currentState.selectedCategory,
          recentScans: currentState.recentScans,
        ),
      );
    }
  }

  Future<void> _onSubmitScan(
    SubmitScan event,
    Emitter<QrScanState> emit,
  ) async {
    List<ActivityGroup> activities = [];
    ActivityGroup? selectedActivity;
    AttendanceCategory? selectedCategory;
    List<ScanHistoryItem> recentScans = [];

    if (state is QrScanProcessing) {
      final currentState = state as QrScanProcessing;
      activities = currentState.activities;
      selectedActivity = currentState.selectedActivity;
      selectedCategory = currentState.selectedCategory;
      recentScans = currentState.recentScans;
    } else if (state is QrScanReady) {
      final currentState = state as QrScanReady;
      activities = currentState.activities;
      selectedActivity = currentState.selectedActivity;
      selectedCategory = currentState.selectedCategory;
      recentScans = currentState.recentScans;
    }

    if (selectedCategory == null) {
      emit(
        QrScanError(
          message: 'Pilih kategori absensi terlebih dahulu',
          activities: activities,
          selectedActivity: selectedActivity,
          selectedCategory: selectedCategory,
          recentScans: recentScans,
        ),
      );
      return;
    }

    try {
        // Only Reguler should omit the kegiatan label.
        final kegiatan = selectedActivity?.activity != 'Reguler'
          ? selectedActivity?.activity
          : null;

      final response = await _repository.submitScan(
        nisn: event.nisn,
        categoryId: selectedCategory.id,
        notes: kegiatan ?? event.notes,
      );

      // Refresh recent scans
      final recentScans = await _repository.getRecentScans(limit: 20);

      emit(
        QrScanSuccess(
          response: response,
          activities: activities,
          selectedActivity: selectedActivity,
          selectedCategory: selectedCategory,
          recentScans: recentScans,
        ),
      );
    } catch (e) {
      emit(
        QrScanError(
          message: e.toString().replaceAll('Exception: ', ''),
          activities: activities,
          selectedActivity: selectedActivity,
          selectedCategory: selectedCategory,
          recentScans: recentScans,
        ),
      );
    }
  }

  void _onClearScanResult(ClearScanResult event, Emitter<QrScanState> emit) {
    if (state is QrScanSuccess || state is QrScanError) {
      List<ActivityGroup> activities = [];
      ActivityGroup? selectedActivity;
      AttendanceCategory? selectedCategory;
      List<ScanHistoryItem> recentScans = [];

      if (state is QrScanSuccess) {
        final currentState = state as QrScanSuccess;
        activities = currentState.activities;
        selectedActivity = currentState.selectedActivity;
        selectedCategory = currentState.selectedCategory;
        recentScans = currentState.recentScans;
      } else if (state is QrScanError) {
        final currentState = state as QrScanError;
        activities = currentState.activities;
        selectedActivity = currentState.selectedActivity;
        selectedCategory = currentState.selectedCategory;
        recentScans = currentState.recentScans;
      }

      emit(
        QrScanReady(
          activities: activities,
          selectedActivity: selectedActivity,
          selectedCategory: selectedCategory,
          recentScans: recentScans,
        ),
      );
    }
  }

  void _onToggleFlashlight(ToggleFlashlight event, Emitter<QrScanState> emit) {
    if (state is QrScanReady) {
      final currentState = state as QrScanReady;
      emit(currentState.copyWith(flashlightOn: !currentState.flashlightOn));
    }
  }

  void _onResetScanner(ResetScanner event, Emitter<QrScanState> emit) {
    emit(const QrScanInitial());
    add(const LoadCategories());
  }
}
