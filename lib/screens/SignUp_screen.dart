import 'package:app/screens/CarWash_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart'; // Import for TextInputFormatter

class SignupScreen extends StatefulWidget {
  static const String routeName = 'signup_screen';
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  String? name;
  String? phone;
  String? email;
  String? password;
  String? userType = 'user'; // Default user type

  Future<void> signUp() async {
    if (name == null ||
        name!.isEmpty ||
        phone == null ||
        phone!.length != 10 ||
        email == null ||
        email!.isEmpty ||
        password == null ||
        password!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all required fields.')),
      );
      return;
    }

    String url = 'http://10.0.2.2/myapp/api/signup.php';
    try {
      final response = await http.post(
        Uri.parse(url),
        body: {
          'name': name ?? '',
          'phone': phone ?? '',
          'email': email ?? '',
          'password': password ?? '',
          'user_type': userType ?? '',
        },
      );

      print('Response body: ${response.body}'); // Debugging line
      print('Response status code: ${response.statusCode}'); // Debugging line

      final responseData = json.decode(response.body); // Attempt to parse JSON

      if (responseData['success'] == true) {
        if (userType == 'owner') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CarWashScreen(
                ownerId: responseData['owner_id'].toString(),
                initialCarWashInfo: {
                  'name': '',
                  'location': '',
                  'phone': '',
                  'email': '',
                  'profileImage': '',
                },
                initialImages: [],
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Registration successful!')),
          );
          Navigator.pop(context);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'])),
        );
      }
    } catch (e) {
      print('Error: $e'); // Print the exception
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing up. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign up'),
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Name Field
            TextField(
              onChanged: (value) {
                name = value;
              },
              decoration: InputDecoration(
                hintText: 'Enter Your Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            // Phone Field with Input Formatter
            TextField(
              onChanged: (value) {
                phone = value;
              },
              decoration: InputDecoration(
                hintText: 'Enter Your Phone',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone, // Numeric keyboard
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly, // Allow only digits
                LengthLimitingTextInputFormatter(10), // Limit to 10 digits
              ],
            ),
            const SizedBox(height: 15),
            // Email Field
            TextField(
              onChanged: (value) {
                email = value;
              },
              decoration: InputDecoration(
                hintText: 'Enter Your Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 15),
            // Password Field
            TextField(
              obscureText: true,
              onChanged: (value) {
                password = value;
              },
              decoration: InputDecoration(
                hintText: 'Enter Your Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            // User Type Selection
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Radio Button for Regular User
                Row(
                  children: [
                    Radio<String>(
                      value: 'user',
                      groupValue: userType,
                      onChanged: (value) {
                        setState(() {
                          userType = value;
                        });
                      },
                    ),
                    const Text('User'),
                  ],
                ),
                // Radio Button for Car Wash Owner
                Row(
                  children: [
                    Radio<String>(
                      value: 'owner',
                      groupValue: userType,
                      onChanged: (value) {
                        setState(() {
                          userType = value;
                        });
                      },
                    ),
                    const Text('Car Wash Owner'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Sign Up Button
            ElevatedButton(
              onPressed: signUp,
              child: const Text('Sign Up'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
