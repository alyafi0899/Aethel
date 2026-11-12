import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/context_ext.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../widgets/buttons.dart';
import '../../../../widgets/common.dart';
import '../../models/clinic_enums.dart';
import '../../models/feedback_model.dart';
import '../../state/clinic_controller.dart';

class ClinicFeedbackPage extends StatefulWidget {
  const ClinicFeedbackPage({super.key});

  @override
  State<ClinicFeedbackPage> createState() => _ClinicFeedbackPageState();
}

class _ClinicFeedbackPageState extends State<ClinicFeedbackPage> {
  FeedbackStatus? _statusFilter;
  FeedbackCategory? _categoryFilter;

  @override
  Widget build(BuildContext context) {
    final clinicCtrl = context.watch<ClinicController>();
    final feedbackList = clinicCtrl.feedbackList;

    var filtered = List<ClinicFeedbackPrivateModel>.from(feedbackList);
    if (_statusFilter != null) {
      filtered = filtered.where((f) => f.status == _statusFilter).toList();
    }
    if (_categoryFilter != null) {
      filtered = filtered.where((f) => f.category == _categoryFilter).toList();
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
                  Text('Masukan Privat Pasien', style: context.sH2),
                  Text(
                      'Kelola masukan, kritik, dan saran internal yang disampaikan langsung oleh pasien.',
                      style: context.sSmall),
                ],
              ),
              AppButton(
                'Segarkan Masukan',
                icon: Icons.refresh,
                kind: BtnKind.secondary,
                onPressed: () => clinicCtrl.refreshFeedback(),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Privacy Warning Banner
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.security, color: Colors.blue, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kerahasiaan Masukan Privat Pasien',
                        style: context.sBody.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900),
                      ),
                      Text(
                        'Masukan ini hanya terlihat oleh klinik Anda dan dapat memuat informasi kesehatan. Jangan dibagikan di luar tim yang berwenang.',
                        style: context.sSmall.copyWith(
                            color: Colors.blue.shade900, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Filters Bar
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                DropdownButton<FeedbackStatus?>(
                  value: _statusFilter,
                  hint: const Text('Semua Status'),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('Semua Status')),
                    ...FeedbackStatus.values.map(
                      (s) => DropdownMenuItem(value: s, child: Text(s.label)),
                    ),
                  ],
                  onChanged: (v) => setState(() => _statusFilter = v),
                ),
                const SizedBox(width: 16),
                DropdownButton<FeedbackCategory?>(
                  value: _categoryFilter,
                  hint: const Text('Semua Kategori'),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('Semua Kategori')),
                    ...FeedbackCategory.values.map(
                      (cat) =>
                          DropdownMenuItem(value: cat, child: Text(cat.label)),
                    ),
                  ],
                  onChanged: (v) => setState(() => _categoryFilter = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Feedback List
          if (filtered.isEmpty)
            AppCard(
              padding: const EdgeInsets.all(36),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.inbox_outlined,
                        size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text('Belum ada masukan privat pasien.',
                        style: context.sBody
                            .copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Masukan privat pasien akan muncul di sini.',
                        style: context.sSmall),
                  ],
                ),
              ),
            )
          else
            Column(
              children:
                  filtered.map((item) => _feedbackCard(context, item)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _feedbackCard(BuildContext context, ClinicFeedbackPrivateModel item) {
    final c = context.c;
    final isNew = item.status == FeedbackStatus.newStatus;

    Color badgeCol = Colors.blue.shade800;
    if (item.status == FeedbackStatus.read) {
      badgeCol = Colors.amber.shade900;
    }
    if (item.status == FeedbackStatus.resolved) {
      badgeCol = Colors.green.shade800;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(20),
        borderColor: isNew ? c.accent : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeCol.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.status.label,
                        style: TextStyle(
                            color: badgeCol,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: c.border),
                      ),
                      child: Text(
                        'Kategori: ${item.category.label}',
                        style: context.sSmall.copyWith(fontSize: 11),
                      ),
                    ),
                  ],
                ),
                Text(AppFormatters.formatDateTime(item.createdAt),
                    style: context.sSmall),
              ],
            ),
            const SizedBox(height: 12),
            Text(item.message, style: context.sBody.copyWith(fontSize: 14)),
            const SizedBox(height: 12),
            if (item.internalNote != null && item.internalNote!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: c.bg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: c.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.note_alt_outlined,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Catatan Internal Klinik: ${item.internalNote}',
                        style: context.sSmall.copyWith(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isNew)
                  AppButton(
                    'Tandai Dibaca',
                    icon: Icons.mark_email_read_outlined,
                    kind: BtnKind.secondary,
                    compact: true,
                    onPressed: () {
                      context.read<ClinicController>().updateFeedbackStatus(
                            feedbackId: item.id,
                            status: FeedbackStatus.read,
                          );
                    },
                  ),
                const SizedBox(width: 8),
                AppButton(
                  'Tindak Lanjuti & Detail',
                  icon: Icons.edit_note,
                  kind: BtnKind.primary,
                  compact: true,
                  onPressed: () => _showDetailDialog(context, item),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailDialog(
      BuildContext context, ClinicFeedbackPrivateModel item) {
    final noteCtrl = TextEditingController(text: item.internalNote ?? '');
    FeedbackStatus selectedStatus = item.status;
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tindak Lanjuti Masukan Privat'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Kategori: ${item.category.label}',
                  style: context.sSmall.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(item.message, style: context.sBody),
              const SizedBox(height: 16),
              Text('Ubah Status Masukan:',
                  style: context.sBody.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              DropdownButtonFormField<FeedbackStatus>(
                initialValue: selectedStatus,
                items: FeedbackStatus.values
                    .map(
                        (s) => DropdownMenuItem(value: s, child: Text(s.label)))
                    .toList(),
                onChanged: (v) =>
                    setDialogState(() => selectedStatus = v ?? item.status),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Catatan Internal Klinik',
                  hintText:
                      'Tuliskan tindakan yang telah diambil oleh tim klinik...',
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
              'Simpan Perubahan',
              icon: Icons.check,
              kind: BtnKind.primary,
              loading: saving,
              onPressed: saving
                  ? null
                  : () async {
                      setDialogState(() => saving = true);
                      final clinicCtrl = context.read<ClinicController>();
                      final ok = await clinicCtrl.updateFeedbackStatus(
                        feedbackId: item.id,
                        status: selectedStatus,
                        internalNote: noteCtrl.text.trim().isNotEmpty
                            ? noteCtrl.text.trim()
                            : null,
                      );
                      setDialogState(() => saving = false);
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
