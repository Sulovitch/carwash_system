import 'package:app/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'user/user_home_tab.dart';
import 'user/user_profile_tab.dart';
import 'user/user_reservations_tab.dart';
import 'user/user_cars_tab.dart';
import '../config/app_constants.dart';

class UserScreen extends StatefulWidget {
  static const String routeName = 'userScreen';

  final dynamic carDetails;
  final Map<String, dynamic> userDetails;

  const UserScreen({
    Key? key,
    this.carDetails,
    required this.userDetails,
  }) : super(key: key);

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  int _selectedIndex = 0;
  late Map<String, String> _userProfile;

  @override
  void initState() {
    super.initState();
    _initializeUserProfile();
  }

  void _initializeUserProfile() {
    _userProfile = {
      'userId': widget.userDetails['userId']?.toString() ?? '',
      'name': widget.userDetails['name']?.toString() ?? 'مستخدم',
      'email': widget.userDetails['email']?.toString() ?? '',
      'phone': widget.userDetails['phone']?.toString() ?? '',
    };
  }

  void _onProfileUpdated(Map<String, String> updatedProfile) {
    setState(() {
      _userProfile = updatedProfile;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = _userProfile['userId'] ?? '';

    if (userId.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: AppColors.error),
              const SizedBox(height: AppSpacing.medium),
              const Text('خطأ: معرف المستخدم مفقود'),
              const SizedBox(height: AppSpacing.medium),
              Flexible(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('العودة'),
                ),
              )
            ],
          ),
        ),
      );
    }

    final tabs = [
      UserHomeTab(
        userId: userId,
        userProfile: _userProfile,
      ),
      UserReservationsTab(userId: userId),
      UserCarsTab(userId: userId),
      UserProfileTab(
        userProfile: _userProfile,
        onProfileUpdated: _onProfileUpdated,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        backgroundColor: AppColors.background,
        elevation: 1,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('تسجيل الخروج'),
                  content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إلغاء'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // إغلاق الـ dialog
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          WelcomeScreen.routeName,
                          (route) => false,
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                      child: const Text('تسجيل الخروج'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.local_car_wash),
            label: 'المغاسل',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'حجوزاتي',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'سياراتي',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'الملف الشخصي',
          ),
        ],
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'المغاسل المتاحة';
      case 1:
        return 'حجوزاتي';
      case 2:
        return 'سياراتي';
      case 3:
        return 'الملف الشخصي';
      default:
        return 'التطبيق';
    }
  }
}
