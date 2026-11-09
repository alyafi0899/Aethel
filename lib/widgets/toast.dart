import 'dart:async';

import 'package:flutter/material.dart';

import '../core/icons.dart';

/// Floating confirmation card (bottom-right). Always sits above dialogs and
/// side panels because it is inserted into the root overlay.
abstract final class Toast {
  static OverlayEntry? _entry;
  static Timer? _timer;

  static void show(BuildContext context, String message) {
    _timer?.cancel();
    _entry?.remove();
    final overlay = Overlay.of(context, rootOverlay: true);
    final entry = OverlayEntry(
      builder: (ctx) => _ToastCard(message: message, onClose: dismiss),
    );
    _entry = entry;
    overlay.insert(entry);
    _timer = Timer(const Duration(milliseconds: 3200), dismiss);
  }

  static void dismiss() {
    _timer?.cancel();
    _entry?.remove();
    _entry = null;
  }
}

class _ToastCard extends StatelessWidget {
  const _ToastCard({required this.message, required this.onClose});

  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Positioned(
      right: 22,
      bottom: 22,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: width - 44 < 430 ? width - 44 : 430,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF142536),
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40142536),
                blurRadius: 30,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFF1E8E64),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  AppIcons.check,
                  size: 15,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Action completed',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      message,
                      style: const TextStyle(
                        color: Color(0xFFB7C6D4),
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: onClose,
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(
                    AppIcons.close,
                    size: 16,
                    color: Color(0xFF8DA2B5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
