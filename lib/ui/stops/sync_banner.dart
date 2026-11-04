import 'package:flutter/material.dart';

class SyncBanner extends StatelessWidget {
  const SyncBanner({
    super.key,
    required this.pendingCount,
  });

  final int pendingCount;

  String get _label {
    if (pendingCount <= 0) {
      return 'All outcomes synced';
    }

    if (pendingCount == 1) {
      return '1 outcome waiting to sync';
    }

    return '$pendingCount outcomes waiting to sync';
  }

  @override
  Widget build(BuildContext context) {
    final isSynced = pendingCount <= 0;

    final background = isSynced
        ? Colors.green.withValues(alpha: 0.10)
        : Colors.orange.withValues(alpha: 0.12);

    final foreground =
        isSynced ? Colors.green.shade800 : Colors.orange.shade900;

    return Semantics(
      key: const Key('sync-banner'),
      container: true,
      liveRegion: true,
      label: _label,
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: foreground.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSynced
                    ? Icons.cloud_done_outlined
                    : Icons.cloud_upload_outlined,
                color: foreground,
                size: 20,
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  _label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),

              Icon(
                isSynced
                    ? Icons.check_circle_outline
                    : Icons.sync,
                color: foreground,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}