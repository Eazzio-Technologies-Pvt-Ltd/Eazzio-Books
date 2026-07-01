import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';

class PlanDetail {
  final String id;
  final String name;
  final double price;
  final String description;
  final String? badge;
  final Color color;
  final List<String> features;
  final String cta;

  const PlanDetail({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    this.badge,
    required this.color,
    required this.features,
    required this.cta,
  });
}

const List<PlanDetail> plansList = [
  PlanDetail(
    id: 'free',
    name: 'Free Plan',
    price: 0,
    description: 'Basic features to get started',
    color: Colors.grey,
    features: [
      'Basic invoice',
      'Tracking payments',
      '1 user access',
      'Basic customer management',
      'Manual journal entries',
      'Dashboard overview'
    ],
    cta: 'Get started for free',
  ),
  PlanDetail(
    id: 'premium',
    name: 'Standard Premium',
    price: 749,
    description: 'Advanced features for growing businesses',
    color: AppColors.primaryBlue,
    features: [
      'Automated payment reminders',
      'Complete inventory',
      'GST tracking reporting',
      'Unlimited invoices & quotes',
      'Customer & vendor management',
      'Sales orders & purchase orders',
      'Delivery challans & credit notes',
      'Bank reconciliation'
    ],
    cta: 'Start 14 Days Trial',
  ),
  PlanDetail(
    id: 'professional',
    name: 'Professional',
    price: 1499,
    description: 'Comprehensive features for established businesses',
    badge: 'Most Popular',
    color: Colors.deepPurple,
    features: [
      'Advanced workflow automation',
      'Multi-currency support',
      'Custom roles & permissions',
      'Time tracking & timesheets',
      'Reports: P&L, Balance Sheet, Cash Flow',
      'Priority email & chat support'
    ],
    cta: 'Start 14 Days Trial',
  ),
  PlanDetail(
    id: 'enterprise',
    name: 'Enterprise',
    price: 1999,
    description: 'Ultimate power and control for large organizations',
    color: Colors.pink,
    features: [
      'Dedicated account manager',
      'Custom integrations & API',
      'Advanced analytics & reporting',
      'Advanced RBAC & audit logs',
      'Custom fields & workflows',
      'API access & webhooks'
    ],
    cta: 'Start 14 Days Trial',
  ),
];

class PricingScreen extends ConsumerStatefulWidget {
  const PricingScreen({super.key});

  @override
  ConsumerState<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends ConsumerState<PricingScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentPage = 1; // Default to Standard Premium

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pageController.jumpToPage(_currentPage);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ResponsiveScaffold(
      currentRoute: '/pricing',
      appBar: AppBar(
        title: const Text('Subscription Pricing'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.l),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
              child: Column(
                children: [
                  Text(
                    'Simple Pricing for Every Business',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Choose the perfect Eazzio Books plan to manage your accounting, GST, inventory, invoicing, and business growth.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : AppColors.textSecondaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            SizedBox(
              height: 480,
              child: PageView.builder(
                controller: _pageController,
                itemCount: plansList.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final plan = plansList[index];
                  final isSelected = _currentPage == index;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s,
                      vertical: AppSpacing.s,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? plan.color : (isDark ? Colors.white10 : Colors.grey[300]!),
                        width: isSelected ? 2.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: plan.color.withValues(alpha: 0.2),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              )
                            ]
                          : null,
                    ),
                    child: Stack(
                      children: [
                        if (plan.badge != null)
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                decoration: BoxDecoration(
                                  color: plan.color,
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(12),
                                    bottomRight: Radius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  plan.badge!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.m),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: AppSpacing.m),
                              Text(
                                plan.name.toUpperCase(),
                                style: TextStyle(
                                  color: plan.color,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '₹',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                                    ),
                                  ),
                                  Text(
                                    '${plan.price.toInt()}',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                  if (plan.price > 0)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 14, left: 4),
                                      child: Text(
                                        '/mo',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                plan.description,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: AppSpacing.m),
                              const Divider(),
                              const SizedBox(height: AppSpacing.s),
                              Expanded(
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: plan.features.length,
                                  itemBuilder: (context, fIndex) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.check_circle_outline,
                                            size: 14,
                                            color: plan.color,
                                          ),
                                          const SizedBox(width: AppSpacing.xs),
                                          Expanded(
                                            child: Text(
                                              plan.features[fIndex],
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isDark ? Colors.grey[300] : AppColors.textPrimaryLight,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: AppSpacing.m),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: plan.color,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                onPressed: () {
                                  context.push('/register');
                                },
                                child: Text(
                                  plan.cta,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(plansList.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: _currentPage == index ? plansList[index].color : Colors.grey[400],
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
