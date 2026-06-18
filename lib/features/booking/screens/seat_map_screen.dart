import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shuvmarg_partner_app/core/theme/app_theme.dart';
import 'package:shuvmarg_partner_app/core/routes/app_routes.dart';
import 'package:shuvmarg_partner_app/shared/widgets/app_widgets.dart';

enum _SeatStatus { available, booked, selected }

class _Seat {
  final String id;
  _SeatStatus status;
  _Seat(this.id, this.status);
}

class SeatMapScreen extends StatefulWidget {
  final Map<String, dynamic> tripData;
  const SeatMapScreen({super.key, required this.tripData});

  @override
  State<SeatMapScreen> createState() => _SeatMapScreenState();
}

class _SeatMapScreenState extends State<SeatMapScreen> {
  String? _selectedSeat;

  // Build mock 40-seat layout (2+2 config, 10 rows)
  late final List<List<_Seat?>> _upper; // Upper deck rows
  late final List<List<_Seat?>> _lower; // Lower deck rows

  @override
  void initState() {
    super.initState();
    _upper = _buildDeck('U', 5, [2, 5, 8, 11, 14]); // pre-booked seats
    _lower = _buildDeck('L', 10, [1, 3, 7, 12, 18, 21, 23, 28]);
  }

  List<List<_Seat?>> _buildDeck(String prefix, int rows, List<int> bookedNums) {
    int num = 1;
    return List.generate(rows, (row) {
      // Each row: [left1, left2, null(aisle), right1, right2]
      return List.generate(5, (col) {
        if (col == 2) return null; // aisle
        final seatNum = num++;
        final status = bookedNums.contains(seatNum)
            ? _SeatStatus.booked
            : _SeatStatus.available;
        return _Seat('$prefix$seatNum', status);
      });
    });
  }

  void _selectSeat(String seatId) {
    setState(() {
      // Deselect previous
      for (final deck in [_upper, _lower]) {
        for (final row in deck) {
          for (final seat in row) {
            if (seat != null && seat.status == _SeatStatus.selected) {
              seat.status = _SeatStatus.available;
            }
          }
        }
      }
      // Select new
      for (final deck in [_upper, _lower]) {
        for (final row in deck) {
          for (final seat in row) {
            if (seat != null && seat.id == seatId) {
              seat.status = _SeatStatus.selected;
              _selectedSeat = seatId;
            }
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final operator = widget.tripData['operator'] ?? 'Greenline';
    final busType = widget.tripData['busType'] ?? 'AC';
    final departure = widget.tripData['departure'] ?? '07:00';
    final price = widget.tripData['price'] ?? 850;

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
            Text('Select Seat', style: AppTextStyles.labelLg(AppColors.textPrimary)),
            Text('$operator · $departure · $busType', style: AppTextStyles.bodySmall(AppColors.textSecond)),
          ],
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Seat Map ─────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  children: [
                    // Legend
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _LegendItem(color: const Color(0xFFE1F5EE), borderColor: const Color(0xFF0F6E56), label: 'Available'),
                        const SizedBox(width: AppSpacing.xl),
                        _LegendItem(color: const Color(0xFF1F5D4F), borderColor: const Color(0xFF1F5D4F), label: 'Selected', textColor: Colors.white),
                        const SizedBox(width: AppSpacing.xl),
                        _LegendItem(color: const Color(0xFF1E2A28), borderColor: const Color(0xFF888780), label: 'Booked'),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    // Bus outline
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.bgSurface,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                        border: Border.all(color: AppColors.stroke),
                      ),
                      child: Column(
                        children: [
                          // Driver area
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.airline_seat_recline_normal_rounded, color: AppColors.secondary, size: 22),
                                ),
                              ],
                            ),
                          ),
                          Divider(color: AppColors.stroke, height: 1),

                          // Upper deck label
                          if (_upper.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                              child: Text('UPPER DECK', style: AppTextStyles.labelSm(AppColors.textSecond)),
                            ),
                            ..._upper.asMap().entries.map((entry) => _SeatRow(
                              rowIndex: entry.key + 1,
                              seats: entry.value,
                              onTap: _selectSeat,
                            )),
                            Divider(color: AppColors.stroke, height: 1),
                          ],

                          // Lower deck label
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                            child: Text('LOWER DECK', style: AppTextStyles.labelSm(AppColors.textSecond)),
                          ),
                          ..._lower.asMap().entries.map((entry) => _SeatRow(
                            rowIndex: entry.key + 1,
                            seats: entry.value,
                            onTap: _selectSeat,
                          )),
                          const SizedBox(height: AppSpacing.xl),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Sticky Bottom ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxl,
              ),
              decoration: BoxDecoration(
                color: AppColors.bgBase,
                border: Border(top: BorderSide(color: AppColors.stroke)),
                boxShadow: AppShadows.bottomNav,
              ),
              child: Row(
                children: [
                  if (_selectedSeat != null) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Selected', style: AppTextStyles.bodySmall(AppColors.textSecond)),
                        Text('Seat $_selectedSeat', style: AppTextStyles.labelLg(AppColors.accentLime)),
                      ],
                    ),
                    const SizedBox(width: AppSpacing.xl),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Price', style: AppTextStyles.bodySmall(AppColors.textSecond)),
                        Text('NPR $price', style: AppTextStyles.heading3(AppColors.textPrimary)),
                      ],
                    ),
                    const SizedBox(width: AppSpacing.xl),
                  ],
                  Expanded(
                    child: PrimaryButton(
                      label: 'Continue',
                      onPressed: _selectedSeat != null
                          ? () => context.push(AppRoutes.passengerDetails, extra: {
                                ...widget.tripData,
                                'seatId': _selectedSeat,
                              })
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeatRow extends StatelessWidget {
  final int rowIndex;
  final List<_Seat?> seats;
  final void Function(String) onTap;

  const _SeatRow({required this.rowIndex, required this.seats, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 4),
      child: Row(
        children: [
          // Row number
          SizedBox(
            width: 20,
            child: Text(
              rowIndex.toString(),
              style: AppTextStyles.bodyTiny(AppColors.textSecond),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          ...seats.asMap().entries.map((entry) {
            final seat = entry.value;
            if (seat == null) {
              // Aisle
              return const SizedBox(width: 28);
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _SeatWidget(seat: seat, onTap: () => onTap(seat.id)),
            );
          }),
        ],
      ),
    );
  }
}

class _SeatWidget extends StatelessWidget {
  final _Seat seat;
  final VoidCallback onTap;
  const _SeatWidget({required this.seat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color bg, border;
    Color textColor = AppColors.textSecond;

    switch (seat.status) {
      case _SeatStatus.available:
        bg = const Color(0xFFE1F5EE);
        border = const Color(0xFF0F6E56);
        break;
      case _SeatStatus.selected:
        bg = const Color(0xFF1F5D4F);
        border = const Color(0xFF1F5D4F);
        textColor = Colors.white;
        break;
      case _SeatStatus.booked:
        bg = const Color(0xFF1E2A28);
        border = const Color(0xFF888780);
        break;
    }

    return GestureDetector(
      onTap: seat.status == _SeatStatus.booked ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: border, width: 1.5),
        ),
        child: Center(
          child: Text(
            seat.id.substring(1), // strip prefix
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color, borderColor;
  final String label;
  final Color? textColor;
  const _LegendItem({required this.color, required this.borderColor, required this.label, this.textColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: borderColor, width: 1.5),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.bodyTiny(AppColors.textSecond)),
      ],
    );
  }
}
