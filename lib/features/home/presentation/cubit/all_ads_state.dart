import '../../../../core/network/api_result.dart';
import '../../domain/entities/home_dashboard.dart';

sealed class AllAdsState {
  const AllAdsState();
}

final class AllAdsInitial extends AllAdsState {
  const AllAdsInitial();
}

final class AllAdsLoading extends AllAdsState {
  const AllAdsLoading();
}

final class AllAdsSuccess extends AllAdsState {
  const AllAdsSuccess(this.ads, {this.newestFirst = true});

  /// دائماً بترتيب الأحدث أولاً كما وصلت من [AllAdsCubit.fetchAds]؛
  /// [newestFirst] فقط يحدد اتجاه العرض دون الحاجة لإعادة الجلب.
  final List<Announcement> ads;
  final bool newestFirst;

  List<Announcement> get sorted => newestFirst ? ads : ads.reversed.toList();
}

final class AllAdsFailure extends AllAdsState {
  const AllAdsFailure(this.failure);

  final ApiFailure failure;
}
