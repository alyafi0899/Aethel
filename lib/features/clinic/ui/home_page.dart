import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/context_ext.dart';
import '../../../core/theme/clinic_colors.dart';
import '../../../core/l10n/terms_id.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../data/models.dart';
import '../../../state/app_controller.dart';
import '../../../widgets/buttons.dart';
import '../../../widgets/common.dart';
import '../../operations/models/operational_status.dart';
import '../../operations/ui/internal_operations_page.dart';
import '../../help/support_actions.dart';
import '../data/home_tasks_repository.dart';
import '../models/clinic_enums.dart';
import '../models/onboarding_recommendation.dart';
import '../state/clinic_controller.dart';
import '../widgets/rejected_items_panel.dart';

final _homeTasksRepository = HomeTasksRepository();

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HomeTasksRepository _repository = _homeTasksRepository;
  HomeTasksResult? _result;
  final Set<String> _hiddenSuggestions = {};
  final Set<String> _hiddenRecommendations = {};
  String? _hiddenRecommendationsClinicId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({bool forceRefresh = false}) async {
    final controller = context.read<ClinicController>();
    final showGuide = _result == null && !forceRefresh;
    try {
      final result = await _repository.load(
        controller,
        forceRefresh: forceRefresh,
      );
      final statusLoaded = await controller.refreshOnboardingStatus();
      if (!statusLoaded && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(controller.errorMessage ??
                'Saran klinik belum dapat diperbarui.'),
          ),
        );
      }
      final clinicId = controller.clinicId;
      if (clinicId != null && _hiddenRecommendationsClinicId != clinicId) {
        await _loadHiddenRecommendations(clinicId);
      }
      if (mounted) {
        setState(() {
          _result = result;
          _loading = false;
        });
      }
      if (showGuide && mounted) {
        await _showFirstVisitGuide(controller.clinicId ?? 'clinic');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Data belum dapat dimuat. Coba segarkan kembali.')),
        );
      }
    }
  }

  Future<void> _loadHiddenRecommendations(String clinicId) async {
    if (_hiddenRecommendationsClinicId != clinicId && mounted) {
      setState(_hiddenRecommendations.clear);
    }
    try {
      final preferences = await SharedPreferences.getInstance();
      final hidden = OnboardingRecommendation.byKey.keys
          .where((key) =>
              preferences
                  .getBool(_recommendationPreferenceKey(clinicId, key)) ==
              true)
          .toSet();
      if (!mounted) return;
      setState(() {
        _hiddenRecommendations
          ..clear()
          ..addAll(hidden);
        _hiddenRecommendationsClinicId = clinicId;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Preferensi saran belum dapat dimuat: ${ErrorMapper.mapError(error)}'),
          ),
        );
      }
    }
  }

  Future<void> _hideRecommendation(String recommendationKey) async {
    final clinicId = context.read<ClinicController>().clinicId;
    if (clinicId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Klinik belum tersedia untuk menyimpan saran.')),
      );
      return;
    }

    setState(() => _hiddenRecommendations.add(recommendationKey));
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(
        _recommendationPreferenceKey(clinicId, recommendationKey),
        true,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _hiddenRecommendations.remove(recommendationKey));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Saran belum dapat disembunyikan: ${ErrorMapper.mapError(error)}'),
        ),
      );
    }
  }

  String _recommendationPreferenceKey(String clinicId, String key) =>
      'clinic_home_recommendation_hidden_${clinicId}_$key';

  Future<void> _showFirstVisitGuide(String clinicId) async {
    final key = 'clinic_home_guide_seen_$clinicId';
    try {
      final preferences = await SharedPreferences.getInstance();
      if (preferences.getBool(key) == true || !mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Selamat datang di beranda klinik'),
          content: const Text(
              'Di sini Anda dapat melihat status klinik, mengubah status layanan hari ini, dan membuka daftar hal yang perlu ditindaklanjuti. Ketuk tindakan pada setiap kartu untuk langsung menuju bagian terkait.'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Mengerti'),
            ),
          ],
        ),
      );
      await preferences.setBool(key, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Panduan awal belum dapat ditampilkan: ${ErrorMapper.mapError(error)}')),
        );
      }
    }
  }

  void _openTask(HomeTask task) {
    if (task.destination == null) return;
    final app = context.read<AppController>();
    app.go(task.destination!);
    if (task.profileTab != null) {
      app.selectProfileTab(task.profileTab!);
    }
    if (task.destination == AppPage.clinicReviews) {
      app.focusUnansweredReviews = task.id == 'unanswered-reviews';
      app.selectReviewsTab(task.id == 'new-feedback' ? 1 : 0);
    }
  }

  Future<void> _setMode(OperationalMode mode) async {
    final controller = context.read<ClinicController>();
    final operations = controller.internalOperations;
    if (operations == null) return;
    final updated = operations.copyWith(
      facilityStatus: mode.facilityStatus,
      queueProcessStatus: mode.queueStatus,
    );
    final saved = await controller.updateInternalOperations(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(saved
            ? 'Status klinik berhasil diperbarui.'
            : 'Status belum tersimpan. Periksa koneksi, lalu coba lagi.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clinicController = context.watch<ClinicController>();
    final clinic = clinicController.clinic;
    final result = _result;
    if (_loading && result == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final tasks = result?.tasks ?? const <HomeTask>[];
    final suggestions = (result?.suggestions ?? const <HomeTask>[])
        .where((task) => !_hiddenSuggestions.contains(task.id))
        .toList();
    final recommendations = clinicController.onboardingStatus.recommendations
        .map(OnboardingRecommendation.fromKey)
        .whereType<OnboardingRecommendation>()
        .where((recommendation) =>
            !_hiddenRecommendations.contains(recommendation.key))
        .toList();
    final isSioValid = clinicController.complianceStatus.sioValid;
    final isPublished = clinic?.isPublished ?? false;
    final displayReason = !isSioValid
        ? 'Tidak tampil karena SIO kedaluwarsa.'
        : clinic?.status != ClinicStatus.verified
            ? 'Tidak tampil karena data klinik sedang ditinjau.'
            : isPublished
                ? 'Klinik tampil ke pasien.'
                : 'Belum tampil karena publikasi belum dinyalakan.';

    return RefreshIndicator(
      onRefresh: () => _load(forceRefresh: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Text('Beranda', style: context.sH2),
          const SizedBox(height: 4),
          Text('Ringkasan klinik dan hal yang perlu dilakukan.',
              style: context.sSmall),
          const SizedBox(height: 16),
          _ClinicStatusCard(
            clinicName: clinic?.clinicName ?? 'Klinik Anda',
            status: clinic?.status.userLabel ?? 'Status belum tersedia',
            visible: isPublished && isSioValid,
            visibilityReason: displayReason,
            mode: OperationalMode.fromDatabase(
              facilityStatus:
                  clinicController.internalOperations?.facilityStatus ??
                      FacilityOperatingStatus.closed,
              queueStatus:
                  clinicController.internalOperations?.queueProcessStatus ??
                      QueueProcessStatus.closed,
            ),
            queueNumber:
                clinicController.internalOperations?.currentQueueNumber ?? 0,
            onModeChanged: _setMode,
          ),
          if (clinic?.status == ClinicStatus.rejected)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: RejectedItemsPanel(
                onFix: (step) {
                  final app = context.read<AppController>();
                  if (step == 5) {
                    app.go(AppPage.clinicStaff);
                  } else {
                    app.go(AppPage.clinicProfile);
                    app.selectProfileTab((step - 1).clamp(0, 5));
                  }
                },
              ),
            ),
          const SizedBox(height: 16),
          if (result?.hasPartialFailure == true)
            AppCard(
              child: Row(
                children: [
                  const Icon(Icons.info_outline),
                  const SizedBox(width: 10),
                  const Expanded(
                      child: Text(
                          'Sebagian data belum berhasil dimuat. Coba segarkan kembali.')),
                  TextButton(
                    onPressed: () => _load(forceRefresh: true),
                    child: const Text('Coba lagi'),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                  child: Text('Perlu tindakan hari ini', style: context.sH3)),
              TextButton.icon(
                onPressed: () => _load(forceRefresh: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Segarkan'),
              ),
            ],
          ),
          if (tasks.isEmpty)
            _AllDoneCard(
              doctors:
                  clinicController.internalOperations?.totalDoctorsAvailable ??
                      0,
              rating: clinicController.reviewStats.average,
              reviews: clinicController.reviewStats.count,
            )
          else
            for (final task in tasks) ...[
              _TaskCard(task: task, onOpen: () => _openTask(task)),
              const SizedBox(height: 8),
            ],
          if (suggestions.isNotEmpty || recommendations.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('Saran', style: context.sH3),
            const SizedBox(height: 8),
            for (final suggestion in suggestions)
              _TaskCard(
                task: suggestion,
                onOpen: () => _openTask(suggestion),
                onDismiss: () =>
                    setState(() => _hiddenSuggestions.add(suggestion.id)),
              ),
            for (final recommendation in recommendations)
              _buildRecommendationCard(recommendation),
          ],
          if (hasSupportContact) ...[
            const SizedBox(height: 12),
            AppCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.support_agent_outlined),
                title: const Text('Butuh bantuan?'),
                subtitle:
                    const Text('Hubungi tim dukungan jika menemui kendala.'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => openSupportChat(context),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(OnboardingRecommendation recommendation) {
    final task = HomeTask(
      id: 'recommendation:${recommendation.key}',
      severity: HomeTaskSeverity.info,
      title: recommendation.label,
      body: 'Saran pengaturan klinik.',
      actionLabel: 'Buka',
      destination: AppPage.clinicProfile,
      profileTab: recommendation.profileTabIndex,
      isSuggestion: true,
    );
    return _TaskCard(
      task: task,
      onOpen: () => _openTask(task),
      onDismiss: () => _hideRecommendation(recommendation.key),
    );
  }
}

class _ClinicStatusCard extends StatelessWidget {
  const _ClinicStatusCard({
    required this.clinicName,
    required this.status,
    required this.visible,
    required this.visibilityReason,
    required this.mode,
    required this.queueNumber,
    required this.onModeChanged,
  });

  final String clinicName;
  final String status;
  final bool visible;
  final String visibilityReason;
  final OperationalMode mode;
  final int queueNumber;
  final ValueChanged<OperationalMode> onModeChanged;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(clinicName, style: context.sH3),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Chip(label: Text(status)),
                Chip(
                  avatar: Icon(
                    visible ? Icons.visibility : Icons.visibility_off,
                    size: 18,
                  ),
                  label: Text(visible ? 'Tampil ke pasien' : 'Tidak tampil'),
                ),
              ],
            ),
            Text(visibilityReason, style: context.sSmall),
            const Divider(height: 24),
            Text('Status hari ini · Antrean $queueNumber',
                style: context.sStrong),
            const SizedBox(height: 8),
            OperationalStatusControls(
              selected: mode,
              onChanged: onModeChanged,
            ),
          ],
        ),
      );
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.onOpen,
    this.onDismiss,
  });

  final HomeTask task;
  final VoidCallback onOpen;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final color = switch (task.severity) {
      HomeTaskSeverity.critical => context.c.fg(Tone.red),
      HomeTaskSeverity.warning => context.c.fg(Tone.amber),
      HomeTaskSeverity.info => context.c.primary,
    };
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            task.severity == HomeTaskSeverity.critical
                ? Icons.error_outline
                : task.severity == HomeTaskSeverity.warning
                    ? Icons.warning_amber_rounded
                    : Icons.info_outline,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title, style: context.sStrong),
                const SizedBox(height: 3),
                Text(task.body, style: context.sSmall),
                if (task.reviewNote?.isNotEmpty == true) ...[
                  const SizedBox(height: 6),
                  Text('Catatan peninjau: ${task.reviewNote}',
                      style: context.sSmall.copyWith(color: color)),
                ],
              ],
            ),
          ),
          if (task.actionLabel != null)
            AppButton(
              task.actionLabel!,
              kind: BtnKind.secondary,
              compact: true,
              onPressed: onOpen,
            ),
          if (onDismiss != null)
            IconButton(
              tooltip: 'Sembunyikan saran',
              onPressed: onDismiss,
              icon: const Icon(Icons.close),
            ),
        ],
      ),
    );
  }
}

class _AllDoneCard extends StatelessWidget {
  const _AllDoneCard({
    required this.doctors,
    required this.rating,
    required this.reviews,
  });

  final int doctors;
  final double rating;
  final int reviews;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.check_circle_outline,
                size: 42, color: Colors.green),
            const SizedBox(height: 8),
            Text('Semua beres ✓', style: context.sH3),
            const SizedBox(height: 4),
            Text('Tidak ada hal yang perlu ditindaklanjuti sekarang.',
                style: context.sSmall),
            const SizedBox(height: 14),
            Wrap(
              spacing: 18,
              children: [
                Text('$doctors dokter tersedia'),
                Text('Rating ${rating.toStringAsFixed(1)}'),
                Text('$reviews ulasan'),
              ],
            ),
          ],
        ),
      );
}
