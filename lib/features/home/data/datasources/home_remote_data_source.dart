import '../../../housing_request/data/datasources/housing_request_remote_data_source.dart';
import '../../../housing_request/domain/entities/housing_request.dart';
import '../../../notifications/data/datasources/notifications_remote_data_source.dart';
import '../models/home_dashboard_model.dart';
import 'ads_remote_data_source.dart';

/// مصدر بيانات لوحة الرئيسية.
///
/// ==================================================================
/// **نقطة الربط مع الباك إند:** حالة السكن والإعلانات مربوطتان بخدمتَين
/// حقيقيتَين فعلياً (راجع [HousingRequestRemoteDataSource] و
/// [AdsRemoteDataSource]). "آخر النشاطات" لا توجد لها خدمة تجميع مستقلة
/// أصلاً بالباك إند — لا حاجة لها فعلياً، فصندوق الإشعارات الحقيقي
/// (`NotificationsRemoteDataSource`) يغطي بالضبط نفس الأحداث (قرار
/// سكن، رد شكوى، إعلان...)، فنعيد استخدام أحدث إشعاراته هنا مباشرة بدل
/// اختلاق تجميعة موازية وهمية. اسم الطالب يبقى غير مستخدَم فعلياً (رأس
/// الرئيسية يقرأ الاسم مباشرة من [UserSessionCubit] وليس من هنا).
/// ==================================================================
class HomeRemoteDataSource {
  static const _activitiesLimit = 5;

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
      'activities': const [],
    });

    return HomeDashboardModel(
      studentName: baseJson.studentName,
      housingStatus: baseJson.housingStatus,
      announcements: ads,
      activities: await _fetchRecentActivities(),
    );
  }

  Future<List<ActivityLogItemModel>> _fetchRecentActivities() async {
    try {
      final notifications =
          await NotificationsRemoteDataSource().fetchNotifications()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifications
          .take(_activitiesLimit)
          .map(
            (n) => ActivityLogItemModel(
              id: n.id,
              text: n.title,
              time: n.timeLabel,
              colorKey: n.colorKey,
            ),
          )
          .toList();
    } catch (_) {
      // فشل جلب الإشعارات لا يجب أن يمنع عرض باقي الرئيسية — يكفي إخفاء
      // قسم "آخر النشاطات" (الشاشة أصلاً بتعرض رسالة "لا توجد نشاطات
      // حديثة" لو القائمة فاضية).
      return const [];
    }
  }
}
