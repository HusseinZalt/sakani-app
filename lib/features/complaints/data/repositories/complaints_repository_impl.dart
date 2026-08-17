import 'dart:typed_data';

import '../../../../core/network/api_result.dart';
import '../../domain/entities/complaint.dart';
import '../../domain/repositories/complaints_repository.dart';
import '../datasources/complaints_remote_data_source.dart';

class ComplaintsRepositoryImpl implements ComplaintsRepository {
  ComplaintsRepositoryImpl({ComplaintsRemoteDataSource? remoteDataSource})
    : _remoteDataSource = remoteDataSource ?? ComplaintsRemoteDataSource();

  final ComplaintsRemoteDataSource _remoteDataSource;

  @override
  Future<ApiResult<List<Complaint>>> fetchComplaints() async {
    try {
      final complaints = await _remoteDataSource.fetchComplaints();
      return ApiResult.success(complaints);
    } on ComplaintsException catch (e) {
      return ApiResult.failure(ApiFailure(message: e.message, type: e.type));
    } catch (_) {
      return ApiResult.failure(ApiFailure.unknown());
    }
  }

  @override
  Future<ApiResult<Complaint>> fetchComplaintById(String id) async {
    try {
      final complaint = await _remoteDataSource.fetchComplaintById(id);
      return ApiResult.success(complaint);
    } on ComplaintsException catch (e) {
      return ApiResult.failure(ApiFailure(message: e.message, type: e.type));
    } catch (_) {
      return ApiResult.failure(ApiFailure.unknown());
    }
  }

  @override
  Future<ApiResult<Complaint>> submitComplaint({
    required String type,
    required String title,
    required String description,
    bool isAnonymous = false,
    List<Uint8List> images = const [],
  }) async {
    try {
      final complaint = await _remoteDataSource.submitComplaint(
        type: type,
        title: title,
        description: description,
        isAnonymous: isAnonymous,
        images: images,
      );
      return ApiResult.success(complaint);
    } on ComplaintsException catch (e) {
      return ApiResult.failure(ApiFailure(message: e.message, type: e.type));
    } catch (_) {
      return ApiResult.failure(ApiFailure.unknown());
    }
  }
}
