import 'package:flutter/material.dart';

import '../../domain/stop.dart';
import 'stop_tile.dart';
import 'sync_banner.dart';

class TawseelStopsApp extends StatelessWidget {
  const TawseelStopsApp({
    super.key,
    required this.stops,
    required this.pendingCount,
    this.textDirection = TextDirection.ltr,
  });

  final List<Stop> stops;
  final int pendingCount;
  final TextDirection textDirection;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF087E8B),
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'Tawseel stops',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        cardTheme: const CardThemeData(
          margin: EdgeInsets.zero,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: textDirection,
          child: child!,
        );
      },
      home: _StopsHome(
        stops: stops,
        pendingCount: pendingCount,
      ),
    );
  }
}

class _StopsHome extends StatefulWidget {
  const _StopsHome({
    required this.stops,
    required this.pendingCount,
  });

  final List<Stop> stops;
  final int pendingCount;

  @override
  State<_StopsHome> createState() => _StopsHomeState();
}

class _StopsHomeState extends State<_StopsHome> {
  String? _selectedStopId;

  Stop? get _selectedStop {
    if (widget.stops.isEmpty) return null;

    for (final stop in widget.stops) {
      if (stop.id == _selectedStopId) {
        return stop;
      }
    }

    return widget.stops.first;
  }

  void _selectStop(Stop stop) {
    setState(() {
      _selectedStopId = stop.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Today's stops"),
            SizedBox(height: 2),
            Text(
              'Courier route overview',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 16),
            child: Center(
              child: CircleAvatar(
                radius: 18,
                backgroundColor:
                    Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  Icons.local_shipping_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          SyncBanner(
            key: const Key('sync-banner'),
            pendingCount: widget.pendingCount,
          ),

          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 600) {
                  return _buildExpandedLayout();
                }

                return _buildCompactLayout();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactLayout() {
    return KeyedSubtree(
      key: const Key('layout-compact'),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 20),
        children: [
          _SectionHeading(
            title: 'Route stops',
            subtitle: '${widget.stops.length} stops scheduled',
          ),

          ...widget.stops.map(
            (stop) => StopTile(
              key: Key('stop-${stop.id}'),
              stop: stop,
              selected: stop.id == _selectedStop?.id,
              onTap: () => _selectStop(stop),
              onCall: () {},
            ),
          ),

          if (widget.stops.isEmpty)
            const _EmptyStops(),
        ],
      ),
    );
  }

  Widget _buildExpandedLayout() {
    final selected = _selectedStop;

    return KeyedSubtree(
      key: const Key('layout-expanded'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 360,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 20),
              children: [
                _SectionHeading(
                  title: 'Route stops',
                  subtitle: '${widget.stops.length} stops scheduled',
                ),

                ...widget.stops.map(
                  (stop) => StopTile(
                    key: Key('stop-${stop.id}'),
                    stop: stop,
                    selected: stop.id == selected?.id,
                    onTap: () => _selectStop(stop),
                    onCall: () {},
                  ),
                ),

                if (widget.stops.isEmpty)
                  const _EmptyStops(),
              ],
            ),
          ),

          const VerticalDivider(
            width: 1,
            thickness: 1,
          ),

          Expanded(
            child: selected == null
                ? const _EmptyStops()
                : _StopDetail(
                    key: const Key('stop-detail'),
                    stop: selected,
                  ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        18,
        18,
        18,
        10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _StopDetail extends StatelessWidget {
  const _StopDetail({
    super.key,
    required this.stop,
  });

  final Stop stop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final color = switch (stop.status) {
      StopStatus.pending => Colors.orange.shade800,
      StopStatus.delivered => Colors.green.shade700,
      StopStatus.failed => theme.colorScheme.error,
    };

    final status = switch (stop.status) {
      StopStatus.pending => 'Pending',
      StopStatus.delivered => 'Delivered',
      StopStatus.failed => 'Failed',
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STOP DETAILS',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 18),

          Card(
            elevation: 0,
            color: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor:
                        theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.person_outline,
                      color: theme.colorScheme.primary,
                      size: 30,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Text(
                    stop.customerName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      status,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),

                  const SizedBox(height: 26),

                  _DetailItem(
                    icon: Icons.location_on_outlined,
                    title: 'Delivery address',
                    value: stop.address,
                  ),

                  const SizedBox(height: 20),

                  _DetailItem(
                    icon: Icons.phone_outlined,
                    title: 'Phone number',
                    value: stop.phone,
                  ),

                  const SizedBox(height: 20),

                  _DetailItem(
                    icon: Icons.payments_outlined,
                    title: 'Cash on delivery',
                    value:
                        'EGP ${(stop.codPiasters / 100).toStringAsFixed(2)}',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 22,
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyStops extends StatelessWidget {
  const _EmptyStops();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.route_outlined,
              size: 44,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),

            const SizedBox(height: 12),

            Text(
              'No stops available',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}