import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shuvmarg_partner_app/core/theme/app_theme.dart';
import 'package:shuvmarg_partner_app/core/routes/app_routes.dart';
import 'package:shuvmarg_partner_app/shared/widgets/app_widgets.dart';

// Mock bus data
class _BusResult {
  final String id, operator, busType, departure, arrival, departureCity, arrivalCity;
  final double rating;
  final int seatsLeft;
  final int price;
  final List<String> features;
  final bool soldOut;

  const _BusResult({
    required this.id,
    required this.operator,
    required this.busType,
    required this.departure,
    required this.arrival,
    required this.departureCity,
    required this.arrivalCity,
    required this.rating,
    required this.seatsLeft,
    required this.price,
    this.features = const [],
    this.soldOut = false,
  });
}

const _kMockResults = [
  _BusResult(
    id: 'b1',
    operator: 'Greenline Travels',
    busType: 'AC Deluxe',
    departure: '07:00',
    arrival: '13:00',
    departureCity: 'Ktm',
    arrivalCity: 'Pkr',
    rating: 4.2,
    seatsLeft: 23,
    price: 850,
    features: ['AC', 'WiFi', 'Charging'],
  ),
  _BusResult(
    id: 'b2',
    operator: 'Yeti Travels',
    busType: 'Standard',
    departure: '08:30',
    arrival: '15:30',
    departureCity: 'Ktm',
    arrivalCity: 'Pkr',
    rating: 3.8,
    seatsLeft: 8,
    price: 700,
    features: ['AC'],
  ),
  _BusResult(
    id: 'b3',
    operator: 'Buddha Air',
    busType: 'Super Deluxe',
    departure: '06:00',
    arrival: '11:30',
    departureCity: 'Ktm',
    arrivalCity: 'Pkr',
    rating: 4.6,
    seatsLeft: 0,
    price: 1200,
    features: ['AC', 'WiFi', 'Snacks', 'Charging'],
    soldOut: true,
  ),
  _BusResult(
    id: 'b4',
    operator: 'Himalayan Travels',
    busType: 'Night Coach',
    departure: '20:00',
    arrival: '04:00',
    departureCity: 'Ktm',
    arrivalCity: 'Pkr',
    rating: 4.0,
    seatsLeft: 15,
    price: 950,
    features: ['AC', 'Blanket', 'Charging'],
  ),
];

enum _SortMode { departure, price }

class SearchResultsScreen extends StatefulWidget {
  final String from;
  final String to;
  final String date;

  const SearchResultsScreen({
    super.key,
    required this.from,
    required this.to,
    required this.date,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  bool _loading = true;
  _SortMode _sort = _SortMode.departure;
  List<_BusResult> _results = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      setState(() {
        _results = List.from(_kMockResults);
        _loading = false;
      });
    }
  }

  List<_BusResult> get _sorted {
    final list = List<_BusResult>.from(_results.where((b) => !b.soldOut))
      ..addAll(_results.where((b) => b.soldOut));

    if (_sort == _SortMode.price) {
      list.sort((a, b) => a.price.compareTo(b.price));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgBase,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${widget.from} → ${widget.to}', style: AppTextStyles.labelLg(AppColors.textPrimary)),
            Text(widget.date, style: AppTextStyles.bodySmall(AppColors.textSecond)),
          ],
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Sort chips ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.md),
              child: Row(
                children: [
                  if (!_loading)
                    Text(
                      '${_results.length} buses found',
                      style: AppTextStyles.bodySmall(AppColors.textSecond),
                    ),
                  const Spacer(),
                  _SortChip(
                    label: 'Departure',
                    active: _sort == _SortMode.departure,
                    onTap: () => setState(() => _sort = _SortMode.departure),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _SortChip(
                    label: 'Price',
                    active: _sort == _SortMode.price,
                    onTap: () => setState(() => _sort = _SortMode.price),
                  ),
                ],
              ),
            ),

            // ── Results list ──────────────────────────────────────
            Expanded(
              child: _loading
                  ? _shimmerList()
                  : _results.isEmpty
                      ? _emptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.xl, 0, AppSpacing.xl, 100,
                          ),
                          itemCount: _sorted.length,
                          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                          itemBuilder: (context, i) => _BusCard(
                            bus: _sorted[i],
                            onSelect: () => context.push(AppRoutes.seatMap, extra: {
                              'busId': _sorted[i].id,
                              'operator': _sorted[i].operator,
                              'busType': _sorted[i].busType,
                              'departure': _sorted[i].departure,
                              'price': _sorted[i].price,
                            }),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerList() {
    return Shimmer.fromColors(
      baseColor: AppColors.bgInput,
      highlightColor: AppColors.bgSurface,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.xl),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, __) => const ShimmerBox(height: 160, borderRadius: 20),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.directions_bus_outlined, color: AppColors.textSecond, size: 64),
          const SizedBox(height: AppSpacing.xl),
          Text('No buses found', style: AppTextStyles.heading3(AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Try a different date or route',
            style: AppTextStyles.bodyMed(AppColors.textSecond),
          ),
        ],
      ),
    );
  }
}

class _BusCard extends StatelessWidget {
  final _BusResult bus;
  final VoidCallback onSelect;
  const _BusCard({required this.bus, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.bgInput,
        borderRadius: BorderRadius.circular(AppRadius.card - 4),
        border: Border.all(color: AppColors.stroke),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Operator + type + rating
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bus.operator, style: AppTextStyles.heading3(AppColors.textPrimary)),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 14),
                        const SizedBox(width: 3),
                        Text(bus.rating.toStringAsFixed(1), style: AppTextStyles.bodySmall(AppColors.textSecond)),
                        const SizedBox(width: AppSpacing.sm),
                        Text('·  ${bus.busType}', style: AppTextStyles.bodySmall(AppColors.textSecond)),
                      ],
                    ),
                  ],
                ),
              ),
              if (bus.soldOut)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Text('Sold out', style: AppTextStyles.bodySmall(AppColors.error)),
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Time line
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bus.departure, style: AppTextStyles.heading2(AppColors.textPrimary)),
                  Text(bus.departureCity, style: AppTextStyles.bodySmall(AppColors.textSecond)),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 1,
                        color: AppColors.stroke,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.bgBase,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _duration(bus.departure, bus.arrival),
                          style: AppTextStyles.bodyTiny(AppColors.textSecond),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(bus.arrival, style: AppTextStyles.heading2(AppColors.textPrimary)),
                  Text(bus.arrivalCity, style: AppTextStyles.bodySmall(AppColors.textSecond)),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Seats + price + features
          Row(
            children: [
              Icon(
                bus.seatsLeft <= 5 ? Icons.warning_amber_rounded : Icons.event_seat_outlined,
                color: bus.seatsLeft <= 5 ? AppColors.warning : AppColors.secondary,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                bus.soldOut ? 'No seats' : '${bus.seatsLeft} seats left',
                style: AppTextStyles.bodySmall(
                  bus.seatsLeft <= 5 ? AppColors.warning : AppColors.textSecond,
                ),
              ),
              const Spacer(),
              Text(
                'NPR ${bus.price}',
                style: AppTextStyles.heading3(AppColors.textPrimary),
              ),
            ],
          ),

          // Features
          if (bus.features.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: 6,
              children: bus.features.map((f) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(f, style: AppTextStyles.bodyTiny(AppColors.secondary)),
              )).toList(),
            ),
          ],

          const SizedBox(height: AppSpacing.lg),

          // Select CTA
          if (!bus.soldOut)
            PrimaryButton(
              label: 'Select Seats',
              height: 44,
              onPressed: onSelect,
              color: AppColors.accentLime,
            ),
        ],
      ),
    );
  }

  String _duration(String dep, String arr) {
    try {
      final d = _parse(dep);
      var a = _parse(arr);
      if (a.isBefore(d)) a = a.add(const Duration(hours: 24));
      final mins = a.difference(d).inMinutes;
      final h = mins ~/ 60;
      final m = mins % 60;
      return m == 0 ? '${h}h' : '${h}h ${m}m';
    } catch (_) {
      return '';
    }
  }

  DateTime _parse(String time) {
    final parts = time.split(':');
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _SortChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: active ? AppColors.accentLime.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: active ? AppColors.accentLime.withOpacity(0.5) : AppColors.stroke,
          ),
        ),
        child: Text(
          label,
          style: active
              ? AppTextStyles.labelSm(AppColors.accentLime)
              : AppTextStyles.labelSm(AppColors.textSecond),
        ),
      ),
    );
  }
}
