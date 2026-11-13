import 'package:flutter/material.dart';

import '../../core/theme/context_ext.dart';
import '../../widgets/common.dart';

class QuickGuidePage extends StatelessWidget {
  const QuickGuidePage({super.key});

  static const _steps = [
    (
      Icons.business_outlined,
      'Isi data klinik',
      'Masukkan nama, alamat, kontak, dan informasi izin klinik.'
    ),
    (
      Icons.medical_services_outlined,
      'Lengkapi layanan',
      'Tambahkan layanan, fasilitas, alat, dan jam buka klinik.'
    ),
    (
      Icons.description_outlined,
      'Siapkan dokumen',
      'Unggah dokumen yang diminta agar tim dapat memeriksanya.'
    ),
    (
      Icons.people_outline,
      'Tambahkan tenaga kesehatan',
      'Isi data tenaga kesehatan dan dokumen pendukung yang diperlukan.'
    ),
    (
      Icons.send_outlined,
      'Kirim untuk ditinjau',
      'Periksa kembali ringkasan, lalu kirim pengajuan klinik Anda.'
    ),
  ];

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Panduan singkat', style: context.sH2),
                const SizedBox(height: 6),
                Text('Lima langkah untuk menyiapkan pendaftaran klinik.',
                    style: context.sSmall),
                const SizedBox(height: 16),
                for (var index = 0; index < _steps.length; index++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Icon(_steps[index].$1),
                        ),
                        title: Text('${index + 1}. ${_steps[index].$2}'),
                        subtitle: Text(_steps[index].$3),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
}
