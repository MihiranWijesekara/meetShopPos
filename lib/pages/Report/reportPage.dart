import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Data model ──────────────────────────────────────────────────────────────

class ReportItem {
  const ReportItem({
    required this.name,
    required this.stockKg,
    required this.soldKg,
    required this.income,
    required this.profit,
    this.imageUrl,
  });

  final String name;
  final int stockKg;
  final int soldKg;
  final double income;
  final double profit;
  final String? imageUrl;
}

// ── Sample data ──────────────────────────────────────────────────────────────

const List<ReportItem> _sampleItems = [
  ReportItem(
    name: 'Blueberries',
    stockKg: 1500,
    soldKg: 1320,
    income: 100000,
    profit: 120000,
  ),
  ReportItem(
    name: 'Strawberries',
    stockKg: 350,
    soldKg: 280,
    income: 1920,
    profit: 560,
  ),
  ReportItem(
    name: 'Raspberries',
    stockKg: 300,
    soldKg: 200,
    income: 1960,
    profit: 490,
  ),
  ReportItem(
    name: 'Apples',
    stockKg: 400,
    soldKg: 150,
    income: 1720,
    profit: 430,
  ),
  ReportItem(
    name: 'Blueberries Mix',
    stockKg: 400,
    soldKg: 150,
    income: 1740,
    profit: 435,
  ),
  ReportItem(
    name: 'Mangoes',
    stockKg: 600,
    soldKg: 410,
    income: 2460,
    profit: 820,
  ),
  ReportItem(
    name: 'Peaches',
    stockKg: 250,
    soldKg: 190,
    income: 1140,
    profit: 380,
  ),
];

// ── Helpers ──────────────────────────────────────────────────────────────────

/// Format as "RS 1,234" — no dollar sign, RS prefix, no decimals
String _fmt(double v) {
  final formatted = v
      .toStringAsFixed(0)
      .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
  return 'RS $formatted';
}

class _FruitTheme {
  final Color iconColor;
  final Color bgColor;
  final String emoji;
  const _FruitTheme(this.iconColor, this.bgColor, this.emoji);
}

_FruitTheme _fruitTheme(String name) {
  final n = name.toLowerCase();
  if (n.contains('blue'))
    return const _FruitTheme(Color(0xFF3B6FD4), Color(0xFFDEE8FF), '🫐');
  if (n.contains('straw'))
    return const _FruitTheme(Color(0xFFD63B3B), Color(0xFFFFE4E4), '🍓');
  if (n.contains('rasp'))
    return const _FruitTheme(Color(0xFFC2185B), Color(0xFFFFE0F0), '🍒');
  if (n.contains('apple'))
    return const _FruitTheme(Color(0xFF388E3C), Color(0xFFDFF5E0), '🍎');
  if (n.contains('mango'))
    return const _FruitTheme(Color(0xFFE65100), Color(0xFFFFF3E0), '🥭');
  if (n.contains('peach'))
    return const _FruitTheme(Color(0xFFD84315), Color(0xFFFBE9E7), '🍑');
  return const _FruitTheme(Color(0xFF757575), Color(0xFFF5F5F5), '🌿');
}

// ── Main widget ──────────────────────────────────────────────────────────────

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  double get _totalIncome => _sampleItems.fold(0, (s, i) => s + i.income);
  double get _totalProfit => _sampleItems.fold(0, (s, i) => s + i.profit);

  // ── Month picker ──────────────────────────────────────────────────────────

  void _showMonthPicker() {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final years = [2026, 2027, 2028, 2029, 2030];
    int tempMonth = _selectedMonth;
    int tempYear = _selectedYear;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Month & Year',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              // Year picker
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: years.map((year) {
                    final selected = year == tempYear;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text('$year'),
                        selected: selected,
                        selectedColor: const Color(0xFF3B5BDB),
                        backgroundColor: Colors.grey[200],
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (_) {
                          tempYear = year;
                          setState(() {
                            _selectedYear = year;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              // Month picker
              ...List.generate(months.length, (i) {
                final selected = i + 1 == tempMonth;
                return ListTile(
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: selected
                        ? const Color(0xFF3B5BDB)
                        : const Color(0xFFF0F0F0),
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: selected ? Colors.white : Colors.grey[600],
                      ),
                    ),
                  ),
                  title: Text(
                    months[i],
                    style: TextStyle(
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: selected
                          ? const Color(0xFF3B5BDB)
                          : Colors.black87,
                    ),
                  ),
                  trailing: selected
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF3B5BDB),
                        )
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedMonth = i + 1;
                      _selectedYear = tempYear;
                    });
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF2F4F8);
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Reports',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1D2E),
                        letterSpacing: -0.5,
                      ),
                    ),
                    // Month chip
                    GestureDetector(
                      onTap: _showMonthPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFF3B5BDB),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3B5BDB).withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_month_rounded,
                              color: Color(0xFF3B5BDB),
                              size: 15,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${monthNames[_selectedMonth - 1]} $_selectedYear',
                              style: const TextStyle(
                                color: Color(0xFF3B5BDB),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFF3B5BDB),
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Summary cards ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        label: 'Total Income',
                        amount: _totalIncome,
                        cardColor: const Color(0xFF8FA8E8),
                        icon: Icons.show_chart_rounded,
                        iconColor: const Color(0xFF3B5BDB),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _SummaryCard(
                        label: 'Total Profit',
                        amount: _totalProfit,
                        cardColor: const Color(0xFF6DC8A0),
                        icon: Icons.trending_up_rounded,
                        iconColor: const Color(0xFF1E7A50),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Table ────────────────────────────────────────────────────
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _TableHeader(),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFF0F0F0),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: _sampleItems.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            thickness: 1,
                            indent: 68,
                            color: Color(0xFFF5F5F5),
                          ),
                          itemBuilder: (_, i) =>
                              _ItemRow(item: _sampleItems[i]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Summary Card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.cardColor,
    required this.icon,
    required this.iconColor,
  });

  final String label;
  final double amount;
  final Color cardColor;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1D2E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _fmt(amount),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1D2E),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.35),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Table Header ──────────────────────────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: Color(0xFF9CA3AF),
      letterSpacing: 0.5,
    );
    return Container(
      color: const Color(0xFFF8F9FB),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Row(
        children: const [
          SizedBox(width: 20), // aligns with thumbnail
          Expanded(flex: 4, child: Text('ITEM', style: style)),
          Expanded(
            flex: 4,
            child: Text(
              'STOCK/SOLD',
              style: style,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 4,
            child: Text('INCOME', style: style, textAlign: TextAlign.right),
          ),
          Expanded(
            flex: 4,
            child: Text('PROFIT', style: style, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

// ── Item Row ──────────────────────────────────────────────────────────────────

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});
  final ReportItem item;

  @override
  Widget build(BuildContext context) {
    final theme = _fruitTheme(item.name);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 8),

          // ── Item name ─────────────────────────────────────────────────
          Expanded(
            flex: 5,
            child: Text(
              item.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1D2E),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),

          // ── Stock / Sold ──────────────────────────────────────────────
          Expanded(
            flex: 4,
            child: Text(
              '${item.stockKg}/${item.soldKg}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ),

          // ── Income ───────────────────────────────────────────────────
          Expanded(
            flex: 4,
            child: Text(
              _fmt(item.income),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1D2E),
              ),
            ),
          ),

          // ── Profit ───────────────────────────────────────────────────
          Expanded(
            flex: 4,
            child: Text(
              _fmt(item.profit),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E7A50),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
