import '../../../../core/network/api_result.dart';
import '../entities/home_dashboard.dart';

/// عقد (Interface) طبقة الرئيسية، تعتمد عليه طبقة الـ Presentation دون
/// معرفة تفاصيل التنفيذ الفعلية (وهمية حالياً أو عبر API حقيقي مستقبلاً).
abstract class HomeRepository {
  /// جلب بيانات لوحة الرئيسية بالكامل (حالة السكن، الإعلانات، آخر النشاطات).
  Future<ApiResult<HomeDashboard>> fetchDashboard();
}
