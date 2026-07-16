import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../core/utils/validators.dart';
import 'package:mobile_books/core/theme/app_icons.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;

  // Brand colors
  static const Color _tealGreen = Color(0xFF0CD693);
  static const Color _tealGreenDark = Color(0xFF0AAF7A);
  static const Color _labelColor = Color(0xFF1A202C);
  static const Color _bodyTextColor = Color(0xFF718096);
  static const Color _borderColor = Color(0xFFCBD5E0);
  static const Color _linkColor = Color(0xFF0CD693);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          rememberMe: _rememberMe,
        );

    if (success) {
      // Navigation handled automatically by GoRouter redirect
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 48),

                  // ── Logo (splash_screen.jpeg) ──
                  Image.asset(
                    'assets/images/splash_screen.jpeg',
                    width: 220,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback text logo if image fails
                      return RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'e',
                              style: GoogleFonts.inter(
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                                fontStyle: FontStyle.italic,
                                color: _tealGreen,
                              ),
                            ),
                            TextSpan(
                              text: 'azzio ',
                              style: GoogleFonts.inter(
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                                fontStyle: FontStyle.italic,
                                color: const Color(0xFF0B1437),
                              ),
                            ),
                            TextSpan(
                              text: 'BOOKS',
                              style: GoogleFonts.inter(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: _tealGreen,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // ── Tagline ──
                  Text(
                    'Accounting Made Simple',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _labelColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage invoices, track expenses,\nand stay GST compliant',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: _bodyTextColor,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── Welcome back heading ──
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Welcome back',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: _labelColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Sign in to your account to continue',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: _bodyTextColor,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Form ──
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Email Address
                        Text(
                          'Email Address',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _labelColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildEmailField(),

                        const SizedBox(height: 18),

                        // Password
                        Text(
                          'Password',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _labelColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildPasswordField(),

                        const SizedBox(height: 14),

                        // Remember me + Forgot password row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Remember me
                            Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    activeColor: _tealGreen,
                                    side: const BorderSide(
                                        color: _borderColor, width: 1.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    onChanged: (value) {
                                      setState(
                                          () => _rememberMe = value ?? false);
                                    },
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => setState(
                                      () => _rememberMe = !_rememberMe),
                                  child: Text(
                                    'Remember me',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      color: _labelColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Forgot password
                            GestureDetector(
                              onTap: () {
                                // TODO: Navigate to forgot password
                              },
                              child: Text(
                                'Forgot password?',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _tealGreen,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Error message
                        if (authState.errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              authState.errorMessage!,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFFEF4444),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 28),

                        // ── Sign In button (Teal Green) ──
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed:
                                authState.isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _tealGreen,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              disabledBackgroundColor:
                                  _tealGreen.withValues(alpha: 0.6),
                              shadowColor: _tealGreen.withValues(alpha: 0.3),
                            ).copyWith(
                              overlayColor: WidgetStateProperty.resolveWith(
                                (states) => states.contains(WidgetState.pressed)
                                    ? _tealGreenDark.withValues(alpha: 0.2)
                                    : null,
                              ),
                            ),
                            child: authState.isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Sign In',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Don't have an account? ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: _bodyTextColor,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                ref
                                    .read(authProvider.notifier)
                                    .clearError();
                                context.push('/register');
                              },
                              child: Text(
                                'Create an account',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _linkColor,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),
                      ],
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

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      validator: AppValidators.validateEmail,
      style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1A202C)),
      decoration: InputDecoration(
        hintText: 'you@example.com',
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: const Color(0xFFA0AEC0),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: _borderColor, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: _tealGreen, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide:
              const BorderSide(color: Color(0xFFEF4444), width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide:
              const BorderSide(color: Color(0xFFEF4444), width: 1.8),
        ),
        errorStyle: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFEF4444)),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      validator: AppValidators.validatePassword,
      style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1A202C)),
      decoration: InputDecoration(
        hintText: 'Enter your password',
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: const Color(0xFFA0AEC0),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: _borderColor, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: _tealGreen, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide:
              const BorderSide(color: Color(0xFFEF4444), width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide:
              const BorderSide(color: Color(0xFFEF4444), width: 1.8),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? AppIcons.visibility_outlined
                : AppIcons.visibility_off_outlined,
            color: const Color(0xFFA0AEC0),
            size: 20,
          ),
          onPressed: () =>
              setState(() => _obscurePassword = !_obscurePassword),
        ),
        errorStyle: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFEF4444)),
      ),
    );
  }
}
