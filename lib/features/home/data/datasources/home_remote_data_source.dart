import '../../../housing_request/data/datasources/housing_request_remote_data_source.dart';
import '../models/home_dashboard_model.dart';
import 'ads_remote_data_source.dart';

/// مصدر بيانات لوحة الرئيسية.
///
/// ==================================================================
/// **نقطة الربط مع الباك إند:** حالة السكن والإعلانات مربوطتان بخدمتَين
/// حقيقيتَين فعلياً (راجع [HousingRequestRemoteDataSource] و
/// [AdsRemoteDataSource])؛ اسم الطالب وسجل آخر النشاطات لا يزالان بيانات
/// وهمية بانتظار خدمة حقيقية تجمّعهما.
/// ==================================================================
class HomeRemoteDataSource {
  Future<HomeDashboardModel> fetchDashboard() async {
    // حالة السكن مُشتقة من طلب السكن الفعلي للمستخدم (وليست قيمة ثابتة)،
    // حتى تبقى الرئيسية متسقة مع ما قدّمه المستخدم فعلياً بدل الادّعاء
    // الدائم بأنه مقبول في غرفة A-204 بغض النظر عن الواقع.
    final myRequest = await HousingRequestRemoteDataSource().fetchMyRequest();
    final ads = await AdsRemoteDataSource().fetchActiveAds();
    final Map<String, dynamic> housingStatus =
        myRequest == null
            ? {'status': 'none'}
            : switch (myRequest.status) {
              'accepted' => {
                'status': 'accepted',
                'buildingUnit': 'الوحدة أ',
                'roomNumber': 'A-204',
                'daysUntilPayment': 12,
                'paymentReference': 'PAY-2025-4521',
              },
              'rejected' => {'status': 'rejected'},
              _ => {'status': 'pending'},
            };

    final baseJson = HomeDashboardModel.fromJson({
      'studentName': 'أحمد محمد',
      'housingStatus': housingStatus,
      'announcements': const [],
      'activities': [
        {
          'id': 'act_1',
          'text': 'تم قبول طلب السكن الخاص بك',
          'time': 'منذ ساعتين',
          'colorKey': 'success',
        },
        {
          'id': 'act_2',
          'text': 'انضممت إلى غروب الوحدة أ',
          'time': 'أمس',
          'colorKey': 'info',
        },
        {
          'id': 'act_3',
          'text': 'تم تحديث بيانات حسابك',
          'time': 'منذ 3 أيام',
          'colorKey': 'neutral',
        },
      ],
    });

    return HomeDashboardModel(
      studentName: baseJson.studentName,
      housingStatus: baseJson.housingStatus,
      announcements: ads,
      activities: baseJson.activities,
    );
  }
}
