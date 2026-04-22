import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shadowcv/screens/loginScreen.dart';
import 'package:shadowcv/services/translation_service.dart'; // <-- IMPORT
import 'kennlernphase.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isChecked = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool isLoading = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void handleSignUp() async {
    setState(() => isLoading = true);
    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty ||
        !isChecked) {
      setState(() => isLoading = false);
      _showErrorSnackBar(
        AppTranslation.t('Please fill in all fields and accept terms'),
      );
      return;
    }
    if (passwordController.text != confirmPasswordController.text) {
      setState(() => isLoading = false);
      _showErrorSnackBar(AppTranslation.t('Passwords do not match'));
      return;
    }
    if (passwordController.text.length < 6) {
      setState(() => isLoading = false);
      _showErrorSnackBar(
        AppTranslation.t('Password must be at least 6 characters'),
      );
      return;
    }

    try {
      await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      setState(() => isLoading = false);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Kennlernphase()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      setState(() => isLoading = false);
      _showErrorSnackBar(
        AppTranslation.t('Email already exists') +
            ' ' +
            AppTranslation.t('Sign up failed'),
      );
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
                textAlign: TextAlign.center,
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
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(35),
                        border: Border.all(
                          color: Colors.deepPurpleAccent.withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurpleAccent.withOpacity(0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/images/NewLogo.png',
                            width: 200,
                            height: 200,
                          ),
                          const SizedBox(height: 20),
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
                                fontSize: 40,
                                fontFamily: 'Boldo',
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurpleAccent.withOpacity(0.3),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppTranslation.t('Create Account'),
                            style: const TextStyle(
                              fontSize: 30,
                              color: Colors.black,
                              fontFamily: 'Boldo',
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppTranslation.t(
                              'Join thousands optimizing their CVs',
                            ),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontFamily: 'Boldo',
                            ),
                          ),
                          const SizedBox(height: 32),
                          _buildModernTextField(
                            controller: emailController,
                            label: AppTranslation.t('Email'),
                            icon: Icons.email_rounded,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 20),
                          _buildModernTextField(
                            controller: passwordController,
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
                          const SizedBox(height: 20),
                          _buildModernTextField(
                            controller: confirmPasswordController,
                            label: AppTranslation.t('Confirm Password'),
                            icon: Icons.lock_rounded,
                            obscureText: obscureConfirmPassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscureConfirmPassword
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                color: Colors.deepPurpleAccent,
                                size: 22,
                              ),
                              onPressed: () => setState(
                                () => obscureConfirmPassword =
                                    !obscureConfirmPassword,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.deepPurpleAccent.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isChecked
                                    ? Colors.deepPurpleAccent
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: isChecked
                                        ? Colors.deepPurpleAccent
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isChecked
                                          ? Colors.deepPurpleAccent
                                          : Colors.grey[300]!,
                                      width: 2,
                                    ),
                                  ),
                                  child: Checkbox(
                                    value: isChecked,
                                    onChanged: (value) =>
                                        setState(() => isChecked = value!),
                                    activeColor: Colors.transparent,
                                    checkColor: Colors.white,
                                    side: BorderSide.none,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    AppTranslation.t(
                                      'I agree to Terms & Conditions',
                                    ),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                      fontFamily: 'Boldo',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          Container(
                            width: double.infinity,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Colors.deepPurpleAccent,
                                  Colors.purpleAccent,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.deepPurpleAccent.withOpacity(
                                    0.5,
                                  ),
                                  blurRadius: 25,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: isLoading ? null : handleSignUp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 26,
                                      height: 26,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          AppTranslation.t('Create Account'),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            color: Colors.white,
                                            fontFamily: 'Boldo',
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const Icon(
                                          Icons.arrow_forward_rounded,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const loginScreen(),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: RichText(
                          text: TextSpan(
                            text: AppTranslation.t('Already have an account? '),
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.white60,
                              fontFamily: 'Boldo',
                              fontWeight: FontWeight.w400,
                            ),
                            children: [
                              TextSpan(
                                text: AppTranslation.t('Log in'),
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.deepPurpleAccent,
                                  fontFamily: 'Boldo',
                                  fontWeight: FontWeight.w800,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.deepPurpleAccent,
                                  decorationThickness: 2,
                                ),
                              ),
                            ],
                          ),
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

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurpleAccent.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        cursorColor: Colors.deepPurpleAccent,
        style: const TextStyle(
          fontSize: 15,
          fontFamily: 'Boldo',
          fontWeight: FontWeight.w600,
          color: Colors.black,
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
            fontWeight: FontWeight.w500,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: Colors.deepPurpleAccent,
              width: 2.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
        ),
      ),
    );
  }
}
