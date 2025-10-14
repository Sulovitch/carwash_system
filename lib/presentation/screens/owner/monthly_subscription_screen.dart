import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/error_handler.dart';

class SubscriptionPlan {
  final String name;
  final String priceLabel;
  final List<String> features;
  final bool isRecommended;

  const SubscriptionPlan({
    required this.name,
    required this.priceLabel,
    required this.features,
    this.isRecommended = false,
  });
}

class OwnerSubscriptionScreen extends StatelessWidget {
  static const String routeName = 'owner_subscription_screen';

  const OwnerSubscriptionScreen({Key? key}) : super(key: key);

  void _subscribe(BuildContext context, SubscriptionPlan plan) async {
    final confirmed = await ErrorHandler.showConfirmDialog(
      context,
      title: 'تأكيد الاشتراك',
      content: 'هل ترغب في الاشتراك في خطة "${plan.name}"؟',
      confirmText: 'تأكيد',
      cancelText: 'إلغاء',
    );

    if (!confirmed) return;

    if (context.mounted) {
      ErrorHandler.showSuccessSnackBar(
        context,
        'تم إرسال طلب الاشتراك في خطة "${plan.name}" بنجاح',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final plans = <SubscriptionPlan>[
      const SubscriptionPlan(
        name: 'الباقة الأساسية',
        priceLabel: '49 ر.س / شهر',
        features: [
          'إدارة الخدمات والموظفين',
          'تنبيهات عبر البريد الإلكتروني',
          'دعم عبر البريد خلال 48 ساعة',
        ],
      ),
      const SubscriptionPlan(
        name: 'الباقة الاحترافية',
        priceLabel: '99 ر.س / شهر',
        features: [
          'كل مزايا الباقة الأساسية',
          'تقارير أداء شهرية متقدمة',
          'تنبيهات فورية عبر التطبيق',
          'دعم فني على مدار الساعة',
        ],
        isRecommended: true,
      ),
      const SubscriptionPlan(
        name: 'الباقة المميزة',
        priceLabel: '149 ر.س / شهر',
        features: [
          'كل مزايا الباقة الاحترافية',
          'مدير حساب مخصص',
          'تخصيص كامل للتقارير والتحليلات',
          'تدريب شهري للفريق',
        ],
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('خطط الاشتراك'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.large),
        itemCount: plans.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.medium),
        itemBuilder: (context, index) {
          final plan = plans[index];
          return _SubscriptionCard(
            plan: plan,
            onSubscribe: () => _subscribe(context, plan),
          );
        },
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final VoidCallback onSubscribe;

  const _SubscriptionCard({
    required this.plan,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
        plan.isRecommended ? AppColors.primary : Colors.grey.shade300;
    final titleStyle = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: plan.isRecommended ? AppColors.primary : AppColors.textPrimary,
    );

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
        side: BorderSide(color: borderColor, width: plan.isRecommended ? 2 : 1),
      ),
      elevation: plan.isRecommended
          ? AppSizes.cardElevation + 2
          : AppSizes.cardElevation,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plan.name, style: titleStyle),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        plan.priceLabel,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (plan.isRecommended)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.small,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius:
                          BorderRadius.circular(AppSizes.borderRadius),
                    ),
                    child: const Text(
                      'الأكثر طلبًا',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
            ...plan.features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.small),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.small),
                    Expanded(
                      child: Text(
                        feature,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.large),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSubscribe,
                child: const Text('اشترك الآن'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
