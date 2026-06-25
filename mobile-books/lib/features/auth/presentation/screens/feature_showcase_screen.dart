import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/core/navigation/router.dart';

class FeatureShowcaseScreen extends ConsumerStatefulWidget {
  const FeatureShowcaseScreen({super.key});

  @override
  ConsumerState<FeatureShowcaseScreen> createState() => _FeatureShowcaseScreenState();
}

class _FeatureShowcaseScreenState extends ConsumerState<FeatureShowcaseScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('has_seen_onboarding', true);
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Header with Wordmark / Logo and Skip Button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.m,
                vertical: AppSpacing.s,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo/Wordmark
                  Image.asset(
                    'assets/images/logo.png',
                    height: 32,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback placeholder in case the logo image is missing
                      return Text(
                        'Eazzio Books',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                      );
                    },
                  ),
                  // Skip button
                  TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: AppColors.primaryBlueDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Page Content (Showcase Slides)
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildHowItWorksPage(),
                  _buildHighlightsPage(),
                ],
              ),
            ),

            // Footer Actions (Indicators and Primary CTA)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Indicators (Page progress dots)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(2, (index) {
                      final isActive = _currentPage == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        height: 8.0,
                        width: isActive ? 24.0 : 8.0,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primaryBlueDark
                              : AppColors.textSecondaryDark.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AppSpacing.m),

                  // Primary CTA Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage == 0) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _completeOnboarding();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlueDark,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                      ),
                      child: Text(
                        _currentPage == 0 ? 'Continue' : 'Get Started',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  Widget _buildHowItWorksPage() {
    final steps = [
      _StepData(
        '1',
        'Record transactions',
        'Create invoices and log expenses as they happen with minimal data entry.',
      ),
      _StepData(
        '2',
        'Reconcile with your bank',
        'Connect your bank feeds to match transactions automatically.',
      ),
      _StepData(
        '3',
        'Review your reports',
        'Generate P&L, Balance Sheet, and tax summaries in one click.',
      ),
      _StepData(
        '4',
        'Close the books',
        'Lock your financial periods securely with full audit trails.',
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.s),
          Text(
            'How it works',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            'Keep your business finances in order in four simple steps.',
            style: TextStyle(
              color: AppColors.textSecondaryDark,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          ...steps.map((step) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.m),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Numbered circular step indicator
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        step.number,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.m),
                    // Step Text Description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            step.description,
                            style: TextStyle(
                              color: AppColors.textSecondaryDark,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildHighlightsPage() {
    final chips = [
      'GST-ready',
      'Automated bank reconciliation',
      'Real-time reports (P&L, Balance Sheet, Cash Flow)',
      'Multi-module (Invoices, Expenses, Banking, Reports)',
    ];

    final stats = [
      _StatData('2.4 Cr+', 'reconciled monthly'),
      _StatData('1,200+', 'invoices generated'),
      _StatData('100%', 'GST ready'),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.s),
          Text(
            'Bookkeeping that reconciles itself',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              height: 1.25,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            'Invoices, expenses, and bank feeds matched automatically in real time.',
            style: TextStyle(
              color: AppColors.textSecondaryDark,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.l),

          // Feature Grid list using custom design cards
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: chips.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.7,
            ),
            itemBuilder: (context, index) {
              return Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: AppColors.borderDark.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getHighlightIcon(index),
                      color: AppColors.primaryBlueDark,
                      size: 20,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        chips[index],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),

          // Trust Stats Row
          const Divider(color: AppColors.borderDark, height: 1),
          const SizedBox(height: AppSpacing.m),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: stats.map((stat) => Expanded(
              child: Column(
                children: [
                  Text(
                    stat.value,
                    style: TextStyle(
                      color: AppColors.primaryBlueDark,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stat.label,
                    style: TextStyle(
                      color: AppColors.textSecondaryDark,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  IconData _getHighlightIcon(int index) {
    switch (index) {
      case 0:
        return Icons.gavel;
      case 1:
        return Icons.sync;
      case 2:
        return Icons.bar_chart;
      case 3:
      default:
        return Icons.dashboard;
    }
  }
}

class _StepData {
  final String number;
  final String title;
  final String description;
  _StepData(this.number, this.title, this.description);
}

class _StatData {
  final String value;
  final String label;
  _StatData(this.value, this.label);
}
