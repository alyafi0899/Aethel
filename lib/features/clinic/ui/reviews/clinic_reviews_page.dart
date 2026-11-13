import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/context_ext.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../state/app_controller.dart';
import '../../../../widgets/buttons.dart';
import '../../../../widgets/common.dart';
import '../../models/clinic_enums.dart';
import '../../models/review_models.dart';
import '../../state/clinic_controller.dart';

class ClinicReviewsPage extends StatefulWidget {
  const ClinicReviewsPage({super.key});

  @override
  State<ClinicReviewsPage> createState() => _ClinicReviewsPageState();
}

class _ClinicReviewsPageState extends State<ClinicReviewsPage> {
  int? _ratingFilter;
  bool _unansweredOnly = false;
  String _periodFilter = 'all';
  String _sortBy = 'newest';

  @override
  Widget build(BuildContext context) {
    final clinicCtrl = context.watch<ClinicController>();
    final appCtrl = context.watch<AppController>();
    if (appCtrl.focusUnansweredReviews && !_unansweredOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _unansweredOnly = true);
        appCtrl.focusUnansweredReviews = false;
      });
    }
    final c = context.c;
    final stats = clinicCtrl.reviewStats;
    final reviews = clinicCtrl.reviews;
    final clinicId = clinicCtrl.clinicId ?? '';

    var filteredReviews = List<ClinicReviewManageModel>.from(reviews);
    if (_ratingFilter != null) {
      filteredReviews =
          filteredReviews.where((r) => r.rating == _ratingFilter).toList();
    }
    if (_unansweredOnly) {
      filteredReviews = filteredReviews.where((r) => !r.replied).toList();
    }
    if (_periodFilter == '30_days') {
      final cutoff = DateTime.now().subtract(const Duration(days: 30));
      filteredReviews = filteredReviews
          .where((r) => r.createdAt != null && r.createdAt!.isAfter(cutoff))
          .toList();
    } else if (_periodFilter == '90_days') {
      final cutoff = DateTime.now().subtract(const Duration(days: 90));
      filteredReviews = filteredReviews
          .where((r) => r.createdAt != null && r.createdAt!.isAfter(cutoff))
          .toList();
    }

    if (_sortBy == 'highest') {
      filteredReviews.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_sortBy == 'lowest') {
      filteredReviews.sort((a, b) => a.rating.compareTo(b.rating));
    } else {
      filteredReviews.sort((a, b) => (b.createdAt ??
              DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ulasan & Rating Klinik', style: context.sH2),
                  Text(
                      'Kelola ulasan pasien terverifikasi, tanggapan klinik, dan laporan moderasi.',
                      style: context.sSmall),
                ],
              ),
              AppButton(
                'Segarkan Ulasan',
                icon: Icons.refresh,
                kind: BtnKind.secondary,
                onPressed: () => clinicCtrl.refreshReviews(),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Statistics Header Block
          AppCard(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Average Star Box
                Column(
                  children: [
                    Text(
                      stats.average.toStringAsFixed(1),
                      style: context.sH1.copyWith(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade800),
                    ),
                    Row(
                      children: List.generate(5, (index) {
                        final starValue = index + 1;
                        return Icon(
                          starValue <= stats.average.round()
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber.shade800,
                          size: 20,
                        );
                      }),
                    ),
                    const SizedBox(height: 4),
                    Text('Total ${stats.count} ulasan', style: context.sSmall),
                  ],
                ),
                const SizedBox(width: 32),
                const VerticalDivider(width: 1),
                const SizedBox(width: 32),

                // Star Distribution Bars
                Expanded(
                  child: Column(
                    children: [5, 4, 3, 2, 1].map((star) {
                      final count = stats.distribution['$star'] ?? 0;
                      final ratio =
                          stats.count > 0 ? (count / stats.count) : 0.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Text('$star',
                                style: context.sSmall
                                    .copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 4),
                            const Icon(Icons.star,
                                size: 14, color: Colors.amber),
                            const SizedBox(width: 8),
                            Expanded(
                              child: LinearProgressIndicator(
                                value: ratio,
                                backgroundColor: c.border,
                                color: Colors.amber.shade700,
                                minHeight: 6,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                                width: 30,
                                child: Text('$count',
                                    style: context.sSmall,
                                    textAlign: TextAlign.right)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 32),
                const VerticalDivider(width: 1),
                const SizedBox(width: 32),

                // Response Metrics
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _metricText('Tingkat Respons', '${stats.responseRate}%'),
                    const SizedBox(height: 8),
                    _metricText('Belum Dibalas', '${stats.unanswered} ulasan'),
                    const SizedBox(height: 8),
                    _metricText(
                        '30 Hari Terakhir', '${stats.last30Days} ulasan'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Filters Bar
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                DropdownButton<int?>(
                  value: _ratingFilter,
                  hint: const Text('Semua Bintang'),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('Semua Bintang')),
                    ...List.generate(
                      5,
                      (i) => DropdownMenuItem(
                          value: 5 - i, child: Text('${5 - i} Bintang')),
                    ),
                  ],
                  onChanged: (v) => setState(() => _ratingFilter = v),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _periodFilter,
                  items: const [
                    DropdownMenuItem(
                        value: 'all', child: Text('Semua Periode')),
                    DropdownMenuItem(
                        value: '30_days', child: Text('30 Hari Terakhir')),
                    DropdownMenuItem(
                        value: '90_days', child: Text('90 Hari Terakhir')),
                  ],
                  onChanged: (v) => setState(() => _periodFilter = v ?? 'all'),
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    Checkbox(
                      value: _unansweredOnly,
                      onChanged: (v) =>
                          setState(() => _unansweredOnly = v ?? false),
                    ),
                    Text('Hanya belum dibalas', style: context.sBody),
                  ],
                ),
                const Spacer(),
                DropdownButton<String>(
                  value: _sortBy,
                  items: const [
                    DropdownMenuItem(value: 'newest', child: Text('Terbaru')),
                    DropdownMenuItem(
                        value: 'highest', child: Text('Rating Tertinggi')),
                    DropdownMenuItem(
                        value: 'lowest', child: Text('Rating Terendah')),
                  ],
                  onChanged: (v) => setState(() => _sortBy = v ?? 'newest'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Reviews List
          if (filteredReviews.isEmpty)
            AppCard(
              padding: const EdgeInsets.all(36),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.rate_review_outlined,
                        size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text('Belum ada ulasan yang sesuai filter.',
                        style: context.sBody
                            .copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                        'Ulasan muncul setelah pasien menyelesaikan kunjungan.',
                        style: context.sSmall),
                  ],
                ),
              ),
            )
          else
            Column(
              children: filteredReviews
                  .map((r) => _reviewCard(context, r, clinicId))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _metricText(String title, String value) {
    return Builder(builder: (context) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.sSmall),
          Text(value, style: context.sH2.copyWith(fontWeight: FontWeight.bold)),
        ],
      );
    });
  }

  Widget _reviewCard(
      BuildContext context, ClinicReviewManageModel review, String clinicId) {
    final c = context.c;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < review.rating
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber.shade800,
                          size: 18,
                        );
                      }),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Pasien Terverifikasi',
                        style: context.sLabel.copyWith(
                            color: Colors.blue.shade800, fontSize: 10),
                      ),
                    ),
                  ],
                ),
                Text(AppFormatters.formatDateTime(review.createdAt),
                    style: context.sSmall),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              review.comment ??
                  '(Pasien memberikan rating tanpa ulasan tertulis)',
              style: context.sBody.copyWith(
                fontStyle: review.comment == null
                    ? FontStyle.italic
                    : FontStyle.normal,
              ),
            ),
            const SizedBox(height: 16),

            // Reply section
            if (review.replied && review.replyBody != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.bg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: c.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Balasan Klinik:',
                            style: context.sBody.copyWith(
                                fontWeight: FontWeight.bold, color: c.accent)),
                        Text(
                            AppFormatters.formatDateTime(review.replyCreatedAt),
                            style: context.sSmall.copyWith(fontSize: 10)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(review.replyBody!,
                        style: context.sBody.copyWith(fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (review.hasOpenReport)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.flag_outlined,
                            size: 14, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text('Dilaporkan - menunggu peninjauan platform',
                            style: TextStyle(
                                color: Colors.orange.shade900, fontSize: 11)),
                      ],
                    ),
                  )
                else
                  TextButton.icon(
                    icon: const Icon(Icons.flag_outlined,
                        size: 16, color: Colors.grey),
                    label: const Text('Laporkan Ulasan',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                    onPressed: () =>
                        _showReportDialog(context, review.reviewId, clinicId),
                  ),
                if (!review.replied)
                  AppButton(
                    'Balas Ulasan',
                    icon: Icons.reply,
                    kind: BtnKind.primary,
                    compact: true,
                    onPressed: () =>
                        _showReplyDialog(context, review.reviewId, clinicId),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showReplyDialog(
      BuildContext context, String reviewId, String clinicId) {
    final clinicCtrl = context.read<ClinicController>();
    final nav = Navigator.of(context);
    final bodyCtrl = TextEditingController();
    bool submitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Balas Ulasan Pasien'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade800),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.amber.shade900, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Balasan bersifat publik dan tidak dapat diubah. Jangan menyebut identitas pasien, diagnosis, atau detail perawatan.',
                        style: TextStyle(
                            color: Colors.amber.shade900, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyCtrl,
                maxLines: 4,
                maxLength: 1000,
                onChanged: (_) => setDialogState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Tuliskan tanggapan resmi dari pihak klinik...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Batal')),
            AppButton(
              'Kirim Balasan',
              icon: Icons.send,
              kind: BtnKind.primary,
              loading: submitting,
              onPressed: bodyCtrl.text.trim().isEmpty || submitting
                  ? null
                  : () async {
                      final confirm = await showDialog<bool>(
                        context: ctx,
                        builder: (c2) => AlertDialog(
                          title: const Text('Konfirmasi Balasan'),
                          content: const Text(
                              'Balasan ulasan bersifat publik dan tidak dapat diubah atau dihapus. Kirim balasan sekarang?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(c2).pop(false),
                              child: const Text('Batal'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(c2).pop(true),
                              child: const Text('Ya, Kirim'),
                            ),
                          ],
                        ),
                      );
                      if (confirm != true) return;

                      setDialogState(() => submitting = true);
                      final ok = await clinicCtrl.replyToReview(
                        reviewId: reviewId,
                        body: bodyCtrl.text.trim(),
                      );
                      setDialogState(() => submitting = false);
                      if (ok && nav.mounted) {
                        nav.pop();
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDialog(
      BuildContext context, String reviewId, String clinicId) {
    final detailsCtrl = TextEditingController();
    ReportReason selectedReason = ReportReason.false_information;
    bool submitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Laporkan Ulasan ke Platform'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pilih alasan pengajuan laporan moderasi ulasan:'),
              const SizedBox(height: 10),
              DropdownButtonFormField<ReportReason>(
                initialValue: selectedReason,
                items: ReportReason.values
                    .map(
                        (r) => DropdownMenuItem(value: r, child: Text(r.label)))
                    .toList(),
                onChanged: (v) => setDialogState(
                    () => selectedReason = v ?? ReportReason.other),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: detailsCtrl,
                maxLines: 3,
                maxLength: 1000,
                decoration: const InputDecoration(
                  hintText: 'Penjelasan tambahan (opsional)...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Keputusan moderasi ada di tim platform; klinik tidak dapat menghapus ulasan secara sepihak.',
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Batal')),
            AppButton(
              'Kirim Laporan',
              icon: Icons.flag,
              kind: BtnKind.danger,
              loading: submitting,
              onPressed: submitting
                  ? null
                  : () async {
                      setDialogState(() => submitting = true);
                      final clinicCtrl = context.read<ClinicController>();
                      final ok = await clinicCtrl.reportReview(
                        reviewId: reviewId,
                        reason: selectedReason,
                        details: detailsCtrl.text.trim().isNotEmpty
                            ? detailsCtrl.text.trim()
                            : null,
                      );
                      setDialogState(() => submitting = false);
                      if (ok && ctx.mounted) {
                        Navigator.of(ctx).pop();
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}
