import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/context_ext.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../features/auth/state/auth_controller.dart';
import '../../../widgets/common.dart';
import '../../help/quick_guide_page.dart';
import '../../help/support_actions.dart';

class ClinicSettingsPage extends StatelessWidget {
  const ClinicSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>();
    final auth = context.watch<AuthController>();
    final email = auth.user?.email ?? 'Email tidak tersedia';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pengaturan', style: context.sH2),
        const SizedBox(height: 4),
        Text('Atur tampilan, akun, dan bantuan.', style: context.sSmall),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tampilan', style: context.sH3),
                    const SizedBox(height: 8),
                    SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                            value: ThemeMode.system, label: Text('Otomatis')),
                        ButtonSegment(
                            value: ThemeMode.light, label: Text('Terang')),
                        ButtonSegment(
                            value: ThemeMode.dark, label: Text('Gelap')),
                      ],
                      selected: {theme.config.mode},
                      onSelectionChanged: (value) => theme.setMode(value.first),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Akun', style: context.sH3),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.account_circle_outlined),
                      title: const Text('Akun yang sedang digunakan'),
                      subtitle: Text(email),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Keluar dari akun?'),
                            content: const Text(
                                'Anda perlu masuk kembali untuk mengelola klinik.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Batal'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Keluar'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) await auth.signOut();
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Keluar akun'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Syarat & Privasi', style: context.sH3),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Syarat penggunaan'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showDocument(
                          context, 'Syarat penggunaan', 'terms_id.md'),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Kebijakan privasi'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showDocument(
                          context, 'Kebijakan privasi', 'privacy_id.md'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bantuan', style: context.sH3),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.menu_book_outlined),
                      title: const Text('Panduan singkat'),
                      subtitle:
                          const Text('Lihat langkah untuk menyiapkan klinik.'),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const Scaffold(
                            body: SafeArea(child: QuickGuidePage()),
                          ),
                        ),
                      ),
                    ),
                    if (hasSupportContact)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.chat_outlined),
                        title: const Text('Butuh bantuan?'),
                        subtitle: const Text(
                            'Hubungi tim dukungan melalui WhatsApp.'),
                        onTap: () => openSupportChat(context),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showDocument(
      BuildContext context, String title, String asset) async {
    final content = await rootBundle.loadString('assets/legal/$asset');
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(child: SelectableText(content)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}
