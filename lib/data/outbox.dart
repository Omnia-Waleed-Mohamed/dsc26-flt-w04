import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/delivery_outcome.dart';
import 'local_store.dart';

const String outboxStorageKey = 'tawseel.outbox.v1';

enum EntryStatus { pending, rejected }

final class OutboxEntry {
  const OutboxEntry({
    required this.id,
    required this.outcome,
    this.attempts = 0,
    this.status = EntryStatus.pending,
    this.rejectionReason,
  });

  final String id;
  final DeliveryOutcome outcome;
  final int attempts;
  final EntryStatus status;
  final String? rejectionReason;

  OutboxEntry copyWith({
    DeliveryOutcome? outcome,
    int? attempts,
    EntryStatus? status,
    String? rejectionReason,
  }) {
    return OutboxEntry(
      id: id,
      outcome: outcome ?? this.outcome,
      attempts: attempts ?? this.attempts,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'outcome': outcome.toJson(),
        'attempts': attempts,
        'status': status.name,
        'rejectionReason': rejectionReason,
      };

  factory OutboxEntry.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final outcome = json['outcome'];
    final attempts = json['attempts'];
    final status = json['status'];
    final reason = json['rejectionReason'];

    if (id is! String ||
        outcome is! Map ||
        attempts is! int ||
        status is! String ||
        (reason != null && reason is! String)) {
      throw FormatException('bad outbox entry: $json');
    }

    return OutboxEntry(
      id: id,
      outcome: DeliveryOutcome.fromJson(
        outcome.cast<String, Object?>(),
      ),
      attempts: attempts,
      status: EntryStatus.values.byName(status),
      rejectionReason: reason as String?,
    );
  }

  @override
  String toString() =>
      'OutboxEntry($id, ${outcome.parcelId}, attempts: $attempts, ${status.name})';
}

final class SyncReport {
  const SyncReport({
    required this.sent,
    required this.rejected,
    required this.remaining,
    this.authRequired = false,
    this.retryAfter,
  });

  final int sent;
  final int rejected;
  final int remaining;
  final bool authRequired;
  final Duration? retryAfter;

  @override
  String toString() => 'SyncReport(sent: $sent, rejected: $rejected, '
      'remaining: $remaining, authRequired: $authRequired, '
      'retryAfter: $retryAfter)';
}

/// 5 seconds × 2^(n-1), capped at 300 seconds.
Duration retryDelay(int consecutiveFailures) {
  if (consecutiveFailures < 1) {
    throw ArgumentError.value(
      consecutiveFailures,
      'consecutiveFailures',
      'Must be at least 1.',
    );
  }

  var seconds = 5;

  for (var i = 1; i < consecutiveFailures && seconds < 300; i++) {
    seconds *= 2;

    if (seconds > 300) {
      seconds = 300;
    }
  }

  return Duration(seconds: seconds);
}

class Outbox {
  Outbox({
    required LocalStore store,
    required http.Client client,
    required Uri baseUrl,
    required String Function() newId,
  })  : _store = store,
        _client = client,
        _baseUrl = baseUrl,
        _newId = newId;

  final LocalStore _store;
  final http.Client _client;
  final Uri _baseUrl;
  final String Function() _newId;

  List<OutboxEntry>? _entries;

  Future<void> _lock = Future<void>.value();

  Future<SyncReport>? _syncFuture;

  Future<T> _withLock<T>(Future<T> Function() action) {
    final completer = Completer<T>();

    _lock = _lock.then((_) async {
      try {
        completer.complete(await action());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });

    return completer.future;
  }

  Future<void> _ensureLoaded() async {
    if (_entries != null) return;

    final raw = await _store.read(outboxStorageKey);

    if (raw == null || raw.isEmpty) {
      _entries = <OutboxEntry>[];
      return;
    }

    final decoded = jsonDecode(raw);

    if (decoded is! List) {
      throw const FormatException(
        'Outbox storage must contain a JSON list.',
      );
    }

    _entries = decoded.map((item) {
      if (item is! Map) {
        throw const FormatException('Invalid outbox entry.');
      }

      return OutboxEntry.fromJson(
        item.cast<String, Object?>(),
      );
    }).toList();
  }

  Future<void> _persist() async {
    await _store.write(
      outboxStorageKey,
      jsonEncode(
        _entries!.map((entry) => entry.toJson()).toList(),
      ),
    );
  }

  void _validate(DeliveryOutcome outcome) {
    if (outcome.parcelId.trim().isEmpty) {
      throw ArgumentError.value(
        outcome.parcelId,
        'parcelId',
        'Cannot be empty.',
      );
    }

    if (!outcome.recordedAt.isUtc) {
      throw ArgumentError.value(
        outcome.recordedAt,
        'recordedAt',
        'Must be UTC.',
      );
    }

    switch (outcome.status) {
      case OutcomeStatus.delivered:
        if (outcome.codCollectedPiasters < 0 ||
            outcome.reason != null) {
          throw ArgumentError(
            'Delivered outcome must have non-negative COD and no reason.',
          );
        }
        break;

      case OutcomeStatus.failed:
        if (outcome.reason == null ||
            outcome.codCollectedPiasters != 0) {
          throw ArgumentError(
            'Failed outcome must have a reason and zero COD.',
          );
        }
        break;
    }
  }

  Future<OutboxEntry> record(DeliveryOutcome outcome) async {
    _validate(outcome);

    return _withLock(() async {
      await _ensureLoaded();

      final existingIndex = _entries!.indexWhere(
        (entry) =>
            entry.status == EntryStatus.pending &&
            entry.attempts == 0 &&
            entry.outcome.parcelId == outcome.parcelId,
      );

      late final OutboxEntry entry;

      if (existingIndex != -1) {
        final previous = _entries![existingIndex];

        entry = previous.copyWith(outcome: outcome);

        _entries![existingIndex] = entry;
      } else {
        entry = OutboxEntry(
          id: _newId(),
          outcome: outcome,
        );

        _entries!.add(entry);
      }

      await _persist();

      return entry;
    });
  }

  Future<List<OutboxEntry>> pending() {
    return _withLock(() async {
      await _ensureLoaded();

      return List<OutboxEntry>.unmodifiable(
        _entries!.where(
          (entry) => entry.status == EntryStatus.pending,
        ),
      );
    });
  }

  Future<List<OutboxEntry>> rejected() {
    return _withLock(() async {
      await _ensureLoaded();

      return List<OutboxEntry>.unmodifiable(
        _entries!.where(
          (entry) => entry.status == EntryStatus.rejected,
        ),
      );
    });
  }

  Future<int> pendingCount() {
    return _withLock(() async {
      await _ensureLoaded();

      return _entries!
          .where((entry) => entry.status == EntryStatus.pending)
          .length;
    });
  }

  Uri get _outcomesUri {
    final path = _baseUrl.path.endsWith('/')
        ? _baseUrl.path
        : '${_baseUrl.path}/';

    return _baseUrl.replace(
      path: '${path}v1/outcomes',
      query: null,
      fragment: null,
    );
  }

  Future<SyncReport> sync() {
    final active = _syncFuture;

    if (active != null) {
      return active;
    }

    final run = _runSync();

    _syncFuture = run;

    run.then<void>(
      (_) {
        if (identical(_syncFuture, run)) {
          _syncFuture = null;
        }
      },
      onError: (Object _, StackTrace __) {
        if (identical(_syncFuture, run)) {
          _syncFuture = null;
        }
      },
    );

    return run;
  }

  Future<SyncReport> _runSync() async {
    var sent = 0;
    var rejectedCount = 0;
    var authRequired = false;
    Duration? retryAfter;

    while (true) {
      final entry = await _withLock(() async {
        await _ensureLoaded();

        final index = _entries!.indexWhere(
          (item) => item.status == EntryStatus.pending,
        );

        if (index == -1) return null;

        final updated = _entries![index].copyWith(
          attempts: _entries![index].attempts + 1,
        );

        _entries![index] = updated;

        await _persist();

        return updated;
      });

      if (entry == null) break;

      http.Response response;

      try {
        response = await _client.post(
          _outcomesUri,
          headers: {
            'Content-Type': 'application/json',
            'Idempotency-Key': entry.id,
          },
          body: jsonEncode({
            'id': entry.id,
            ...entry.outcome.toJson(),
          }),
        );
      } on http.ClientException {
        retryAfter = retryDelay(entry.attempts);
        break;
      }

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 409) {
        await _withLock(() async {
          await _ensureLoaded();

          _entries!.removeWhere(
            (item) => item.id == entry.id,
          );

          await _persist();
        });

        sent++;
        continue;
      }

      if (response.statusCode == 400 ||
          response.statusCode == 422) {
        final reason = _rejectionMessage(response);

        await _withLock(() async {
          await _ensureLoaded();

          final index = _entries!.indexWhere(
            (item) => item.id == entry.id,
          );

          if (index != -1) {
            _entries![index] = _entries![index].copyWith(
              status: EntryStatus.rejected,
              rejectionReason: reason,
            );

            await _persist();
          }
        });

        rejectedCount++;
        continue;
      }

      if (response.statusCode == 401) {
        authRequired = true;
        break;
      }

      retryAfter = retryDelay(entry.attempts);
      break;
    }

    final remaining = await pendingCount();

    return SyncReport(
      sent: sent,
      rejected: rejectedCount,
      remaining: remaining,
      authRequired: authRequired,
      retryAfter: retryAfter,
    );
  }

  String _rejectionMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map && decoded['message'] is String) {
        return decoded['message'] as String;
      }
    } catch (_) {
      // Use HTTP fallback for invalid JSON.
    }

    return 'HTTP ${response.statusCode}';
  }
}