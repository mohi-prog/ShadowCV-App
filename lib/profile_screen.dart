import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shadowcv/home_screen.dart';
import 'package:shadowcv/loginScreen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? userData;
  bool isLoading = true;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // Backend: Fetch User Data from Firestore
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
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error fetching profile data: $e");
      setState(() => isLoading = false);
    }
  }

  // Backend: Logout Logic
  Future<void> _signOut() async {
    // Optional: Show Confirmation Dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Sign Out',
          style: TextStyle(color: Colors.white, fontFamily: 'Boldo'),
        ),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: Colors.white70, fontFamily: 'Boldo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54, fontFamily: 'Boldo'),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.redAccent, fontFamily: 'Boldo'),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        // Navigate back to Login/Onboarding Screen
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => loginScreen()));
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Same Subtle Background Gradient as HomeScreen
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
                              const SizedBox(height: 32),
                              _buildSubscriptionCard(),
                              const SizedBox(height: 32),
                              const Text(
                                'Account Settings',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  fontFamily: 'Boldo',
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildSettingsTile(
                                icon: Icons.person_outline_rounded,
                                title: 'Personal Information',
                                onTap: () {},
                              ),
                              const SizedBox(height: 12),
                              _buildSettingsTile(
                                icon: Icons.work_outline_rounded,
                                title: 'Edit Career Goals',
                                onTap: () {},
                              ),
                              const SizedBox(height: 12),
                              _buildSettingsTile(
                                icon: Icons.language_rounded,
                                title: 'Language',
                                subtitle: 'English',
                                onTap: () {},
                              ),
                              const SizedBox(height: 32),
                              const Text(
                                'Support & Info',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  fontFamily: 'Boldo',
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildSettingsTile(
                                icon: Icons.help_outline_rounded,
                                title: 'FAQ & Help',
                                onTap: () {},
                              ),
                              const SizedBox(height: 12),
                              _buildSettingsTile(
                                icon: Icons.privacy_tip_outlined,
                                title: 'Privacy & Terms',
                                onTap: () {},
                              ),
                              const SizedBox(height: 32),
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
              MaterialPageRoute(builder: (_) => HomeScreen()),
              (route) => false,
            ),
          ),
          const Expanded(
            child: Text(
              'Profile',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontFamily: 'Boldo',
              ),
            ),
          ),
          const SizedBox(width: 48), // Spacer for symmetry
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final String name = userData?['name'] ?? 'User';
    final String email = currentUser?.email ?? 'No Email';
    final String job = userData?['job'] ?? 'Job Seeker';

    // Generate Initials for Avatar
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
          ),
          child: Center(
            child: Text(
              initials.toUpperCase(),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.deepPurpleAccent,
                fontFamily: 'Boldo',
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontFamily: 'Boldo',
                ),
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

  Widget _buildSubscriptionCard() {
    // Later fetch actual status from Firestore (e.g., userData?['tier'])
    final String currentTier = userData?['tier'] ?? 'Free';
    final bool isFree = currentTier == 'Free';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: isFree
            ? null
            : LinearGradient(
                colors: [
                  Colors.deepPurpleAccent,
                  Colors.deepPurpleAccent.shade700,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
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
                'Current Plan',
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
                  currentTier,
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
                ? 'Ready for the next step?'
                : 'All Premium features unlocked!',
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
                ? 'Unlock AI Optimization and unlimited analyses.'
                : 'You are using ShadowCV with maximum power.',
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
                onPressed: () {
                  // TODO: Navigate to Upgrade Page
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
                child: const Text(
                  'Upgrade Now - from €19.99',
                  style: TextStyle(
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
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
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
        child: const Center(
          child: Text(
            'Sign Out',
            style: TextStyle(
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
