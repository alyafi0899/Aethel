import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

enum ClinicRealtimeSource {
  encounters,
  queueTickets,
  inbox,
  emergencyAlerts,
  recoveryPoll,
}

class ClinicRealtimeEvent {
  const ClinicRealtimeEvent(this.source);

  final ClinicRealtimeSource source;
}

class ClinicRealtimeService {
  ClinicRealtimeService({
    required this.clinicId,
    required Future<void> Function() poller,
    SupabaseClient? client,
    bool realtimeEnabled = true,
    this.pollInterval = const Duration(seconds: 20),
  })  : _client = client ?? Supabase.instance.client,
        _poller = poller,
        _realtimeEnabled = realtimeEnabled;

  final String clinicId;
  final Duration pollInterval;
  final SupabaseClient _client;
  final Future<void> Function() _poller;
  final bool _realtimeEnabled;
  final StreamController<ClinicRealtimeEvent> _events =
      StreamController<ClinicRealtimeEvent>.broadcast();
  final List<RealtimeChannel> _channels = [];
  Timer? _pollTimer;
  bool _polling = false;
  bool _started = false;
  bool _disposed = false;

  Stream<ClinicRealtimeEvent> get events => _events.stream;

  void start() {
    if (_started || _disposed) return;
    _started = true;
    if (!_realtimeEnabled) {
      _startPolling();
      return;
    }

    _subscribe(
      'encounters',
      ClinicRealtimeSource.encounters,
    );
    _subscribe(
      'queue_tickets',
      ClinicRealtimeSource.queueTickets,
    );
    _subscribe(
      'clinic_inbox',
      ClinicRealtimeSource.inbox,
    );
    _subscribe(
      'emergency_alerts',
      ClinicRealtimeSource.emergencyAlerts,
    );
  }

  void _subscribe(String table, ClinicRealtimeSource source) {
    final channel = _client
        .channel('clinic:$clinicId:$table')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: table,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'clinic_id',
            value: clinicId,
          ),
          callback: (_) => _events.add(ClinicRealtimeEvent(source)),
        )
        .subscribe((status, error) {
      if (status == RealtimeSubscribeStatus.channelError ||
          status == RealtimeSubscribeStatus.timedOut ||
          error != null) {
        _events.addError(
          StateError('Realtime subscription unavailable'),
        );
        _startPolling();
      }
    });
    _channels.add(channel);
  }

  void _startPolling() {
    if (_pollTimer != null || _disposed) return;
    _pollTimer = Timer.periodic(pollInterval, (_) => _poll());
  }

  Future<void> _poll() async {
    if (_polling || _disposed) return;
    _polling = true;
    try {
      await _poller();
      _events.add(
        const ClinicRealtimeEvent(ClinicRealtimeSource.recoveryPoll),
      );
    } catch (error, stackTrace) {
      _events.addError(error, stackTrace);
    } finally {
      _polling = false;
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _pollTimer?.cancel();
    for (final channel in _channels) {
      await _client.removeChannel(channel);
    }
    _channels.clear();
    await _events.close();
  }
}
