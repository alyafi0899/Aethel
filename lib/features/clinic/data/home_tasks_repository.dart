import '../../../data/models.dart';
import '../models/clinic_enums.dart';
import '../state/clinic_controller.dart';

enum HomeTaskSeverity { critical, warning, info }

class HomeTask {
  const HomeTask({
    required this.id,
    required this.severity,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.destination,
    this.profileTab,
    this.reviewNote,
    this.isSuggestion = false,
  });

  final String id;
  final HomeTaskSeverity severity;
  final String title;
  final String body;
  final String? actionLabel;
  final AppPage? destination;
  final int? profileTab;
  final String? reviewNote;
  final bool isSuggestion;
}

class HomeTasksResult {
  const HomeTasksResult({
    required this.tasks,
    required this.suggestions,
    required this.hasPartialFailure,
  });

  final List<HomeTask> tasks;
  final List<HomeTask> suggestions;
  final bool hasPartialFailure;
}

class HomeTasksRepository {
  HomeTasksRepository({
    this.cacheDuration = const Duration(seconds: 60),
    Future<bool> Function()? refreshSources,
  }) : _refreshSources = refreshSources;

  final Duration cacheDuration;
  final Future<bool> Function()? _refreshSources;
  DateTime? _cachedAt;
  HomeTasksResult? _cached;
  String? _cachedClinicId;

  Future<HomeTasksResult> load(
    ClinicController controller, {
    bool forceRefresh = false,
  }) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _cached != null &&
        _cachedClinicId == controller.clinicId &&
        _cachedAt != null &&
        now.difference(_cachedAt!) < cacheDuration) {
      return _cached!;
    }

    final allSourcesLoaded =
        await (_refreshSources?.call() ?? controller.refreshHomeTaskData());
    final result = buildTasks(controller, hasPartialFailure: !allSourcesLoaded);
    _cached = result;
    _cachedAt = now;
    _cachedClinicId = controller.clinicId;
    return result;
  }

  static HomeTasksResult buildTasks(
    ClinicController controller, {
    bool hasPartialFailure = false,
  }) {
    final tasks = <HomeTask>[];
    final suggestions = <HomeTask>[];

    for (final document in controller.clinicDocuments.where(
      (item) => item.reviewStatus == DocumentReviewStatus.rejected,
    )) {
      tasks.add(HomeTask(
        id: 'document:${document.id}',
        severity: HomeTaskSeverity.critical,
        title: 'Dokumen perlu diperbaiki',
        body: document.docType.label,
        reviewNote: document.reviewNote,
        actionLabel: 'Perbaiki',
        destination: AppPage.clinicProfile,
        profileTab: 2,
      ));
    }

    for (final media in controller.mediaList.where(
      (item) => item.reviewStatus == DocumentReviewStatus.rejected,
    )) {
      tasks.add(HomeTask(
        id: 'media:${media.id}',
        severity: HomeTaskSeverity.critical,
        title: 'Foto perlu diperbaiki',
        body: switch (media.kind) {
          MediaKind.logo => 'Logo Klinik',
          MediaKind.cover => 'Sampul Klinik',
          MediaKind.gallery => 'Foto galeri',
        },
        reviewNote: media.reviewNote,
        actionLabel: 'Perbaiki',
        destination: AppPage.clinicProfile,
        profileTab: 4,
      ));
    }

    for (final worker
        in controller.healthWorkers.where((item) => item.isActive)) {
      for (final document in worker.documents.where(
        (item) => item.reviewStatus == DocumentReviewStatus.rejected,
      )) {
        tasks.add(HomeTask(
          id: 'worker:${document.id}',
          severity: HomeTaskSeverity.critical,
          title: 'Dokumen tenaga kesehatan perlu diperbaiki',
          body: '${worker.fullName} · ${document.docType.label}',
          reviewNote: document.reviewNote,
          actionLabel: 'Perbaiki',
          destination: AppPage.clinicStaff,
        ));
      }
    }

    final complianceTasks = controller.complianceStatus.alerts.map((alert) {
      return HomeTask(
        id: 'compliance:${alert.id}',
        severity: alert.severity == AlertSeverity.critical
            ? HomeTaskSeverity.critical
            : HomeTaskSeverity.warning,
        title: 'Periksa masa berlaku izin',
        body: alert.message,
        actionLabel: 'Perbarui',
        destination: alert.type.startsWith('sio')
            ? AppPage.clinicProfile
            : AppPage.clinicStaff,
        profileTab: alert.type.startsWith('sio') ? 0 : null,
      );
    }).toList()
      ..sort((a, b) => a.severity.index.compareTo(b.severity.index));
    tasks.addAll(complianceTasks);

    final clinic = controller.clinic;
    if (clinic?.status == ClinicStatus.verified &&
        clinic?.isPublished == false &&
        controller.complianceStatus.sioValid) {
      tasks.add(const HomeTask(
        id: 'publish-clinic',
        severity: HomeTaskSeverity.warning,
        title: 'Klinik belum tampil ke pasien',
        body: 'Informasi klinik belum terlihat di aplikasi pasien.',
        actionLabel: 'Tampilkan ke pasien',
        destination: AppPage.clinicProfile,
        profileTab: 4,
      ));
    }

    if (controller.reviewStats.unanswered > 0) {
      tasks.add(HomeTask(
        id: 'unanswered-reviews',
        severity: HomeTaskSeverity.warning,
        title: '${controller.reviewStats.unanswered} ulasan belum dibalas',
        body: 'Balasan membantu pasien mengetahui bahwa masukannya dibaca.',
        actionLabel: 'Balas ulasan',
        destination: AppPage.clinicReviews,
      ));
    }

    if (controller.unreadFeedbackCount > 0) {
      tasks.add(HomeTask(
        id: 'new-feedback',
        severity: HomeTaskSeverity.warning,
        title: '${controller.unreadFeedbackCount} masukan baru',
        body: 'Baca masukan privat dari pasien.',
        actionLabel: 'Baca masukan',
        destination: AppPage.clinicReviews,
      ));
    }

    final updatedAt = controller.internalOperations?.lastUpdateTimestamp;
    if (updatedAt == null || !_isTodayInJakarta(updatedAt)) {
      tasks.add(const HomeTask(
        id: 'daily-operations',
        severity: HomeTaskSeverity.info,
        title: 'Status hari ini belum diperbarui',
        body: 'Pastikan pasien mendapat informasi jam layanan yang sesuai.',
        actionLabel: 'Atur status hari ini',
        destination: AppPage.clinicOperationsInternal,
      ));
    }

    if (clinic?.status == ClinicStatus.under_review) {
      tasks.add(const HomeTask(
        id: 'under-review',
        severity: HomeTaskSeverity.info,
        title: 'Data klinik sedang ditinjau',
        body: 'Perubahan data legal sedang diperiksa oleh tim verifikasi.',
        actionLabel: null,
        destination: null,
      ));
    }

    if (controller.reviewStats.count > 0 &&
        controller.reviewStats.replied == 0) {
      suggestions.add(const HomeTask(
        id: 'suggest-reply',
        severity: HomeTaskSeverity.info,
        title: 'Balas ulasan pasien',
        body: 'Balasan yang ramah menunjukkan bahwa setiap masukan berarti.',
        actionLabel: 'Lihat ulasan',
        destination: AppPage.clinicReviews,
        isSuggestion: true,
      ));
    }

    tasks.sort((a, b) => a.severity.index.compareTo(b.severity.index));
    return HomeTasksResult(
      tasks: tasks,
      suggestions: suggestions,
      hasPartialFailure: hasPartialFailure,
    );
  }

  static bool _isTodayInJakarta(DateTime value) {
    final jakarta = value.toUtc().add(const Duration(hours: 7));
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    return jakarta.year == now.year &&
        jakarta.month == now.month &&
        jakarta.day == now.day;
  }
}
