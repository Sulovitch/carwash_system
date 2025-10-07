import 'package:app/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'owner/owner_services_tab.dart';
import 'owner/owner_receptionists_tab.dart';
import 'owner/owner_profile_tab.dart';
import 'owner/owner_dashboard_tab.dart';
import 'owner/owner_analytics_tab.dart';
import '../config/app_constants.dart';

class OwnerScreen extends StatefulWidget {
  static const String routeName = 'ownerScreen';
  final Map<String, dynamic> carWashInfo;

  const OwnerScreen({
    Key? key,
    required this.carWashInfo,
  }) : super(key: key);

  @override
  State<OwnerScreen> createState() => _OwnerScreenState();
}

class _OwnerScreenState extends State<OwnerScreen> {
  int _selectedIndex = 0;
  late Map<String, dynamic> _carWashInfo;

  @override
  void initState() {
    super.initState();
    _initializeCarWashInfo();
  }

  void _initializeCarWashInfo() {
    _carWashInfo = {
      'ownerId': widget.carWashInfo['ownerId']?.toString() ?? '',
      'carWashId': widget.carWashInfo['carWashId']?.toString() ?? '',
      'name': widget.carWashInfo['name'] ?? 'مغسلة',
      'location': widget.carWashInfo['location'] ?? '',
      'phone': widget.carWashInfo['phone'] ?? '',
      'email': widget.carWashInfo['email'] ?? '',
      'profileImage': widget.carWashInfo['profileImage'] ?? '',
      'images': widget.carWashInfo['images'] ?? [],
      'open_time': widget.carWashInfo['open_time'] ?? '',
      'close_time': widget.carWashInfo['close_time'] ?? '',
      'duration': widget.carWashInfo['duration']?.toString() ?? '',
      'capacity': widget.carWashInfo['capacity']?.toString() ?? '',
      'ownerProfile': widget.carWashInfo['ownerProfile'] ?? {},
    };
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _updateCarWashInfo(Map<String, dynamic> updatedInfo) {
    setState(() {
      _carWashInfo = {
        ..._carWashInfo,
        ...updatedInfo,
      };
    });
  }

  void _updateOwnerInfo(Map<String, dynamic> updatedOwner) {
    setState(() {
      _carWashInfo = {
        ..._carWashInfo,
        'ownerProfile': {
          ...(_carWashInfo['ownerProfile'] as Map<String, dynamic>? ?? {}),
          ...updatedOwner,
        },
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final carWashId = _carWashInfo['carWashId']?.toString() ?? '';

    if (carWashId.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: AppColors.error),
              const SizedBox(height: AppSpacing.medium),
              const Text('خطأ: معرف المغسلة مفقود'),
              const SizedBox(height: AppSpacing.medium),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('العودة'),
              ),
            ],
          ),
        ),
      );
    }

    final tabs = [
      OwnerDashboardTab(
        carWashInfo: _carWashInfo,
        onRefresh: () => setState(() {}),
        onNavigateToTab: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      OwnerAnalyticsTab(carWashId: carWashId),
      OwnerServicesTab(carWashId: carWashId),
      OwnerReceptionistsTab(
        carWashId: carWashId,
        carWashInfo: _carWashInfo,
      ),
      OwnerProfileTab(
        carWashInfo: _carWashInfo,
        onCarWashUpdated: _updateCarWashInfo,
        onOwnerUpdated: _updateOwnerInfo,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          // إشعارات
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  // TODO: فتح شاشة الإشعارات
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: const Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          // تسجيل الخروج
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: tabs,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          backgroundColor: Colors.white,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'لوحة التحكم',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics),
              label: 'التحليلات',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.build_outlined),
              activeIcon: Icon(Icons.build),
              label: 'الخدمات',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'الموظفين',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'الإعدادات',
            ),
          ],
        ),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'لوحة التحكم';
      case 1:
        return 'التحليلات والتقارير';
      case 2:
        return 'إدارة الخدمات';
      case 3:
        return 'إدارة الموظفين';
      case 4:
        return 'الإعدادات والملف الشخصي';
      default:
        return _carWashInfo['name'] ?? 'مغسلة';
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: const [
            Icon(Icons.logout, color: AppColors.error),
            SizedBox(width: 12),
            Text('تسجيل الخروج'),
          ],
        ),
        content: const Text('هل أنت متأكد من تسجيل الخروج من حسابك؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context,
                WelcomeScreen.routeName,
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }
}
