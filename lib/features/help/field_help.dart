import 'package:flutter/material.dart';

import '../../core/theme/context_ext.dart';
import 'help_content.dart';

class FieldHelp extends StatelessWidget {
  const FieldHelp({super.key, required this.contentId});

  final String contentId;

  @override
  Widget build(BuildContext context) {
    final content = clinicHelpContent[contentId];
    if (content == null) return const SizedBox.shrink();
    return TextButton.icon(
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Bantuan: ${content.title}', style: context.sH2),
                  const SizedBox(height: 16),
                  _HelpSection(title: 'Apa ini?', body: content.what),
                  _HelpSection(
                      title: 'Contoh pengisian', body: content.example),
                  _HelpSection(
                      title: 'Di mana mencarinya?', body: content.where),
                  const SizedBox(height: 8),
                  Text(
                    'Pastikan sesuai ketentuan yang berlaku untuk klinik Anda.',
                    style: context.sSmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      icon: const Icon(Icons.help_outline, size: 18),
      label: const Text('Apa ini?'),
    );
  }
}

class _HelpSection extends StatelessWidget {
  const _HelpSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: context.sStrong),
            const SizedBox(height: 4),
            Text(body, style: context.sBody),
          ],
        ),
      );
}
