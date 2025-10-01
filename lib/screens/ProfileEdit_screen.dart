import 'package:flutter/material.dart';

class ProfileEditScreen extends StatefulWidget {
  static const String routeName = 'ProfileEdit_screen';
  final Map<String, String> profile; // Profile data to be edited
  final bool isOwner; // Flag to indicate if the profile is for an owner

  const ProfileEditScreen({
    Key? key,
    required this.profile,
    required this.isOwner,
  }) : super(key: key);

  @override
  _ProfileEditScreenState createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Debugging the profile data received
    print("Profile data received in ProfileEditScreen: ${widget.profile}");

    _nameController = TextEditingController(text: widget.profile['name']);
    _emailController = TextEditingController(text: widget.profile['email']);
    _phoneController = TextEditingController(text: widget.profile['phone']);
  }

  void _submitProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      final profileId = widget.isOwner
          ? widget.profile['ownerId'] // Owner profile ID
          : widget.profile['userId']; // User profile ID

      if (profileId == null) {
        print('Error: ID is missing');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('ID is missing. Cannot update profile.')),
        );
        return;
      }

      final updatedProfile = {
        widget.isOwner ? 'ownerId' : 'userId': profileId,
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
      };

      try {
        // Simulate network call (replace with actual API request)
        await Future.delayed(
            const Duration(seconds: 2)); // Mock delay for testing

        // Return updated profile data to the previous screen
        Navigator.pop(context, updatedProfile);
      } catch (e) {
        print('Error updating profile: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('An error occurred while updating the profile.')),
        );
      }
    } else {
      print('Form validation failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Profile',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // Name field with validation
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Email field with validation
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Phone field with validation
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: _submitProfile,
                  child: const Text('Save Changes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(200, 50),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
