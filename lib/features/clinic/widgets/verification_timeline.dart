import 'package:flutter/material.dart';

import '../../../core/theme/clinic_colors.dart';
import '../../../core/theme/context_ext.dart';
import '../../../core/utils/formatters.dart';
import '../models/clinic_enums.dart';
import '../models/clinic_model.dart';

class VerificationTimeline extends StatelessWidget {
  const VerificationTimeline({super.key, required this.clinic});

  final ClinicModel clinic;

  @override
  Widget build(BuildContext context) {
    final sent = clinic.submittedAt != null;
    final reviewed = clinic.reviewedAt != null;
    final verified = clinic.status == ClinicStatus.verified;
    final rejected = clinic.status == ClinicStatus.rejected;
    final stages = [
      (
        'Pengajuan dikirim',
        sent
            ? AppFormatters.formatDateTime(clinic.submittedAt)
            : 'Belum dikirim',
        sent
      ),
      (
        'Sedang ditinjau',
        reviewed
            ? AppFormatters.formatDateTime(clinic.reviewedAt)
            : 'Menunggu pemeriksaan',
        sent && !verified && !rejected
      ),
      (
        verified
            ? 'Terverifikasi'
            : rejected
                ? 'Perlu diperbaiki'
                : 'Selesai',
        reviewed
            ? AppFormatters.formatDateTime(clinic.reviewedAt)
            : 'Belum selesai',
        verified || rejected
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Linimasa peninjauan', style: context.sH3),
        const SizedBox(height: 8),
        for (var index = 0; index < stages.length; index++)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: Icon(
              stages[index].$3
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: stages[index].$3 ? Colors.green : context.c.muted,
            ),
            title: Text(stages[index].$1),
            subtitle: Text(stages[index].$2),
          ),
        if (rejected && clinic.rejectionReason?.isNotEmpty == true)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.c.soft(Tone.red),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('Catatan peninjau: ${clinic.rejectionReason}'),
          ),
      ],
    );
  }
}
