import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_result.dart';
import '../../domain/entities/home_dashboard.dart';
import '../../domain/repositories/ads_repository.dart';
import 'all_ads_state.dart';

class AllAdsCubit extends Cubit<AllAdsState> {
  AllAdsCubit(this._repository) : super(const AllAdsInitial());

  final AdsRepository _repository;

  Future<void> fetchAds() async {
    emit(const AllAdsLoading());

    final result = await _repository.fetchAllActiveAds();

    switch (result) {
      case ApiSuccess<List<Announcement>>(:final data):
        emit(AllAdsSuccess(data));
      case ApiFailureResult<List<Announcement>>(:final failure):
        emit(AllAdsFailure(failure));
    }
  }

  void toggleSortOrder() {
    final current = state;
    if (current is AllAdsSuccess) {
      emit(AllAdsSuccess(current.ads, newestFirst: !current.newestFirst));
    }
  }
}
