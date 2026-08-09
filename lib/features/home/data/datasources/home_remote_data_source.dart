import '../../../housing_request/data/datasources/housing_request_remote_data_source.dart';
import '../models/home_dashboard_model.dart';

/// مصدر بيانات لوحة الرئيسية.
///
/// ==================================================================
/// **نقطة الربط مع الباك إند:** هذا التنفيذ وهمي بالكامل حالياً (بيانات
/// ثابتة + محاكاة زمن استجابة الشبكة) نظراً لعدم جاهزية الباك إند بعد.
/// عند الربط الحقيقي، يكفي استبدال محتوى هذا الملف باستدعاء نقطة نهاية
/// مجمّعة واحدة (مثال: `GET /api/dashboard`) تُرجع نفس بنية JSON، دون أي
/// تعديل على الـ Repository أو الـ Cubit أو الشاشة.
/// ==================================================================
class HomeRemoteDataSource {
  static const _networkDelay = Duration(milliseconds: 700);

  Future<HomeDashboardModel> fetchDashboard() async {
    await Future.delayed(_networkDelay);

    // حالة السكن مُشتقة من طلب السكن الفعلي للمستخدم (وليست قيمة ثابتة)،
    // حتى تبقى الرئيسية متسقة مع ما قدّمه المستخدم فعلياً بدل الادّعاء
    // الدائم بأنه مقبول في غرفة A-204 بغض النظر عن الواقع.
    final myRequest = await HousingRequestRemoteDataSource().fetchMyRequest();
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

    return HomeDashboardModel.fromJson({
      'studentName': 'أحمد محمد',
      'housingStatus': housingStatus,
      'announcements': [
        {
          'id': 'ann_1',
          'title': 'فعالية الترحيب بالطلاب الجدد 🎉',
          'subtitle': 'الأحد القادم — الساحة الرئيسية',
          'colorVariant': 'primary',
        },
        {
          'id': 'ann_2',
          'title': 'تمديد فترة سداد الرسوم',
          'subtitle': 'حتى نهاية الشهر الحالي',
          'colorVariant': 'warning',
        },
        {
          'id': 'ann_3',
          'title': 'صيانة دورية لشبكة الإنترنت',
          'subtitle': 'الخميس، من 2-4 عصراً',
          'colorVariant': 'primary',
        },
      ],
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
  }
}
