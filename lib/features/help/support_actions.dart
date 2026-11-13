import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/env.dart';

bool get hasSupportContact =>
    EnvConfig.supportWhatsApp.replaceAll(RegExp(r'\D'), '').isNotEmpty;

Future<void> openSupportChat(BuildContext context) async {
  final number = EnvConfig.supportWhatsApp.replaceAll(RegExp(r'\D'), '');
  if (number.isEmpty) return;
  final uri = Uri.parse('https://wa.me/$number');
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('WhatsApp belum dapat dibuka. Coba lagi nanti.')),
    );
  }
}
