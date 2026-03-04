import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_providers.dart';
import '../../../core/security/auth_exceptions.dart';
import 'auth_icons.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  // Design specific colors
  static const _primaryColor = Color(0xFF003E85);
  static const _primaryDarkColor = Color(0xFF002A5C);
  static const _skyBlueColor = Color(0xFF0EA5E9);
  static const _backgroundDarkColor = Color(0xFF0F1823);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    ref.read(authStateProvider.notifier).signIn(email, password);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.isLoading;
    final error = authState.error;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDarkMode ? _backgroundDarkColor : Colors.white;
    final cardColor = isDarkMode
        ? const Color(0xFF1E293B)
        : Colors.white; // Slate-800 for dark mode card
    final textColor = isDarkMode
        ? Colors.white
        : const Color(0xFF0F172A); // Slate-900
    final subtitleColor = isDarkMode
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B); // Slate-400/500
    final borderColor = isDarkMode
        ? const Color(0xFF475569)
        : const Color(0xFFE2E8F0); // Slate-600/200

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 448,
            ), // max-w-md (approx 448px)
            padding: const EdgeInsets.all(24), // p-6 sm:p-10
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12), // rounded-xl
              boxShadow: isDarkMode
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header / Logo Area
                Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: _primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.sports_tennis,
                        size: 32,
                        color: _primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'CourtCare',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : _primaryColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Facility management made effortless',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Welcome Text
                Text(
                  'Welcome Back',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please enter your details to sign in.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 14, color: subtitleColor),
                ),
                const SizedBox(height: 32),

                // Email Field
                _buildLabel('Email', isDarkMode, textColor),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(color: textColor),
                  decoration: _inputDecoration(
                    hintText: 'Enter your email',
                    isDarkMode: isDarkMode,
                    borderColor: borderColor,
                  ),
                ),
                const SizedBox(height: 20),

                // Password Field
                _buildLabel('Password', isDarkMode, textColor),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _login(),
                  style: TextStyle(color: textColor),
                  decoration: _inputDecoration(
                    hintText: 'Enter your password',
                    isDarkMode: isDarkMode,
                    borderColor: borderColor,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: subtitleColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please contact your administrator for password reset.',
                          ),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Forgot Password?',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _skyBlueColor,
                      ),
                    ),
                  ),
                ),

                // Error Message
                if (error != null) ...[
                  const SizedBox(height: 24),
                  Builder(builder: (context) {
                    Color errorBgColor = Colors.red.withValues(alpha: 0.1);
                    Color errorBorderColor = Colors.red.withValues(alpha: 0.3);
                    Color errorTextColor = Colors.red;

                    if (error is AuthException && error.type == AuthExceptionType.pendingApproval) {
                      errorBgColor = Colors.orange.withValues(alpha: 0.1);
                      errorBorderColor = Colors.orange.withValues(alpha: 0.3);
                      errorTextColor = Colors.orange.shade800;
                    }

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: errorBgColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: errorBorderColor),
                      ),
                      child: Text(
                        error is AuthException ? error.message : error.toString(),
                        style: GoogleFonts.inter(
                          color: errorTextColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }),
                ],

                const SizedBox(height: 24),

                // Sign In Button
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _login,
                    style:
                        ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ).copyWith(
                          backgroundColor: WidgetStateProperty.resolveWith((
                            states,
                          ) {
                            if (states.contains(WidgetState.hovered)) {
                              return _primaryDarkColor;
                            }
                            if (states.contains(WidgetState.disabled)) {
                              return _primaryColor.withValues(alpha: 0.6);
                            }
                            return _primaryColor;
                          }),
                        ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Sign In',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: borderColor)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR CONTINUE WITH',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: subtitleColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: borderColor)),
                  ],
                ),

                const SizedBox(height: 24),

                // Social Buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildSocialButton(
                        context,
                        icon: const FacebookIcon(size: 20),
                        label: 'Facebook',
                        isDarkMode: isDarkMode,
                        borderColor: borderColor,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Facebook login not implemented'),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSocialButton(
                        context,
                        icon: const GoogleIcon(size: 20),
                        label: 'Google',
                        isDarkMode: isDarkMode,
                        borderColor: borderColor,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Google login not implemented'),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Footer
                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: subtitleColor,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        context.go('/signup');
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'S\'inscrire',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _skyBlueColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          '© 2024 CourtCare. Premium Tennis Management.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 12, color: subtitleColor),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, bool isDarkMode, Color textColor) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required bool isDarkMode,
    required Color borderColor,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.inter(
        color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8),
      ),
      filled: true,
      fillColor: isDarkMode
          ? const Color(0xFF334155)
          : Colors.white, // Slate-700 / White
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _primaryColor, width: 2),
      ),
      suffixIcon: suffixIcon,
    );
  }

  Widget _buildSocialButton(
    BuildContext context, {
    required Widget icon,
    required String label,
    required bool isDarkMode,
    required Color borderColor,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style:
          OutlinedButton.styleFrom(
            foregroundColor: isDarkMode
                ? Colors.white
                : const Color(0xFF334155),
            side: BorderSide(color: borderColor),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            backgroundColor: isDarkMode
                ? const Color(0xFF334155)
                : Colors.white,
          ).copyWith(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered)) {
                return isDarkMode
                    ? const Color(0xFF475569)
                    : const Color(0xFFF8FAFC); // Slate-600 / Slate-50
              }
              return isDarkMode ? const Color(0xFF334155) : Colors.white;
            }),
          ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
