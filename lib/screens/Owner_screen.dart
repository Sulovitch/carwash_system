import 'package:flutter/material.dart';
import 'owner/owner_services_tab.dart';
import 'owner/owner_receptionists_tab.dart';
import '../config/app_constants.dart';
import 'Transaction_screen.dart';

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
      OwnerServicesTab(carWashId: carWashId),
      OwnerReceptionistsTab(
        carWashId: carWashId,
        carWashInfo: _carWashInfo,
      ),
      TransactionScreen(carWashId: carWashId),
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
                        Navigator.pop(context);
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          'welcome_screen',
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
            icon: Icon(Icons.build),
            label: 'الخدمات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'الموظفين',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: 'المعاملات',
          ),
        ],
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'إدارة الخدمات';
      case 1:
        return 'إدارة الموظفين';
      case 2:
        return 'المعاملات والإحصائيات';
      default:
        return _carWashInfo['name'] ?? 'مغسلة';
    }
  }
}
