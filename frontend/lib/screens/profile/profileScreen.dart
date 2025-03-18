import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:healthy_heart/commonComponents/customAppBar.dart';
import 'package:healthy_heart/services/apiDio.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyEmailController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  String? _emergencyRelationship;
  bool _isLoading = false;

  final List<String> _relationships = [
    'Parent',
    'Spouse',
    'Sibling',
    'Child',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _emergencyNameController.dispose();
    _emergencyEmailController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userProfileString = prefs.getString('user_profile');

      if (userProfileString != null) {
        await _fetchProfileFromServer();
      } else {
        // If no profile found, try to fetch from server
        await _fetchProfileFromServer();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading profile: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchProfileFromServer() async {
    var userProfile = await apiDio().getUserProfile(context);
    setState(() {
      _nameController.text = userProfile['profile']['name'] ?? '';
      _emailController.text = userProfile['profile']['email'] ?? '';
      _heightController.text =
          userProfile['profile']['height']?.toString() ?? '';
      _weightController.text =
          userProfile['profile']['weight']?.toString() ?? '';

      // Load emergency contact data
      if (userProfile['emergency_contact'] != null) {
        _emergencyNameController.text =
            userProfile['emergency_contact']['name'] ?? '';
        _emergencyEmailController.text =
            userProfile['emergency_contact']['email'] ?? '';
        _emergencyPhoneController.text =
            userProfile['emergency_contact']['phone'] ?? '';
        _emergencyRelationship =
            userProfile['emergency_contact']['relationship'];
      }
    });
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // Create updated profile data
        final updatedProfile = {
          'profile': {
            'name': _nameController.text,
            'email': _emailController.text,
            'height': double.tryParse(_heightController.text),
            'weight': double.tryParse(_weightController.text),
          },
          'emergency_contact': {
            'name': _emergencyNameController.text,
            'email': _emergencyEmailController.text,
            'phone': _emergencyPhoneController.text,
            'relationship': _emergencyRelationship,
          },
        };

        // Update on server - passing context as the first parameter
        await apiDio().updateUserProfile(context, updatedProfile);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );

        await _fetchProfileFromServer();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Icon(icon, size: 28, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'My Profile', showHomeButton: true),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Personal Information
                      _buildSectionHeader('Personal Information', Icons.person),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: 'Full Name',
                                  prefixIcon: const Icon(Icons.person_outline),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.purple[900]!,
                                    ),
                                  ),
                                ),
                                validator:
                                    (value) =>
                                        value?.isEmpty ?? true
                                            ? 'Please enter your name'
                                            : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.purple[900]!,
                                    ),
                                  ),
                                ),
                                readOnly: true, // Email should not be editable
                                validator: (value) {
                                  if (value?.isEmpty ?? true) {
                                    return 'Please enter your email';
                                  }
                                  if (!RegExp(
                                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                  ).hasMatch(value!)) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Health Information
                      _buildSectionHeader(
                        'Health Information',
                        Icons.monitor_weight,
                      ),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _heightController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'Height (cm)',
                                        prefixIcon: const Icon(Icons.height),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.purple[900]!,
                                          ),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value?.isEmpty ?? true) {
                                          return 'Please enter height';
                                        }
                                        final height = double.tryParse(value!);
                                        if (height == null || height <= 0) {
                                          return 'Invalid height';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _weightController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'Weight (kg)',
                                        prefixIcon: const Icon(
                                          Icons.monitor_weight,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.purple[900]!,
                                          ),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value?.isEmpty ?? true) {
                                          return 'Please enter weight';
                                        }
                                        final weight = double.tryParse(value!);
                                        if (weight == null || weight <= 0) {
                                          return 'Invalid weight';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Emergency Contact
                      _buildSectionHeader('Emergency Contact', Icons.emergency),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _emergencyNameController,
                                decoration: InputDecoration(
                                  labelText: 'Contact Name',
                                  prefixIcon: const Icon(Icons.person_outline),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.purple[900]!,
                                    ),
                                  ),
                                ),
                                validator:
                                    (value) =>
                                        value?.isEmpty ?? true
                                            ? 'Please enter contact name'
                                            : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _emergencyEmailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: 'Contact Email',
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.purple[900]!,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value?.isEmpty ?? true) {
                                    return 'Please enter contact email';
                                  }
                                  if (!RegExp(
                                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                  ).hasMatch(value!)) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _emergencyPhoneController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  labelText: 'Contact Phone',
                                  prefixIcon: const Icon(Icons.phone_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.purple[900]!,
                                    ),
                                  ),
                                ),
                                validator:
                                    (value) =>
                                        value?.isEmpty ?? true
                                            ? 'Please enter contact phone'
                                            : null,
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _emergencyRelationship,
                                decoration: InputDecoration(
                                  labelText: 'Relationship',
                                  prefixIcon: const Icon(Icons.people_outline),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.purple[900]!,
                                    ),
                                  ),
                                ),
                                items:
                                    _relationships.map((String relationship) {
                                      return DropdownMenuItem<String>(
                                        value: relationship,
                                        child: Text(relationship),
                                      );
                                    }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _emergencyRelationship = newValue;
                                  });
                                },
                                validator:
                                    (value) =>
                                        value == null
                                            ? 'Please select relationship'
                                            : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Save Button
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _updateProfile,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.save),
                        label:
                            _isLoading
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : const Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
    );
  }
}
