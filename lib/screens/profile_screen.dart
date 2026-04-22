import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:shadowcv/screens/home_screen.dart';
import 'package:shadowcv/screens/premium_screen.dart';
import 'package:shadowcv/main.dart';
import 'package:shadowcv/services/translation_service.dart';
import 'edit_profile_screen.dart';
import 'package:shadowcv/services/premium_service.dart';
import 'faq_screen.dart';
import 'privacy_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool _isPremium = false;
  int _analysisCount = 0;
  String? _profileImageBase64;

  final List<String> availableLanguages = ['English', 'Deutsch', 'Español'];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _loadPremiumStatus();
  }

  Future<void> _fetchUserData() async {
    if (currentUser == null) return;
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      if (docSnapshot.exists) {
        setState(() {
          userData = docSnapshot.data();
          isLoading = false;
          _profileImageBase64 = userData?['profileImage'];
          if (userData?['language'] != null) {
            AppTranslation.currentLang = userData!['language'];
          }
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching profile data: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadPremiumStatus() async {
    final premium = await PremiumService.isPremium();
    final count = await PremiumService.getAnalysisCount();
    if (mounted) {
      setState(() {
        _isPremium = premium;
        _analysisCount = count;
      });
    }
  }

  // ==================== IMAGE ====================

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppTranslation.t('Profile Photo'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontFamily: 'Boldo',
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceOption(
                  icon: Icons.camera_alt_rounded,
                  label: AppTranslation.t('Camera'),
                  color: Colors.deepPurpleAccent,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildImageSourceOption(
                  icon: Icons.photo_library_rounded,
                  label: AppTranslation.t('Gallery'),
                  color: Colors.blueAccent,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                if (_profileImageBase64 != null)
                  _buildImageSourceOption(
                    icon: Icons.delete_rounded,
                    label: AppTranslation.t('Remove'),
                    color: Colors.redAccent,
                    onTap: () {
                      Navigator.pop(context);
                      _removeImage();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.white.withOpacity(0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  AppTranslation.t('Cancel'),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Boldo',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3), width: 1.5),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Boldo',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90,
      );
      if (picked == null) return;

      final bytes = await File(picked.path).readAsBytes();

      // Crop Screen öffnen
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _CropScreen(
              imageBytes: bytes,
              onCropped: (croppedBytes) async {
                await _saveProfileImage(croppedBytes);
              },
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Image pick error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error: $e',
                    style: const TextStyle(
                      fontFamily: 'Boldo',
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _saveProfileImage(Uint8List croppedBytes) async {
    try {
      // Komprimieren
      final decoded = img.decodeImage(croppedBytes);
      if (decoded == null) return;
      final resized = img.copyResize(decoded, width: 300, height: 300);
      final compressed = img.encodeJpg(resized, quality: 80);
      final base64String = base64Encode(compressed);

      // In Firestore speichern
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .set({'profileImage': base64String}, SetOptions(merge: true));

      if (mounted) {
        setState(() => _profileImageBase64 = base64String);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Profile photo updated!',
                    style: const TextStyle(
                      fontFamily: 'Boldo',
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.deepPurpleAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      debugPrint('Save image error: $e');
    }
  }

  Future<void> _removeImage() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .set({'profileImage': FieldValue.delete()}, SetOptions(merge: true));
      if (mounted) {
        setState(() => _profileImageBase64 = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.warning_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Profile photo removed!',
                    style: const TextStyle(
                      fontFamily: 'Boldo',
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orangeAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      debugPrint('Remove image error: $e');
    }
  }

  // ==================== LANGUAGE ====================

  void _showLanguagePicker() {
    final currentLang = userData?['language'] ?? 'English';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppTranslation.t('Select Language'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontFamily: 'Boldo',
              ),
            ),
            const SizedBox(height: 16),
            ...availableLanguages.map((lang) {
              final isSelected = lang == currentLang;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.pop(context);
                      _updateLanguage(lang);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.deepPurpleAccent.withOpacity(0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              lang,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.deepPurpleAccent
                                    : Colors.white,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                                fontSize: 15,
                                fontFamily: 'Boldo',
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Colors.deepPurpleAccent,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _updateLanguage(String newLang) async {
    if (currentUser == null) return;
    setState(() {
      AppTranslation.currentLang = newLang;
      if (userData != null) {
        userData = Map<String, dynamic>.from(userData!);
        userData!['language'] = newLang;
      } else {
        userData = {'language': newLang};
      }
    });
    await AppTranslation.setLanguage(newLang);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .set({'language': newLang}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore language error: $e');
    }
  }

  // ==================== AUTH ====================

  Future<void> _signOut() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          AppTranslation.t('Sign Out'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontFamily: 'Boldo',
            fontSize: 18,
          ),
        ),
        content: Text(
          AppTranslation.t('Are you sure you want to sign out?'),
          style: const TextStyle(
            color: Colors.white70,
            fontFamily: 'Boldo',
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              AppTranslation.t('Cancel'),
              style: const TextStyle(
                color: Colors.white38,
                fontFamily: 'Boldo',
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppTranslation.t('Sign Out'),
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w800,
                fontFamily: 'Boldo',
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      PremiumService.clearCache();
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _showDeleteAccountDialog() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          AppTranslation.t('Delete Account'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontFamily: 'Boldo',
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppTranslation.t('This will permanently delete:'),
              style: const TextStyle(
                color: Colors.white70,
                fontFamily: 'Boldo',
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppTranslation.t('• All CV analyses'),
              style: const TextStyle(
                color: Colors.white60,
                fontFamily: 'Boldo',
              ),
            ),
            Text(
              AppTranslation.t('• All chat history'),
              style: const TextStyle(
                color: Colors.white60,
                fontFamily: 'Boldo',
              ),
            ),
            Text(
              AppTranslation.t('• Your account'),
              style: const TextStyle(
                color: Colors.white60,
                fontFamily: 'Boldo',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppTranslation.t('This cannot be undone!'),
              style: const TextStyle(
                color: Colors.redAccent,
                fontFamily: 'Boldo',
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              AppTranslation.t('Cancel'),
              style: const TextStyle(
                color: Colors.white38,
                fontFamily: 'Boldo',
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppTranslation.t('Delete Forever'),
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w800,
                fontFamily: 'Boldo',
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) await _deleteAccount();
  }

  Future<void> _deleteAccount() async {
    try {
      final uid = currentUser!.uid;
      final batch = FirebaseFirestore.instance.batch();
      final cvs = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('cvs')
          .get();
      for (final doc in cvs.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(FirebaseFirestore.instance.collection('users').doc(uid));
      await batch.commit();
      await currentUser!.delete();
      PremiumService.clearCache();
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(
                AppTranslation.t('Security Action Required'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Boldo',
                  fontSize: 18,
                ),
              ),
              content: Text(
                AppTranslation.t(
                  'For security reasons, please log out and log back in before deleting your account.',
                ),
                style: const TextStyle(
                  color: Colors.white70,
                  fontFamily: 'Boldo',
                  fontSize: 14,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    AppTranslation.t('OK'),
                    style: const TextStyle(
                      color: Colors.deepPurpleAccent,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Boldo',
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      } else {
        debugPrint('FirebaseAuth Error: ${e.message}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${AppTranslation.t('Error')}: $e',
                    style: const TextStyle(
                      fontFamily: 'Boldo',
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.8),
                radius: 1.5,
                colors: [
                  Colors.deepPurpleAccent.withOpacity(0.15),
                  Colors.black,
                  Colors.black,
                ],
              ),
            ),
          ),
          SafeArea(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.deepPurpleAccent,
                    ),
                  )
                : Column(
                    children: [
                      _buildAppBar(),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildProfileHeader(),
                              const SizedBox(height: 24),
                              _buildStatsRow(),
                              const SizedBox(height: 24),
                              _buildSubscriptionCard(),
                              const SizedBox(height: 32),
                              Text(
                                AppTranslation.t('Account Settings'),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  fontFamily: 'Boldo',
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildSettingsTile(
                                icon: Icons.person_outline_rounded,
                                title: AppTranslation.t('Personal Information'),
                                onTap: () async {
                                  if (userData != null) {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => EditProfileScreen(
                                          userData: userData!,
                                        ),
                                      ),
                                    );
                                    if (result == true) _fetchUserData();
                                  }
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildSettingsTile(
                                icon: Icons.language_rounded,
                                title: AppTranslation.t('Language'),
                                subtitle: AppTranslation.currentLang,
                                onTap: _showLanguagePicker,
                              ),
                              const SizedBox(height: 12),
                              _buildSettingsTile(
                                icon: Icons.delete_forever_rounded,
                                title: AppTranslation.t('Delete Account'),
                                subtitle: AppTranslation.t(
                                  'Permanently delete all data',
                                ),
                                onTap: _showDeleteAccountDialog,
                                isDanger: true,
                              ),
                              const SizedBox(height: 32),
                              Text(
                                AppTranslation.t('Support & Info'),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  fontFamily: 'Boldo',
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildSettingsTile(
                                icon: Icons.help_outline_rounded,
                                title: AppTranslation.t('FAQ & Help'),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const FaqScreen(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Privacy & Terms
                              _buildSettingsTile(
                                icon: Icons.privacy_tip_outlined,
                                title: AppTranslation.t('Privacy & Terms'),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const PrivacyScreen(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              GestureDetector(
                                onLongPress: () async {
                                  if (_isPremium) {
                                    await PremiumService.disableDevMode();
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              const Icon(
                                                Icons.warning_rounded,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  '🔒 Dev: Premium deaktiviert',
                                                  style: const TextStyle(
                                                    fontFamily: 'Boldo',
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          backgroundColor: Colors.orangeAccent,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                          margin: const EdgeInsets.all(16),
                                        ),
                                      );
                                    }
                                  } else {
                                    await PremiumService.enableDevMode();
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              const Icon(
                                                Icons.check_circle_rounded,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  '🔓 Dev: Premium aktiviert!',
                                                  style: const TextStyle(
                                                    fontFamily: 'Boldo',
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          backgroundColor:
                                              Colors.deepPurpleAccent,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                          margin: const EdgeInsets.all(16),
                                        ),
                                      );
                                    }
                                  }
                                  _fetchUserData();
                                  _loadPremiumStatus();
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    'v1.0.0',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.1),
                                      fontSize: 11,
                                      fontFamily: 'Boldo',
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildLogoutButton(),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ==================== UI COMPONENTS ====================

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            ),
          ),
          Expanded(
            child: Text(
              AppTranslation.t('Profile'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontFamily: 'Boldo',
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final String name = userData?['name'] ?? 'User';
    final String email = currentUser?.email ?? 'No Email';
    final String job =
        userData?['job'] ?? userData?['jobTitle'] ?? 'Job Seeker';

    String initials = "U";
    if (name.isNotEmpty) {
      List<String> nameParts = name.split(" ");
      if (nameParts.length > 1) {
        initials = nameParts[0][0] + nameParts[1][0];
      } else {
        initials = nameParts[0][0];
      }
    }

    return Row(
      children: [
        GestureDetector(
          onTap: _showImageSourceSheet,
          child: Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.deepPurpleAccent.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.deepPurpleAccent.withOpacity(0.5),
                    width: 2,
                  ),
                  image: _profileImageBase64 != null
                      ? DecorationImage(
                          image: MemoryImage(
                            base64Decode(_profileImageBase64!),
                          ),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _profileImageBase64 == null
                    ? Center(
                        child: Text(
                          initials.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.deepPurpleAccent,
                            fontFamily: 'Boldo',
                          ),
                        ),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.deepPurpleAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        fontFamily: 'Boldo',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_isPremium) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'PRO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Boldo',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                job,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.deepPurpleAccent.shade100,
                  fontFamily: 'Boldo',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.5),
                  fontFamily: 'Boldo',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    final int remaining = _isPremium
        ? -1
        : (PremiumService.freeAnalysisLimit - _analysisCount).clamp(
            0,
            PremiumService.freeAnalysisLimit,
          );

    return Row(
      children: [
        _buildStatCard(
          value: '$_analysisCount',
          label: AppTranslation.t('Analyses'),
          icon: Icons.assessment_rounded,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          value: _isPremium ? '∞' : '$remaining',
          label: AppTranslation.t('Remaining'),
          icon: Icons.hourglass_bottom_rounded,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          value: _isPremium
              ? AppTranslation.t('PRO')
              : AppTranslation.t('Free'),
          label: AppTranslation.t('Plan'),
          icon: Icons.workspace_premium_rounded,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.deepPurpleAccent, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                fontFamily: 'Boldo',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 11,
                fontFamily: 'Boldo',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard() {
    final String currentTier = userData?['tier'] ?? 'free';
    final bool isFree = currentTier == 'free' || currentTier == 'Free';

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PremiumScreen()),
        );
        _fetchUserData();
        _loadPremiumStatus();
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: isFree
              ? null
              : LinearGradient(
                  colors: [
                    Colors.deepPurpleAccent,
                    Colors.deepPurpleAccent.shade700,
                  ],
                ),
          color: isFree ? Colors.white.withOpacity(0.03) : null,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isFree ? Colors.white.withOpacity(0.1) : Colors.transparent,
          ),
          boxShadow: isFree
              ? []
              : [
                  BoxShadow(
                    color: Colors.deepPurpleAccent.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppTranslation.t('Current Plan'),
                  style: TextStyle(
                    fontSize: 14,
                    color: isFree ? Colors.white70 : Colors.white,
                    fontFamily: 'Boldo',
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isFree
                        ? Colors.white.withOpacity(0.1)
                        : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isFree ? AppTranslation.t('Free') : currentTier,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontFamily: 'Boldo',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              isFree
                  ? AppTranslation.t('Ready for the next step?')
                  : AppTranslation.t('All Premium features unlocked!'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontFamily: 'Boldo',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFree
                  ? AppTranslation.t(
                      'Unlock AI Optimization and unlimited analyses.',
                    )
                  : AppTranslation.t(
                      'You are using ShadowCV with maximum power.',
                    ),
              style: TextStyle(
                fontSize: 13,
                color: isFree ? Colors.white54 : Colors.white.withOpacity(0.8),
                fontFamily: 'Boldo',
              ),
            ),
            if (isFree) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PremiumScreen()),
                    );
                    _fetchUserData();
                    _loadPremiumStatus();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    AppTranslation.t('Upgrade Now - from €19.99'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Boldo',
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDanger
            ? Colors.redAccent.withOpacity(0.05)
            : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDanger
              ? Colors.redAccent.withOpacity(0.1)
              : Colors.white.withOpacity(0.05),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDanger
                ? Colors.redAccent.withOpacity(0.1)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isDanger ? Colors.redAccent : Colors.white,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isDanger ? Colors.redAccent : Colors.white,
            fontFamily: 'Boldo',
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.5),
                  fontFamily: 'Boldo',
                ),
              )
            : null,
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          color: Colors.white.withOpacity(0.3),
          size: 16,
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return InkWell(
      onTap: _signOut,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
        ),
        child: Center(
          child: Text(
            AppTranslation.t('Sign Out'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.redAccent,
              fontFamily: 'Boldo',
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== CROP SCREEN ====================

class _CropScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final Function(Uint8List) onCropped;

  const _CropScreen({required this.imageBytes, required this.onCropped});

  @override
  State<_CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<_CropScreen> {
  final _cropController = CropController();
  bool _isCropping = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Cancel
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Edit Photo',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        fontFamily: 'Boldo',
                      ),
                    ),
                  ),
                  // Done
                  GestureDetector(
                    onTap: _isCropping
                        ? null
                        : () {
                            setState(() => _isCropping = true);
                            _cropController.crop();
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.deepPurpleAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _isCropping
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Done',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Boldo',
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            // Crop Area
            Expanded(
              child: Crop(
                image: widget.imageBytes,
                controller: _cropController,
                withCircleUi: true,
                onCropped: (croppedBytes) {
                  Navigator.pop(context);
                  widget.onCropped(croppedBytes);
                },
                baseColor: Colors.black,
                maskColor: Colors.black.withValues(alpha: 0.7),
                cornerDotBuilder: (size, edgeAlignment) =>
                    DotControl(color: Colors.deepPurpleAccent),
              ),
            ),

            // Hint Text
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Move and pinch to adjust your photo',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 13,
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
}
