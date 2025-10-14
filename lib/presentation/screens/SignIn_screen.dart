import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/error_handler.dart';
import '../config/app_constants.dart';
import 'Owner_screen.dart';
import 'User_screen.dart';
import 'Receptionist_screen.dart';
import 'CarWash_screen.dart';

class SigninScreen extends StatefulWidget {
  static const String routeName = 'signinScreen';
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  String _userType = 'user';
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await _authService.signIn(
        login: _loginController.text.trim(),
        password: _passwordController.text,
        userType: _userType,
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        _navigateBasedOnUserType(response.data!);
      } else {
        ErrorHandler.showErrorSnackBar(
          context,
          response.message ?? 'فشل تسجيل الدخول',
        );
      }
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateBasedOnUserType(Map<String, dynamic> userData) {
    final userId = userData['id']?.toString();
    if (userId == null || userId.isEmpty) {
      ErrorHandler.showErrorSnackBar(context, 'خطأ: معرف المستخدم مفقود');
      return;
    }

    final userProfile = {
      'userId': userId,
      'name': userData['name'] ?? 'Unknown Name',
      'email': userData['email'] ?? 'Unknown Email',
      'phone': userData['phone'] ?? 'Unknown Phone',
    };

    final carWashData = userData['car_wash'];
    final carWashInfo = {
      'ownerId': userId,
      'carWashId': carWashData?['car_wash_id']?.toString() ?? '',
      'name': carWashData?['name'] ?? '',
      'location': carWashData?['location'] ?? '',
      'phone': carWashData?['phone'] ?? '',
      'email': userData['email'] ?? '',
      'images': carWashData?['images'] ?? [],
      'profileImage': carWashData?['profile_image'] ?? '',
      'open_time': carWashData?['open_time'] ?? '',
      'close_time': carWashData?['close_time'] ?? '',
      'duration': carWashData?['duration'] ?? '',
      'capacity': carWashData?['capacity'] ?? '',
      'ownerProfile': {
        'name': userData['name'] ?? 'Unknown Owner',
        'email': userData['email'] ?? 'owner@example.com',
        'phone': userData['phone'] ?? '123-456-7890',
      },
    };

    Widget destination;

    switch (_userType) {
      case 'owner':
        if (carWashData == null || carWashInfo['carWashId'] == '') {
          destination = CarWashScreen(
            ownerId: userId,
            initialCarWashInfo: {
              'name': '',
              'location': '',
              'phone': '',
              'email': '',
              'profileImage': '',
            },
            initialImages: [],
          );
        } else {
          destination = OwnerScreen(carWashInfo: carWashInfo);
        }
        break;

      case 'receptionist':
        final receptionist = {
          'id': userId,
          'name': userData['name'] ?? 'Unknown',
          'email': userData['email'] ?? 'Unknown',
          'phone': userData['phone'] ?? 'Unknown',
        };
        destination = ReceptionistScreen(
          receptionist: receptionist,
          carWashInfo: {
            'carWashId': carWashData?['car_wash_id']?.toString() ?? '',
            'name': carWashData?['name'] ?? 'Unknown Car Wash',
            'location': carWashData?['location'] ?? 'Unknown Location',
            'phone': carWashData?['phone'] ?? 'No Phone',
          },
        );
        break;

      default:
        destination = UserScreen(
          carDetails: null,
          userDetails: userProfile,
        );
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('تسجيل الدخول'),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Icon(
                    Icons.local_car_wash,
                    size: 80,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: AppSpacing.xlarge),

                  // Login Field
                  TextFormField(
                    controller: _loginController,
                    decoration: InputDecoration(
                      labelText: 'البريد الإلكتروني أو رقم الجوال',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.borderRadius),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppStrings.requiredField;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.medium),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.borderRadius),
                      ),
                    ),
                    validator: AppValidators.required,
                  ),
                  const SizedBox(height: AppSpacing.large),

                  // User Type Selection
                  Text(
                    'نوع المستخدم',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.small),
                  _buildUserTypeRadio('user', 'مستخدم'),
                  _buildUserTypeRadio('owner', 'صاحب مغسلة'),
                  _buildUserTypeRadio('receptionist', 'موظف استقبال'),
                  const SizedBox(height: AppSpacing.xlarge),

                  // Sign In Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.secondary,
                      minimumSize: Size(double.infinity, AppSizes.buttonHeight),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.borderRadius),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'تسجيل الدخول',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeRadio(String value, String label) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: _userType,
      onChanged: (val) {
        if (val != null) {
          setState(() => _userType = val);
        }
      },
      activeColor: AppColors.primary,
    );
  }
}
