import 'package:chicken_dilivery/pages/Auth/signIn.dart';
import 'package:chicken_dilivery/pages/Managemnt/managementDashboard.dart';
import 'package:chicken_dilivery/pages/sales/allSalesDashboard.dart';
import 'package:chicken_dilivery/pages/sales/salesDashboard.dart';
import 'package:chicken_dilivery/pages/stock/allStockDashboard.dart';
import 'package:chicken_dilivery/pages/stock/currentStockDisplay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = <_DashCardData>[
      _DashCardData(
        title: 'Sales',
        subtitle: 'View sales',
        icon: Icons.trending_up,
        color: const Color(0xFF2D8B8B),
        gradientColors: [const Color(0xFF2D8B8B), const Color(0xFF1F6363)],
        onTap: () {
          // Navigate to Items page
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SalesDashboard()),
          );
        },
      ),
      _DashCardData(
        title: 'Stock',
        subtitle: 'Inventory',
        icon: Icons.inventory_2_outlined,
        color: const Color(0xFF4A90E2),
        gradientColors: [const Color(0xFF4A90E2), const Color(0xFF357ABD)],
        onTap: () {
          // Navigate to Items page
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const StockDisplay()),
          );
        },
      ),
      _DashCardData(
        title: 'All Sales',
        subtitle: 'History of sales',
        icon: Icons.receipt_long_outlined,
        color: const Color(0xFFA68E6B),
        gradientColors: [const Color(0xFFA68E6B), const Color(0xFF8C7758)],
        onTap: () {
          // Navigate to Items page
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const Allsalesdashboard()),
          );
        },
      ),
      _DashCardData(
        title: 'All Stocks',
        subtitle: 'History of stocks',
        icon: Icons.history,
        color: const Color(0xFFF04579),
        gradientColors: [const Color(0xFFF04579), const Color(0xFFD13262)],
        onTap: () {
          // Navigate to Items page
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const Allstockdashboard()),
          );
        },
      ),

      _DashCardData(
        title: 'Management',
        subtitle: 'Items & Settings',
        icon: Icons.category_outlined,
        color: const Color(0xFF8E9AAF),
        gradientColors: [const Color(0xFF8E9AAF), const Color(0xFF727D91)],
        onTap: () {
          // Navigate to Items page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const Managementdashboard(),
            ),
          );
        },
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        flexibleSpace: Container(
          color: const Color(0xFFF8F9FA),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dashboard',
                            style: TextStyle(
                              color: const Color(0xFF1A1A1A),
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Welcome back!',
                            style: TextStyle(
                              color: const Color(0xFF7D7D7D),
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.logout_outlined,
                            color: Color.fromARGB(255, 239, 7, 7),
                            size: 24,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SigninPage(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: GridView.builder(
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio:
                1.1, // Increased from 0.95 to make cards smaller/shorter
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) {
            return _DashboardCard(cardData: cards[index]);
          },
        ),
      ),
    );
  }
}

class _DashCardData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _DashCardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.gradientColors,
    required this.onTap,
  });
}

class _DashboardCard extends StatefulWidget {
  final _DashCardData cardData;

  const _DashboardCard({required this.cardData});

  @override
  State<_DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<_DashboardCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.cardData.gradientColors,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              _controller.forward().then((_) => _controller.reverse());
              widget.cardData.onTap();
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.cardData.icon,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    widget.cardData.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.cardData.subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
