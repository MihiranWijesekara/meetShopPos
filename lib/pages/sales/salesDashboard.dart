import 'package:chicken_dilivery/pages/Item/itemPage.dart';
import 'package:chicken_dilivery/pages/Managemnt/rootPage.dart';
import 'package:chicken_dilivery/pages/Managemnt/shopPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


class SalesDashboard extends StatelessWidget {
  const SalesDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = <_DashCardData>[
      _DashCardData(
        title: 'Today Sale',
        subtitle: 'Sales for today',
        icon: Icons.today_outlined,
        color: const Color(0xFF4CAF50),
        gradientColors: [const Color(0xFF4CAF50), const Color(0xFF66BB6A)],
         onTap: () {
          // Navigate to Items page
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ItemPage()),
          );
        },
      ),
      _DashCardData(
        title: 'Weekly Sale',
        subtitle: 'Sales for the week',
        icon: Icons.date_range_outlined,
        color: const Color(0xFF2196F3),
        gradientColors: [const Color(0xFF2196F3), const Color(0xFF42A5F5)],
        onTap: () {
          // Navigate to Shop page
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ShopPage()),
          );
        },
      ),
      _DashCardData(
        title: 'Monthly Sale',
        subtitle: 'Sales for the month',
        icon: Icons.calendar_month_outlined,
        color: const Color(0xFFE91E63),
        gradientColors: [const Color(0xFFE91E63), const Color(0xFFF06292)],
        onTap: () {
          // Navigate to Root page
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const Rootpage()),
          );
        },
      ),
   ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color.fromARGB(255, 26, 11, 167),
                const Color.fromARGB(255, 21, 5, 196),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Row(
                    children: [
                      const SizedBox(width: 40),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ' Sales Dashboard',
                               style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                            ),
                          ],
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
        child: Column(
          children: [
            // Summary Cards Row
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'Today Sales',
                    amount: 'RS 500000',
                    icon: Icons.trending_up,
                    iconColor: const Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SummaryCard(
                    title: 'Yesterday',
                    amount: 'RS 480000',
                    icon: Icons.history,
                    iconColor: const Color(0xFF2196F3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Existing Dashboard Cards
            Expanded(
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  return _DashboardCard(cardData: cards[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String amount;
  final IconData icon;
  final Color iconColor;
  final bool isPercentage;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.iconColor,
    this.isPercentage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: const Color.fromARGB(255, 0, 0, 0),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(
                icon,
                size: 17,
                color: iconColor,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: TextStyle(
              color: isPercentage && amount.startsWith('+') 
                  ? const Color(0xFF4CAF50)
                  : Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: widget.cardData.color.withOpacity(0.3),
              spreadRadius: 0,
              blurRadius: 12,
              offset: const Offset(0, 4),
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
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.cardData.icon,
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    widget.cardData.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.cardData.subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
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