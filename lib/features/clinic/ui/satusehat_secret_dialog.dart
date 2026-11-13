import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/clinic_colors.dart';
import '../../../core/theme/context_ext.dart';
import '../../../widgets/buttons.dart';
import '../../../widgets/forms.dart';
import '../../help/field_help.dart';
import '../state/clinic_controller.dart';

class SatusehatSecretDialog extends StatefulWidget {
  const SatusehatSecretDialog({super.key});

  @override
  State<SatusehatSecretDialog> createState() => _SatusehatSecretDialogState();
}

class _SatusehatSecretDialogState extends State<SatusehatSecretDialog> {
  final _formKey = GlobalKey<FormState>();
  final _secretController = TextEditingController();
  bool _obscureText = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _secretController.clear();
    _secretController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final secret = _secretController.text.trim();
    setState(() {
      _saving = true;
      _error = null;
    });

    final controller = context.read<ClinicController>();
    final saved = await controller.saveSatusehatSecret(secret);
    if (!mounted) return;
    if (saved) {
      _secretController.clear();
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _saving = false;
      _error = controller.errorMessage ?? 'Kode API belum berhasil disimpan.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Hubungkan SATUSEHAT', style: context.sH3),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppFormField(
                label: 'Kode API SATUSEHAT',
                hint: 'Masukkan kode API',
                controller: _secretController,
                obscureText: _obscureText,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Kode API wajib diisi.'
                    : null,
                suffixIcon: IconButton(
                  tooltip: _obscureText ? 'Tampilkan kode' : 'Sembunyikan kode',
                  onPressed: () => setState(() => _obscureText = !_obscureText),
                  icon: Icon(
                    _obscureText
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              const FieldHelp(contentId: 'satusehat_api'),
              const SizedBox(height: 12),
              Text(
                'Kode ini disimpan di server dan tidak dapat dilihat kembali. Jangan bagikan kepada siapa pun.',
                style: context.sSmall,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: context.sSmall.copyWith(color: context.c.fg(Tone.red)),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        AppButton(
          'Batal',
          kind: BtnKind.secondary,
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
        ),
        AppButton(
          'Simpan kode',
          icon: Icons.vpn_key_outlined,
          kind: BtnKind.primary,
          loading: _saving,
          onPressed: _saving ? null : _save,
        ),
      ],
    );
  }
}
