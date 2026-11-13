import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/context_ext.dart';
import '../../../state/app_controller.dart';
import '../state/clinic_controller.dart';
import 'feedback/clinic_feedback_page.dart';
import 'reviews/clinic_reviews_page.dart';

class ReviewsFeedbackPage extends StatefulWidget {
  const ReviewsFeedbackPage({super.key});

  @override
  State<ReviewsFeedbackPage> createState() => _ReviewsFeedbackPageState();
}

class _ReviewsFeedbackPageState extends State<ReviewsFeedbackPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  int _lastRequestedIndex = -1;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(_onTabChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final requestedIndex = context.read<AppController>().reviewsTab;
    if (_lastRequestedIndex != requestedIndex && !_tabs.indexIsChanging) {
      _lastRequestedIndex = requestedIndex;
      _tabs.animateTo(requestedIndex.clamp(0, 1));
    }
  }

  void _onTabChanged() {
    if (_tabs.indexIsChanging) return;
    _lastRequestedIndex = _tabs.index;
    context.read<AppController>().selectReviewsTab(_tabs.index);
  }

  @override
  void dispose() {
    _tabs
      ..removeListener(_onTabChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clinic = context.watch<ClinicController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ulasan & Masukan', style: context.sH2),
        const SizedBox(height: 4),
        Text('Baca ulasan pasien dan masukan privat klinik.',
            style: context.sSmall),
        const SizedBox(height: 16),
        Material(
          color: context.c.surface,
          child: TabBar(
            controller: _tabs,
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Ulasan'),
                    if (clinic.reviewStats.unanswered > 0) ...[
                      const SizedBox(width: 8),
                      _CountBadge(clinic.reviewStats.unanswered),
                    ],
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Masukan Privat'),
                    if (clinic.unreadFeedbackCount > 0) ...[
                      const SizedBox(width: 8),
                      _CountBadge(clinic.unreadFeedbackCount),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: switch (_tabs.index) {
            0 => const ClinicReviewsPage(),
            1 => const ClinicFeedbackPage(),
            _ => const SizedBox.shrink(),
          },
        ),
      ],
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge(this.count);
  final int count;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: context.c.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '$count',
          style: context.sLabel.copyWith(color: Colors.white),
        ),
      );
}
