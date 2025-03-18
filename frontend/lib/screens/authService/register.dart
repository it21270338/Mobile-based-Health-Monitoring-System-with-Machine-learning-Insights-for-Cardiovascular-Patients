import 'package:flutter/material.dart';
import 'package:healthy_heart/commonComponents/healthAlert.dart';
import 'package:healthy_heart/services/apiDio.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _familyNameController = TextEditingController();
  final _familyEmailController = TextEditingController();
  final _familyPhoneController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String? _selectedRelationship;
  final List<String> _relationships = [
    'Parent',
    'Spouse',
    'Sibling',
    'Child',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _familyNameController.dispose();
    _familyEmailController.dispose();
    _familyPhoneController.dispose();
    _relationshipController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  final _apiDio = apiDio();

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // You'll need to update your apiDio.register method to include height and weight
        final response = await _apiDio.register(
          context: context,
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          emergencyContactName: _familyNameController.text,
          emergencyContactEmail: _familyEmailController.text,
          emergencyContactPhone: _familyPhoneController.text,
          relationship: _selectedRelationship!,
          height: _heightController.text,
          weight: _weightController.text,
        );

        if (response["user_id"] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Registration successful! Please log in."),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to login screen after success
          Navigator.pushReplacementNamed(context, '/login');
        } else {
          throw Exception("Registration failed");
        }
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: ${e.toString()}'),
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
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Icon(icon, size: 28, color: Theme.of(context).primaryColor),
          SizedBox(width: 12),
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
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: Theme.of(context).primaryColor,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.health_and_safety,
                              size: 64,
                              color: Theme.of(context).primaryColor,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Create Account',
                              style: Theme.of(
                                context,
                              ).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Join our healthcare community',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 32),
                      // Personal Information Section
                      _buildSectionHeader('Personal Information', Icons.person),
                      // Example button that triggers the alert
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: 'Full Name',
                                  prefixIcon: Icon(Icons.person_outline),
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
                              SizedBox(height: 16),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email_outlined),
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
                              SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                    onPressed:
                                        () => setState(
                                          () =>
                                              _obscurePassword =
                                                  !_obscurePassword,
                                        ),
                                  ),
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
                                        value!.length < 6
                                            ? 'Password must be at least 6 characters'
                                            : null,
                              ),
                              SizedBox(height: 16),
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                decoration: InputDecoration(
                                  labelText: 'Confirm Password',
                                  prefixIcon: Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                    onPressed:
                                        () => setState(
                                          () =>
                                              _obscureConfirmPassword =
                                                  !_obscureConfirmPassword,
                                        ),
                                  ),
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
                                        value != _passwordController.text
                                            ? 'Passwords do not match'
                                            : null,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Health Information Section
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
                          padding: EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _heightController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'Height',
                                        prefixIcon: Icon(Icons.height),
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
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _weightController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'Weight',
                                        prefixIcon: Icon(Icons.monitor_weight),
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

                      // Emergency Contact Section
                      _buildSectionHeader('Emergency Contact', Icons.emergency),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _familyNameController,
                                decoration: InputDecoration(
                                  labelText: 'Contact Name',
                                  prefixIcon: Icon(Icons.person_outline),
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
                              SizedBox(height: 16),
                              TextFormField(
                                controller: _familyEmailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: 'Contact Email',
                                  prefixIcon: Icon(Icons.email_outlined),
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
                              SizedBox(height: 16),
                              TextFormField(
                                controller: _familyPhoneController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  labelText: 'Contact Phone',
                                  prefixIcon: Icon(Icons.phone_outlined),
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
                              SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _selectedRelationship,
                                decoration: InputDecoration(
                                  labelText: 'Relationship',
                                  prefixIcon: Icon(Icons.people_outline),
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
                                    _selectedRelationship = newValue;
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
                      SizedBox(height: 32),

                      // Register Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child:
                            _isLoading
                                ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : Text(
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                      SizedBox(height: 16),

                      // Login Link
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Already have an account? Login',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
