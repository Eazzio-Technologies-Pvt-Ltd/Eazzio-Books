import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';
import 'package:mobile_books/features/auth/presentation/providers/auth_provider.dart';
import 'package:mobile_books/core/network/network_client.dart';

import 'package:mobile_books/core/config/plan_limits.dart';

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

List<PlanDetail> get plansList {
  final data = PlanLimitsConfig.data;
  return [
    PlanDetail(
      id: 'free',
      name: 'Free Plan',
      price: (data['free']['price_inr_per_month'] as num).toDouble(),
      description: 'Basic features to get started',
      color: Colors.grey,
      features: const [
        'Basic invoice',
        'Tracking payments',
        '1 user access',
        'Basic customer management',
        'Manual journal entries',
        'Dashboard overview'
      ],
      cta: data['free']['cta_label'] as String? ?? 'Get started for free',
    ),
    PlanDetail(
      id: 'standard',
      name: 'Standard Premium',
      price: (data['standard']['price_inr_per_month'] as num).toDouble(),
      description: 'Advanced features for growing businesses',
      color: AppColors.primaryBlue,
      features: const [
        'Automated payment reminders',
        'Complete inventory',
        'GST tracking reporting',
        'Unlimited invoices & quotes',
        'Customer & vendor management',
        'Sales orders & purchase orders',
        'Delivery challans & credit notes',
        'Bank reconciliation'
      ],
      cta: data['standard']['cta_label'] as String? ?? 'Upgrade to Premium',
    ),
    PlanDetail(
      id: 'professional',
      name: 'Professional',
      price: (data['professional']['price_inr_per_month'] as num).toDouble(),
      description: 'Comprehensive features for established businesses',
      badge: 'Most Popular',
      color: Colors.deepPurple,
      features: const [
        'Advanced workflow automation',
        'Multi-currency support',
        'Custom roles & permissions',
        'Time tracking & timesheets',
        'Reports: P&L, Balance Sheet, Cash Flow',
        'Priority email & chat support'
      ],
      cta: data['professional']['cta_label'] as String? ?? 'Upgrade to Professional',
    ),
    PlanDetail(
      id: 'enterprise',
      name: 'Enterprise',
      price: (data['enterprise']['price_inr_per_month'] as num).toDouble(),
      description: 'Ultimate power and control for large organizations',
      color: Colors.pink,
      features: const [
        'Dedicated account manager',
        'Custom integrations & API',
        'Advanced analytics & reporting',
        'Advanced RBAC & audit logs',
        'Custom fields & workflows',
        'API access & webhooks'
      ],
      cta: data['enterprise']['cta_label'] as String? ?? 'Upgrade to Enterprise',
    ),
  ];
}

class PricingScreen extends ConsumerStatefulWidget {
  const PricingScreen({super.key});

  @override
  ConsumerState<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends ConsumerState<PricingScreen> {
  late final PageController _pageController;
  int _currentPage = 2; // Default to Professional plan (index 2)
  bool _isProcessingPayment = false;
  late final Razorpay _razorpay;
  String? _pendingPlanId;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.85,
      initialPage: _currentPage,
    );
    
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_pendingPlanId == null) return;
    
    setState(() {
      _isProcessingPayment = true;
    });

    try {
      final networkClient = ref.read(networkClientProvider);
      final verifyResponse = await networkClient.post(
        '/subscription/renew',
        data: {
          'plan_id': _pendingPlanId == 'standard' ? 'premium' : _pendingPlanId,
          'razorpay_order_id': response.orderId ?? '',
          'razorpay_payment_id': response.paymentId ?? '',
          'razorpay_signature': response.signature ?? '',
        },
      );

      final verifyData = verifyResponse.data as Map<String, dynamic>;
      if (verifyData['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Subscription successfully updated!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        await ref.read(authNotifierProvider.notifier).refreshProfile();
      } else {
        throw Exception(verifyData['message'] ?? 'Payment verification failed.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification failed: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      setState(() {
        _isProcessingPayment = false;
        _pendingPlanId = null;
      });
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() {
      _isProcessingPayment = false;
      _pendingPlanId = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment Failed: ${response.message ?? "Cancelled"}'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() {
      _isProcessingPayment = false;
      _pendingPlanId = null;
    });
  }

  Future<void> _initiatePayment(PlanDetail plan) async {
    final authState = ref.read(authNotifierProvider);
    if (authState is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to upgrade your subscription.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isProcessingPayment = true;
      _pendingPlanId = plan.id;
    });

    try {
      final networkClient = ref.read(networkClientProvider);
      final response = await networkClient.post(
        '/subscription/create-order',
        data: {'plan_id': plan.id == 'standard' ? 'premium' : plan.id},
      );

      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['order'] != null) {
        final orderId = data['order']['id'] as String;
        final keyId = data['keyId'] as String? ?? '';
        final user = authState.user;

        var options = {
          'key': keyId,
          'amount': plan.price * 100, // in paise
          'name': 'Eazzio Books',
          'order_id': orderId,
          'description': 'Upgrade to ${plan.name}',
          'prefill': {
            'email': user.email,
          },
        };

        _razorpay.open(options);
      } else {
        throw Exception(data['message'] ?? 'Failed to generate payment order.');
      }
    } catch (e) {
      setState(() {
        _isProcessingPayment = false;
        _pendingPlanId = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _restoreSubscription() async {
    setState(() {
      _isProcessingPayment = true;
    });
    await ref.read(authNotifierProvider.notifier).refreshProfile();
    setState(() {
      _isProcessingPayment = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subscription status restored & refreshed.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _contactSupport() async {
    final emailUri = Uri.parse('mailto:support@eazziobooks.com?subject=Subscription Support');
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email client.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authNotifierProvider);

    return ResponsiveScaffold(
      currentRoute: '/pricing',
      appBar: AppBar(
        title: const Text('Subscription & Billing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isProcessingPayment ? null : _restoreSubscription,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Paywall Header Summary Card (when authenticated)
            if (authState is AuthAuthenticated) ...[
              Container(
                margin: const EdgeInsets.all(AppSpacing.m),
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(
                  color: authState.user.subscriptionStatus == 'expired'
                      ? Colors.redAccent.withOpacity(0.12)
                      : Colors.teal.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: authState.user.subscriptionStatus == 'expired'
                        ? Colors.redAccent
                        : Colors.teal,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'CURRENT SUBSCRIPTION',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: authState.user.subscriptionStatus == 'expired'
                                ? Colors.redAccent[700]
                                : Colors.teal[700],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: authState.user.subscriptionStatus == 'expired'
                                ? Colors.redAccent
                                : Colors.teal,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            authState.user.subscriptionStatus.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Plan: ${authState.user.planId.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (authState.user.subscriptionExpiresAt != null) ...[
                      Text(
                        'Expiry Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(authState.user.subscriptionExpiresAt!)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[300] : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Remaining: ${authState.user.remainingTrialDays} Days',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.orangeAccent,
                        ),
                      ),
                    ] else ...[
                      const Text(
                        'Expiry Date: Never',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: _restoreSubscription,
                          icon: const Icon(Icons.restore),
                          label: const Text('Restore'),
                          style: TextButton.styleFrom(
                            foregroundColor: isDark ? Colors.white : AppColors.primaryBlue,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _contactSupport,
                          icon: const Icon(Icons.support_agent),
                          label: const Text('Support'),
                          style: TextButton.styleFrom(
                            foregroundColor: isDark ? Colors.white : AppColors.primaryBlue,
                          ),
                        ),

                      ],
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: AppSpacing.m),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
              child: Column(
                children: [
                  Text(
                    'Choose the Perfect Plan',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Upgrade your account to unlock professional invoicing, multi-user access, bank reconciliation, and business accounting reports.',
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
            if (_isProcessingPayment)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Processing transaction safely...'),
                    ],
                  ),
                ),
              )
            else
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
                                  color: plan.color.withOpacity(0.2),
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
                                    color: const Color(0xFF3DDC97),
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(12),
                                      bottomRight: Radius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    plan.badge!,
                                    style: const TextStyle(
                                      color: Colors.black,
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
                                  child: SingleChildScrollView(
                                    child: Column(
                                      children: plan.features.map((feature) {
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
                                                  feature,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: isDark ? Colors.grey[300] : AppColors.textPrimaryLight,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
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
                                  onPressed: plan.price == 0 ? null : () => _initiatePayment(plan),
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
