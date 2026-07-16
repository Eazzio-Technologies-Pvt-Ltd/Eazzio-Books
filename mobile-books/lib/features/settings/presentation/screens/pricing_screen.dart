import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';
import 'package:mobile_books/features/auth/presentation/providers/auth_provider.dart';
import 'package:mobile_books/core/network/network_client.dart';

import 'package:mobile_books/core/config/plan_limits.dart';
import 'package:mobile_books/core/theme/app_icons.dart';
import 'package:mobile_books/features/chatbot/presentation/chatbot_bottom_sheet.dart';

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
      description: 'Everything you need to send your first invoice.',
      color: Colors.grey,
      features: const [
        'Create and send professional invoices in minutes',
        'Track payments as customers pay you',
        'Manage your core customer list',
        'Record manual journal entries for basic bookkeeping',
        'A dashboard overview of where your money stands',
        '1 admin user, so you\'re fully in control from day one',
        'Community support to help you get unstuck'
      ],
      cta: 'Get started for free',
    ),
    PlanDetail(
      id: 'standard',
      name: 'Standard Premium',
      price: (data['standard']['price_inr_per_month'] as num).toDouble(),
      description: 'Payments and forecasting, done right.',
      color: AppColors.primaryBlue,
      features: const [
        'Split a single payment across Cash, UPI, Bank, and Petty Cash — simultaneously',
        'Installment scheduler — auto-generates the full payment plan from one entry',
        'Due installment alerts with WhatsApp and email quick-actions',
        'Full financial reports — P&L, Balance Sheet, Cash Flow, Trial Balance',
        'Projected Income widget — see next month\'s expected receipts, today',
        'Projected Expense widget — know what\'s due before it hits your account',
        'WhatsApp payment reminders — one tap from the notification bell',
        'Dedicated Petty Cash ledger with live dashboard balance',
        'Dedicated Undeposited Funds ledger — nothing slips through',
        'Unlimited invoices, quotes, and sales orders',
        'Full vendor management — purchase orders, bills, vendor credits',
        'Complete inventory tracking with low-stock alerts',
        'Recurring invoices and recurring expenses',
        'Unlimited users with role-based access'
      ],
      cta: 'Upgrade Now',
    ),
    PlanDetail(
      id: 'professional',
      name: 'Professional',
      price: (data['professional']['price_inr_per_month'] as num).toDouble(),
      description: 'Built for the business that has an accountant.',
      color: Colors.deepPurple,
      features: const [
        'Split a single payment across Cash, UPI, Bank, and Petty Cash — simultaneously',
        'Installment scheduler — auto-generates the full payment plan from one entry',
        'Due installment alerts with WhatsApp and email quick-actions',
        'Full financial reports — P&L, Balance Sheet, Cash Flow, Trial Balance',
        'Projected Income widget — see next month\'s expected receipts, today',
        'Bank reconciliation and currency adjustments',
        'Customer and vendor aging reports',
        'Projects and timesheets for time-based work',
        'Custom roles and permissions, plus a dedicated Accountant role',
        'API access & webhooks for custom integrations',
        'Advanced RBAC with full audit logs, custom fields & workflows',
        'Transaction locking & bulk updates',
        'Customer statements (per-customer account ledger)',
        '24/7 priority email and chat support'
      ],
      cta: 'Upgrade Now',
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
  int _currentPage = 1; // Default to Standard Premium plan (index 1)
  bool _isProcessingPayment = false;
  late final Razorpay _razorpay;
  String? _pendingPlanId;
  final Set<String> _expandedPlanIds = {};

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

  Future<void> _openChatbot(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ChatbotBottomSheet(),
    );

    if (result != null && mounted) {
      int targetPage = 1; // default Standard Premium
      if (result == 'free') targetPage = 0;
      if (result == 'standard' || result == 'standard premium') targetPage = 1;
      if (result == 'professional') targetPage = 2;

      _pageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
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
            icon: const Icon(AppIcons.refresh),
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
                      ? Colors.redAccent.withValues(alpha: 0.12)
                      : Colors.teal.withValues(alpha: 0.12),
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
                          icon: const Icon(AppIcons.restore),
                          label: const Text('Restore'),
                          style: TextButton.styleFrom(
                            foregroundColor: isDark ? Colors.white : AppColors.primaryBlue,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _contactSupport,
                          icon: const Icon(AppIcons.support_agent),
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
                  const SizedBox(height: AppSpacing.s),
                  TextButton.icon(
                    onPressed: () => _openChatbot(context),
                    icon: const Icon(AppIcons.support_agent, size: 16, color: AppColors.primaryBlue),
                    label: const Text(
                      'Not sure? Try our Plan Finder Assistant',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
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
                      _expandedPlanIds.clear();
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
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ...plan.features.take(_expandedPlanIds.contains(plan.id) ? plan.features.length : 5).map((feature) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 2),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Icon(
                                                  AppIcons.check_circle_outline,
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
                                        if (plan.features.length > 5) ...[
                                          const SizedBox(height: 4),
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                if (_expandedPlanIds.contains(plan.id)) {
                                                  _expandedPlanIds.remove(plan.id);
                                                } else {
                                                  _expandedPlanIds.add(plan.id);
                                                }
                                              });
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 4),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    _expandedPlanIds.contains(plan.id)
                                                        ? 'Show less features'
                                                        : 'Show more features',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: plan.color,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Icon(
                                                    _expandedPlanIds.contains(plan.id)
                                                        ? AppIcons.arrow_upward
                                                        : AppIcons.keyboard_arrow_down,
                                                    size: 14,
                                                    color: plan.color,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.m),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: plan.color,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
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
            const SizedBox(height: AppSpacing.l),
            
            // Trust Badges Grid (2x2)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTrustItem(Icons.verified_user_outlined, 'Enterprise Security', 'Bank-level', isDark),
                      _buildTrustItem(Icons.cloud_done_outlined, '99.9% Uptime', 'Always online', isDark),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.m),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTrustItem(Icons.swap_horiz_outlined, 'Easy Migration', 'Seamless setup', isDark),
                      _buildTrustItem(Icons.headset_mic_outlined, 'Priority Support', '24/7 help', isDark),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.m),
            
            // Enterprise CTA Banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Need a dedicated account manager, white-glove onboarding, or an SLA?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey[300] : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final emailUri = Uri.parse('mailto:support@eazzio.com?subject=Enterprise Inquiry');
                      if (await canLaunchUrl(emailUri)) {
                        await launchUrl(emailUri);
                      }
                    },
                    child: const Text(
                      'Talk to us →',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Footer note
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.m),
              child: Column(
                children: [
                  Text(
                    'Prices are exclusive of applicable GST.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Questions? ',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                        ),
                      ),
                      InkWell(
                        onTap: () async {
                          final emailUri = Uri.parse('mailto:support@eazzio.com?subject=Pricing Question');
                          if (await canLaunchUrl(emailUri)) {
                            await launchUrl(emailUri);
                          }
                        },
                        child: const Text(
                          'Contact us',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustItem(IconData icon, String title, String desc, bool isDark) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: isDark ? Colors.white70 : AppColors.primaryBlue,
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: isDark ? Colors.white70 : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9.5,
              color: isDark ? Colors.grey[400] : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
