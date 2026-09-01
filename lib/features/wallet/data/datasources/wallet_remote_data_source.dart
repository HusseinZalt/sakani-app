import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/server_message_ar.dart';
import '../../domain/entities/wallet_transactions_page.dart';
import '../models/wallet_transaction_model.dart';

/// استثناء مخصص لطبقة الـ Data يحمل رسالة عربية واضحة ونوع الخطأ المناسب،
/// ليتم تحويله لاحقاً إلى [ApiFailure] داخل الـ Repository.
class WalletException implements Exception {
  const WalletException(this.message, {this.type = ApiErrorType.badRequest});

  final String message;
  final ApiErrorType type;
}

/// مصدر بيانات المحفظة — يستدعي نقاط `/api/wallet/...` من خدمة المصادقة
/// نفسها (راجع `flutter-wallet-integration.md`)، لكن خلافاً لبقية نقاط
/// `/api/auth/...` فهي **لسا مش خلف البوابة الموحّدة** (مؤكَّد من الباك
/// إند 2026-09-01 — راجع توثيق [ApiClient.walletBaseUrl])، لذلك تمر عبر
/// [ApiClient.wallet] المخصَّص لا [ApiClient.auth].
class WalletRemoteDataSource {
  WalletRemoteDataSource({Dio? dio}) : _dio = dio ?? ApiClient.wallet.dio;

  final Dio _dio;

  /// شحن الرصيد عبر كود مُستخرج من ملصق QR. يُرجع (قيمة الشحنة، الرصيد
  /// الجديد) كزوج خام — يبنيها الـ Repository إلى [WalletRedeemResult].
  Future<({double amount, double balance})> redeem(String code) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/wallet/redeem',
        data: {'code': code},
      );
      final data = _asJsonMap(response.data)['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw const WalletException(
          'تعذّر قراءة استجابة الخادم، يرجى المحاولة مرة أخرى.',
          type: ApiErrorType.parsing,
        );
      }
      return (
        amount: (data['amount'] as num?)?.toDouble() ?? 0,
        balance: (data['balance'] as num?)?.toDouble() ?? 0,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<WalletTransactionsPage> fetchTransactions({
    required int page,
    required int limit,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/wallet/transactions',
        queryParameters: {'page': page, 'limit': limit},
      );
      final body = _asJsonMap(response.data);
      final items = (body['data'] as List?) ?? const [];
      final transactions = <WalletTransactionModel>[];
      for (final item in items.whereType<Map<String, dynamic>>()) {
        try {
          transactions.add(WalletTransactionModel.fromJson(item));
        } catch (_) {
          // حركة واحدة بحقل غير متوقع لا يجوز أن تُسقط السجل بالكامل —
          // نتجاهلها ونكمل بالباقي (نفس منطق خدمة الإشعارات).
        }
      }

      final pagination = body['pagination'] as Map<String, dynamic>?;
      return WalletTransactionsPage(
        items: transactions,
        total: (pagination?['total'] as num?)?.toInt() ?? transactions.length,
        page: (pagination?['page'] as num?)?.toInt() ?? page,
        limit: (pagination?['limit'] as num?)?.toInt() ?? limit,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// يطبّع جسم الاستجابة إلى `Map<String, dynamic>` بغض النظر عن نوع
  /// المحتوى الفعلي الذي أرجعه الخادم (راجع نفس المنطق بخدمة الإشعارات).
  Map<String, dynamic> _asJsonMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is String && data.isNotEmpty) {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) return decoded;
    }
    throw const WalletException(
      'تعذّر قراءة استجابة الخادم، يرجى المحاولة مرة أخرى.',
      type: ApiErrorType.parsing,
    );
  }

  WalletException _mapDioException(DioException e) {
    final statusCode = e.response?.statusCode;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const WalletException(
          'استغرق الاتصال بالخادم وقتاً أطول من المتوقع، حاول مرة أخرى.',
          type: ApiErrorType.timeout,
        );
      case DioExceptionType.connectionError:
        return const WalletException(
          'تعذر الاتصال بالخادم، يرجى التحقق من اتصالك بالإنترنت.',
          type: ApiErrorType.network,
        );
      default:
        break;
    }

    switch (statusCode) {
      case 400:
        final body = e.response?.data;
        final map = body is Map ? body : null;
        final serverText =
            (map?['message'] ?? map?['detail'] ?? map?['error']) as String? ??
            (body is String ? body : null);
        return WalletException(
          translateServerMessageAr(
            serverText,
            fallback: 'تعذّر تنفيذ عملية الشحن، تحقق من الكود وحاول مجدداً.',
          ),
        );
      case 401:
        return const WalletException(
          'تعذّر التحقق من صلاحية الدخول، يرجى تسجيل الدخول مرة أخرى.',
          type: ApiErrorType.unauthorized,
        );
      case 404:
        return const WalletException(
          'كود الشحن غير صحيح.',
          type: ApiErrorType.notFound,
        );
      case 409:
        return const WalletException('هذا الكود مستخدم بالفعل.');
      default:
        if (statusCode != null && statusCode >= 500) {
          return const WalletException(
            'حدث خطأ في الخادم، يرجى المحاولة لاحقاً.',
            type: ApiErrorType.server,
          );
        }
        return const WalletException('حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى.');
    }
  }
}
