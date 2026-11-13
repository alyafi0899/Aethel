import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/clinic_colors.dart';
import '../../../core/theme/context_ext.dart';
import '../models/clinic_enums.dart';
import '../state/clinic_controller.dart';

class RejectedItemsPanel extends StatelessWidget {
  const RejectedItemsPanel({super.key, required this.onFix});

  final ValueChanged<int> onFix;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ClinicController>();
    final items = <_RejectedItem>[];

    for (final document in controller.clinicDocuments.where(
      (item) => item.reviewStatus == DocumentReviewStatus.rejected,
    )) {
      items.add(_RejectedItem(
        title: document.docType.label,
        note: document.reviewNote,
        step: _documentStep(document.docType),
      ));
    }

    for (final media in controller.mediaList.where(
      (item) => item.reviewStatus == DocumentReviewStatus.rejected,
    )) {
      items.add(_RejectedItem(
        title: switch (media.kind) {
          MediaKind.logo => 'Logo Klinik',
          MediaKind.cover => 'Sampul Klinik',
          MediaKind.gallery => 'Foto Galeri',
        },
        note: media.reviewNote,
        step: 1,
      ));
    }

    for (final worker in controller.healthWorkers) {
      for (final document in worker.documents.where(
        (item) => item.reviewStatus == DocumentReviewStatus.rejected,
      )) {
        items.add(_RejectedItem(
          title: '${document.docType.label} · ${worker.fullName}',
          note: document.reviewNote,
          step: 5,
        ));
      }
    }

    if (items.isEmpty) return const SizedBox.shrink();
    return Card(
      color: context.c.soft(Tone.red),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Perlu diperbaiki', style: context.sH3),
            const SizedBox(height: 8),
            for (final item in items)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.error_outline, color: Colors.red),
                title: Text(item.title),
                subtitle: Text(item.note?.isNotEmpty == true
                    ? item.note!
                    : 'Berkas ini belum disetujui. Periksa kembali lalu unggah ulang.'),
                trailing: TextButton(
                  onPressed: () => onFix(item.step),
                  child: const Text('Perbaiki'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  int _documentStep(DocumentType type) => switch (type) {
        DocumentType.registration_request_letter ||
        DocumentType.quality_commitment_statement ||
        DocumentType.bpjs_cooperation_proof ||
        DocumentType.org_structure =>
          3,
        DocumentType.service_sop ||
        DocumentType.clinic_photo ||
        DocumentType.educational_poster =>
          4,
        _ => 1,
      };
}

class _RejectedItem {
  const _RejectedItem({
    required this.title,
    required this.note,
    required this.step,
  });

  final String title;
  final String? note;
  final int step;
}
