import '../../../housing_request/data/datasources/housing_request_remote_data_source.dart';
import '../../../housing_request/domain/entities/housing_request.dart';
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
    // بانتظار ربط `/api/allocations/mine` (رقم الغرفة/المبنى الفعليَّين
    // بعد التخصيص) — حالياً نعرض حالة القرار بلا تفاصيل الغرفة الوهمية
    // القديمة.
    final Map<String, dynamic> housingStatus;
    if (myRequest == null) {
      housingStatus = {'status': 'none'};
    } else {
      housingStatus = switch (myRequest.decision?.status) {
        null => {'status': 'pending'},
        AdmissionDecisionStatus.accepted => {'status': 'accepted'},
        AdmissionDecisionStatus.rejected => {'status': 'rejected'},
        AdmissionDecisionStatus.pending ||
        AdmissionDecisionStatus.waitingList => {'status': 'pending'},
      };
    }

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
