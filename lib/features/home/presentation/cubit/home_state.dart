import '../../../../core/network/api_result.dart';
import '../../domain/entities/home_dashboard.dart';

/// حالات شاشة الرئيسية.
sealed class HomeState {
  const HomeState();
}

final class HomeInitial extends HomeState {
  const HomeInitial();
}

final class HomeLoading extends HomeState {
  const HomeLoading();
}

final class HomeSuccess extends HomeState {
  const HomeSuccess(this.dashboard);

  final HomeDashboard dashboard;
}

final class HomeFailure extends HomeState {
  const HomeFailure(this.failure);

  final ApiFailure failure;
}
