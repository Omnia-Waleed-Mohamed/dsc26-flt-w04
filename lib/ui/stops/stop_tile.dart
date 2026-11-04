import 'package:flutter/material.dart';

import '../../domain/stop.dart';

class StopTile extends StatelessWidget {
  const StopTile({
    super.key,
    required this.stop,
    required this.onTap,
    required this.onCall,
    this.selected = false,
  });

  final Stop stop;
  final VoidCallback onTap;
  final VoidCallback onCall;
  final bool selected;

  Color _statusColor(BuildContext context) {
    switch (stop.status) {
      case StopStatus.pending:
        return Colors.orange.shade800;
      case StopStatus.delivered:
        return Colors.green.shade700;
      case StopStatus.failed:
        return Theme.of(context).colorScheme.error;
    }
  }

  String get _statusLabel {
    switch (stop.status) {
      case StopStatus.pending:
        return 'Pending';
      case StopStatus.delivered:
        return 'Delivered';
      case StopStatus.failed:
        return 'Failed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(context);

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      elevation: selected ? 2 : 0,
      color: selected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.45)
          : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: selected ? 1.4 : 0.8,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            14,
            14,
            8,
            14,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  top: 5,
                  end: 12,
                ),
                child: Container(
                  key: Key('stop-dot-${stop.id}'),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stop.customerName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      stop.address,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),

                    const SizedBox(height: 9),

                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            _statusLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),

                        if (stop.codPiasters > 0)
                          Text(
                            'COD: EGP ${(stop.codPiasters / 100).toStringAsFixed(2)}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              IconButton(
                key: Key('call-${stop.id}'),
                tooltip: 'Call ${stop.customerName}',
                constraints: const BoxConstraints(
                  minWidth: 48,
                  minHeight: 48,
                ),
                icon: const Icon(Icons.call_outlined),
                color: theme.colorScheme.primary,
                onPressed: onCall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}