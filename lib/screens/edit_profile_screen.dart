import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shadowcv/services/translation_service.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _jobController;
  late TextEditingController _goalController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['name']);
    // Fallback für jobTitle vs job Inkonsistenz
    _jobController = TextEditingController(
      text: widget.userData['jobTitle'] ?? widget.userData['job'],
    );
    _goalController = TextEditingController(text: widget.userData['goal']);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _jobController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // Update in Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name': _nameController.text.trim(),
        'jobTitle': _jobController.text.trim(),
        'goal': _goalController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppTranslation.t('Profile updated successfully')),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // true = reload needed
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppTranslation.t('Error updating profile')}: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          AppTranslation.t('Edit Profile'),
          style: const TextStyle(color: Colors.white, fontFamily: 'Boldo'),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.deepPurpleAccent),
            onPressed: _isLoading ? null : _saveProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(
                controller: _nameController,
                label: AppTranslation.t('Full Name'),
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _jobController,
                label: AppTranslation.t('Job Title'),
                icon: Icons.work_outline,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _goalController,
                label: AppTranslation.t('Career Goal'),
                icon: Icons.flag_outlined,
              ),
              const SizedBox(height: 40),
              if (_isLoading)
                const CircularProgressIndicator(
                  color: Colors.deepPurpleAccent,
                  strokeWidth: 2,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontFamily: 'Boldo'),
      validator: (value) => value!.isEmpty
          ? '${AppTranslation.t('Please enter your')} $label'
          : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
        prefixIcon: Icon(icon, color: Colors.deepPurpleAccent),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.deepPurpleAccent),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
      ),
    );
  }
}
