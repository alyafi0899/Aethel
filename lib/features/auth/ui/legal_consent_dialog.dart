import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/context_ext.dart';
import '../../../widgets/buttons.dart';
import '../../clinic/data/legal_consent_repository.dart';
import '../../clinic/state/clinic_controller.dart';
import '../state/auth_controller.dart';

class LegalConsentDialog extends StatefulWidget {
  const LegalConsentDialog({super.key});

  @override
  State<LegalConsentDialog> createState() => _LegalConsentDialogState();
}

class _LegalConsentDialogState extends State<LegalConsentDialog> {
  bool _agreeTerms = false;
  bool _agreePrivacy = false;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final authCtrl = context.watch<AuthController>();

    return PopScope(
      canPop: false, // Blocking dialog
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.gavel_outlined,
                        color: Colors.blue, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Persetujuan Dokumen Hukum ($kLegalVersion)',
                        style:
                            context.sH2.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade800),
                  ),
                  child: Text(
                    'DRAFT - Wajib ditinjau konsultan hukum sebelum rilis produksi. Mohon baca dan setujui Syarat & Ketentuan serta Kebijakan Privasi versi terbaru untuk melanjutkan.',
                    style:
                        TextStyle(color: Colors.amber.shade900, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 16),

                // Legal Document Preview Box
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: c.border),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SYARAT & KETENTUAN PENGGUNAAN (VERSi $kLegalVersion)',
                            style: context.sBody
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '1. Pengguna wajib mengisikan data klinik yang sah sesuai SIO aktif.\n'
                            '2. Pengguna bertanggung jawab atas kerahasiaan kredensial akun.\n'
                            '3. Pengguna dilarang mempublikasikan data pribadi atau foto pasien tanpa izin sah.\n'
                            '4. Platform berhak menangguhkan akun klinik yang SIO-nya kedaluwarsa.',
                            style: context.sSmall,
                          ),
                          const Divider(height: 24),
                          Text(
                            'KEBIJAKAN PRIVASI DATA (VERSI $kLegalVersion)',
                            style: context.sBody
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '1. Data pribadi sensitif (NIK, NPWP) disimpan dengan proteksi berlapis.\n'
                            '2. Berkas dokumen perizinan disimpan pada storage privat dengan signed URL.\n'
                            '3. Ulasan pasien dikelola tanpa menampilkan identitas pribadi pasien.',
                            style: context.sSmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Checkboxes
                Row(
                  children: [
                    Checkbox(
                      value: _agreeTerms,
                      onChanged: (v) =>
                          setState(() => _agreeTerms = v ?? false),
                    ),
                    Expanded(
                      child: Text(
                        'Saya menyetujui Syarat & Ketentuan Penggunaan (Versi $kLegalVersion)',
                        style: context.sBody.copyWith(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Checkbox(
                      value: _agreePrivacy,
                      onChanged: (v) =>
                          setState(() => _agreePrivacy = v ?? false),
                    ),
                    Expanded(
                      child: Text(
                        'Saya menyetujui Kebijakan Privasi Data (Versi $kLegalVersion)',
                        style: context.sBody.copyWith(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Align(
                  alignment: Alignment.centerRight,
                  child: AppButton(
                    'Setujui & Lanjutkan',
                    icon: Icons.check_circle_outline,
                    kind: BtnKind.primary,
                    loading: _saving,
                    onPressed: (_agreeTerms && _agreePrivacy && !_saving)
                        ? () async {
                            setState(() => _saving = true);
                            final uid = authCtrl.user?.id;
                            if (uid != null) {
                              final nav = Navigator.of(context);
                              final clinicCtrl =
                                  context.read<ClinicController>();
                              final ok =
                                  await clinicCtrl.recordLegalConsents(uid);
                              if (ok && mounted) {
                                nav.pop();
                              }
                            }
                            if (mounted) setState(() => _saving = false);
                          }
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
