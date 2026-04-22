import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shadowcv/main.dart';
import 'package:shadowcv/services/translation_service.dart'; // <-- IMPORT
import '../services/google_auth_service.dart';
import 'sign_up_screen.dart';
import 'forgot_password_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class loginScreen extends StatefulWidget {
  const loginScreen({super.key});

  @override
  State<loginScreen> createState() => _loginScreenState();
}

class _loginScreenState extends State<loginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  bool obscurePassword = true;
  final EmailController = TextEditingController();
  final PasswordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isLoadingEmail = false;
  bool isLoadingGoogle = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    EmailController.dispose();
    PasswordController.dispose();
    super.dispose();
  }

  void handleEmailLogin() async {
    setState(() => isLoadingEmail = true);

    if (EmailController.text.isEmpty || PasswordController.text.isEmpty) {
      setState(() => isLoadingEmail = false);
      _showErrorSnackBar(AppTranslation.t('Please fill in all fields'));
      return;
    }

    try {
      await _auth.signInWithEmailAndPassword(
        email: EmailController.text.trim(),
        password: PasswordController.text.trim(),
      );

      // --- NEU: Überschreibe die alte Firestore-Sprache mit der neu gewählten! ---
      final user = _auth.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'language': AppTranslation.currentLang,
        }, SetOptions(merge: true));
      }
      // --------------------------------------------------------------------------

      setState(() => isLoadingEmail = false);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      setState(() => isLoadingEmail = false);
      String message = e.code == 'user-not-found'
          ? AppTranslation.t('No account found')
          : e.code == 'wrong-password'
          ? AppTranslation.t('Incorrect password')
          : AppTranslation.t('Login failed');
      _showErrorSnackBar(message);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: Colors.redAccent,
        margin: const EdgeInsets.all(16),
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontFamily: 'Boldo',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.black, Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.deepPurpleAccent.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/images/NewLogo.png',
                            width: 150,
                            height: 150,
                          ),
                          const SizedBox(height: 16),
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                Colors.white,
                                Colors.deepPurpleAccent.shade100,
                              ],
                            ).createShader(bounds),
                            child: const Text(
                              'ShadowCV',
                              style: TextStyle(
                                fontSize: 32,
                                fontFamily: 'Boldo',
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurpleAccent.withOpacity(0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppTranslation.t('Welcome Back'),
                            style: const TextStyle(
                              fontSize: 28,
                              color: Colors.black,
                              fontFamily: 'Boldo',
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppTranslation.t('Sign in to continue'),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontFamily: 'Boldo',
                            ),
                          ),
                          const SizedBox(height: 32),
                          _buildTextField(
                            controller: EmailController,
                            label: AppTranslation.t('Email'),
                            icon: Icons.email_rounded,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: PasswordController,
                            label: AppTranslation.t('Password'),
                            icon: Icons.lock_rounded,
                            obscureText: obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                color: Colors.deepPurpleAccent,
                                size: 22,
                              ),
                              onPressed: () => setState(
                                () => obscurePassword = !obscurePassword,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ForgotPasswordScreen(),
                                ),
                              ),
                              child: Text(
                                AppTranslation.t('Forgot Password?'),
                                style: const TextStyle(
                                  color: Colors.deepPurpleAccent,
                                  fontFamily: 'Boldo',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            height: 58,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Colors.deepPurpleAccent,
                                  Colors.purpleAccent,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.deepPurpleAccent.withOpacity(
                                    0.4,
                                  ),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: isLoadingEmail
                                  ? null
                                  : handleEmailLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: isLoadingEmail
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      AppTranslation.t('Login'),
                                      style: const TextStyle(
                                        fontSize: 17,
                                        color: Colors.white,
                                        fontFamily: 'Boldo',
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.grey[300])),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  AppTranslation.t('or'),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontFamily: 'Boldo',
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: Colors.grey[300])),
                            ],
                          ),
                          const SizedBox(height: 24),
                          InkWell(
                            onTap: isLoadingGoogle
                                ? null
                                : () async {
                                    setState(() => isLoadingGoogle = true);
                                    final user =
                                        await GoogleAuthService.handleGoogleSignIn();

                                    // --- NEU: Sprache auch bei Google-Login überschreiben ---
                                    if (user != null) {
                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(user.uid)
                                          .set({
                                            'language':
                                                AppTranslation.currentLang,
                                          }, SetOptions(merge: true));
                                    }
                                    // --------------------------------------------------------

                                    setState(() => isLoadingGoogle = false);
                                    if (user != null) {
                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const AuthWrapper(),
                                        ),
                                        (route) => false,
                                      );
                                    } else {
                                      _showErrorSnackBar(
                                        AppTranslation.t('Google login failed'),
                                      );
                                    }
                                  },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (isLoadingGoogle)
                                    const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.deepPurpleAccent,
                                            ),
                                      ),
                                    )
                                  else ...[
                                    Image.asset(
                                      'assets/images/google1.png',
                                      width: 24,
                                      height: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      AppTranslation.t('Continue with Google'),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontFamily: 'Boldo',
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignUpScreen(),
                          ),
                        );
                      },
                      child: RichText(
                        text: TextSpan(
                          text: AppTranslation.t("Don't have an account? "),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white60,
                            fontFamily: 'Boldo',
                          ),
                          children: [
                            TextSpan(
                              text: AppTranslation.t('Sign Up'),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.deepPurpleAccent,
                                fontFamily: 'Boldo',
                                fontWeight: FontWeight.w800,
                                decoration: TextDecoration.underline,
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
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      cursorColor: Colors.deepPurpleAccent,
      style: const TextStyle(
        fontSize: 15,
        fontFamily: 'Boldo',
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[50],
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.deepPurpleAccent.withOpacity(0.2),
                Colors.purpleAccent.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.deepPurpleAccent, size: 20),
        ),
        suffixIcon: suffixIcon,
        hintText: label,
        hintStyle: TextStyle(
          color: Colors.grey[400],
          fontSize: 14,
          fontFamily: 'Boldo',
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.deepPurpleAccent,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
    );
  }
}
