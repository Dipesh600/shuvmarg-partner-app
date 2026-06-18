import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shuvmarg_partner_app/core/theme/app_theme.dart';
import 'package:shuvmarg_partner_app/core/routes/app_routes.dart';
import 'package:shuvmarg_partner_app/shared/widgets/app_widgets.dart';

const List<String> _kPopularRoutes = [
  'Ktm → Pkr',
  'Ktm → Brt',
  'Pkr → Ktm',
  'Ktm → Dhrt',
  'Brt → Ktm',
];

const List<String> _kNepalCities = [
  'Kathmandu', 'Pokhara', 'Birgunj', 'Biratnagar', 'Dhangadhi',
  'Butwal', 'Hetauda', 'Bharatpur', 'Janakpur', 'Nepalgunj',
  'Dharan', 'Itahari', 'Gorkha', 'Dhulikhel', 'Narayanghat',
  'Mahendranagar', 'Bhairahawa', 'Lamahi', 'Kohalpur', 'Tulsipur',
];

class RouteSearchScreen extends StatefulWidget {
  const RouteSearchScreen({super.key});

  @override
  State<RouteSearchScreen> createState() => _RouteSearchScreenState();
}

class _RouteSearchScreenState extends State<RouteSearchScreen> {
  String? _from = 'Kathmandu'; // default from agent's area
  String? _to;
  DateTime _date = DateTime.now();
  bool _isSearching = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accentLime,
            onPrimary: AppColors.primaryDark,
            surface: AppColors.bgSurface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _swap() {
    setState(() {
      final tmp = _from;
      _from = _to;
      _to = tmp;
    });
  }

  Future<void> _search() async {
    if (_from == null || _to == null) return;
    setState(() => _isSearching = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() => _isSearching = false);
      context.push(AppRoutes.searchResults, extra: {
        'from': _from,
        'to': _to,
        'date': DateFormat('d MMM y').format(_date),
      });
    }
  }

  Future<String?> _showCityPicker(String title, String? current) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      builder: (_) => _CityPickerSheet(title: title, selected: current),
    );
  }

  bool get _canSearch => _from != null && _to != null && _from != _to;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgBase,
        title: Text('Book a Ticket', style: AppTextStyles.labelLg(AppColors.textPrimary)),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── From/To with Swap ──────────────────────────────────
              Text('Route', style: AppTextStyles.labelSm(AppColors.textSecond)),
              const SizedBox(height: AppSpacing.md),

              Stack(
                alignment: Alignment.centerRight,
                children: [
                  Column(
                    children: [
                      _CityField(
                        icon: Icons.my_location_rounded,
                        label: 'From',
                        value: _from,
                        onTap: () async {
                          final city = await _showCityPicker('From', _from);
                          if (city != null) setState(() => _from = city);
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _CityField(
                        icon: Icons.location_on_rounded,
                        label: 'To',
                        value: _to,
                        onTap: () async {
                          final city = await _showCityPicker('To', _to);
                          if (city != null) setState(() => _to = city);
                        },
                      ),
                    ],
                  ),

                  // Swap button
                  Positioned(
                    right: 0,
                    child: GestureDetector(
                      onTap: _swap,
                      child: Container(
                        width: 40,
                        height: 40,
                        margin: const EdgeInsets.only(right: AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.stroke),
                          boxShadow: AppShadows.card,
                        ),
                        child: const Icon(Icons.swap_vert_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Date ──────────────────────────────────────────────
              Text('Travel date', style: AppTextStyles.labelSm(AppColors.textSecond)),
              const SizedBox(height: AppSpacing.md),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.bgInput,
                    borderRadius: BorderRadius.circular(AppRadius.input),
                    border: Border.all(color: AppColors.stroke),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, color: AppColors.secondary, size: 20),
                      const SizedBox(width: AppSpacing.lg),
                      Text(
                        _isToday(_date)
                            ? 'Today, ${DateFormat('d MMM').format(_date)}'
                            : DateFormat('EEEE, d MMM').format(_date),
                        style: AppTextStyles.bodyLarge(AppColors.textPrimary),
                      ),
                      const Spacer(),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecond),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // ── Search CTA ────────────────────────────────────────
              PrimaryButton(
                label: 'Search Buses',
                onPressed: _canSearch ? _search : null,
                isLoading: _isSearching,
              ),

              const SizedBox(height: AppSpacing.xxl),

              // ── Popular Routes ─────────────────────────────────────
              SectionHeader(title: 'Popular routes'),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _kPopularRoutes.map((r) => _PopularChip(
                  label: r,
                  onTap: () {
                    final parts = r.split(' → ');
                    if (parts.length == 2) {
                      setState(() {
                        _from = _expandCity(parts[0]);
                        _to = _expandCity(parts[1]);
                      });
                    }
                  },
                )).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  String _expandCity(String abbr) {
    const map = {
      'Ktm': 'Kathmandu', 'Pkr': 'Pokhara', 'Brt': 'Birgunj',
      'Dhrt': 'Dhangadhi', 'Bkt': 'Bhaktapur',
    };
    return map[abbr] ?? abbr;
  }
}

class _CityField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;

  const _CityField({required this.icon, required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.bgInput,
          borderRadius: BorderRadius.circular(AppRadius.input),
          border: Border.all(
            color: value != null ? AppColors.primary.withOpacity(0.4) : AppColors.stroke,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: value != null ? AppColors.accentLime : AppColors.secondary, size: 20),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: value != null
                  ? Text(value!, style: AppTextStyles.bodyLarge(AppColors.textPrimary))
                  : Text(label, style: AppTextStyles.bodyLarge(AppColors.textSecond)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PopularChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PopularChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: AppColors.primary.withOpacity(0.30)),
        ),
        child: Text(label, style: AppTextStyles.labelSm(AppColors.secondary)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CITY PICKER BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _CityPickerSheet extends StatefulWidget {
  final String title;
  final String? selected;
  const _CityPickerSheet({required this.title, this.selected});

  @override
  State<_CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<_CityPickerSheet> {
  final _searchCtrl = TextEditingController();
  List<String> _filtered = _kNepalCities;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.toLowerCase();
      setState(() => _filtered = q.isEmpty
          ? _kNepalCities
          : _kNepalCities.where((c) => c.toLowerCase().contains(q)).toList());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: Column(
          children: [
            // Handle
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.stroke,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                children: [
                  Text(widget.title, style: AppTextStyles.heading3(AppColors.textPrimary)),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: _searchCtrl,
                    autofocus: true,
                    style: AppTextStyles.bodyLarge(AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search city...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecond),
                      filled: true,
                      fillColor: AppColors.bgInput,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.input),
                        borderSide: const BorderSide(color: AppColors.stroke),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.input),
                        borderSide: const BorderSide(color: AppColors.stroke),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.input),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                itemCount: _filtered.length,
                separatorBuilder: (_, __) => Divider(color: AppColors.stroke, height: 1),
                itemBuilder: (context, i) {
                  final city = _filtered[i];
                  final isSelected = city == widget.selected;
                  return ListTile(
                    onTap: () => Navigator.pop(context, city),
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    leading: Icon(
                      Icons.location_city_rounded,
                      color: isSelected ? AppColors.accentLime : AppColors.textSecond,
                      size: 20,
                    ),
                    title: Text(
                      city,
                      style: isSelected
                          ? AppTextStyles.labelMed(AppColors.accentLime)
                          : AppTextStyles.bodyLarge(AppColors.textPrimary),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_rounded, color: AppColors.accentLime, size: 18)
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
